data "aws_region" "current_region" {}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "fargate_vpc" {
  enable_dns_support   = true
  enable_dns_hostnames = true

  cidr_block = local.mappings["SubnetConfig"]["VPC"]["CIDR"]

  tags = merge(
    { Name = local.vpc_full_name },
    { environment = var.environment },
    { app_name = var.app_name },
    var.default_tags
  )
}

resource "aws_subnet" "public_subnet_one" {
  availability_zone       = data.aws_availability_zones.available.names[0]
  vpc_id                  = aws_vpc.fargate_vpc.id
  cidr_block              = local.mappings["SubnetConfig"]["PublicOne"]["CIDR"]
  map_public_ip_on_launch = true

  tags = merge(
    { Name = local.subnet_one_full_name },
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_subnet" "public_subnet_two" {
  availability_zone       = data.aws_availability_zones.available.names[1]
  vpc_id                  = aws_vpc.fargate_vpc.id
  cidr_block              = local.mappings["SubnetConfig"]["PublicTwo"]["CIDR"]
  map_public_ip_on_launch = true

  tags = merge(
    { Name = local.subnet_two_full_name },
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_internet_gateway" "internet_gateway" {
  tags = merge(
    { Name = local.internet_gw_full_name },
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_internet_gateway_attachment" "gateway_attachment" {
  internet_gateway_id = aws_internet_gateway.internet_gateway.id
  vpc_id              = aws_vpc.fargate_vpc.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.fargate_vpc.id

  tags = merge(
    { Name = local.public_route_table_full_name },
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
  depends_on             = [aws_route_table.public_route_table]
}

resource "aws_route_table_association" "public_subnet_one_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_one.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_two_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_two.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = local.ecs_cluster_full_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ECSTaskRoleS3ReadOnly"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = ["ecs-tasks.amazonaws.com"]
        }
      }
    ]
  })

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "${var.app_name}S3ReadAccess"
  description = "Policy for S3 access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:Describe*"
        ],
        Effect   = "Allow",
        Resource = "*",
      },
    ],
  })

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}

resource "aws_iam_role_policy_attachment" "s3_access_policy_to_task_role_attachment" {
  role       = aws_iam_role.ecs_task_role.id
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = local.ecs_task_execution_role_full_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
          Service = ["ecs-tasks.amazonaws.com"]
        }
      },
    ]
  })

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

variable "task_execution_role_policies" {
  description = "Policies"
  type        = set(string)
  default = [
    "AmazonECSTaskExecutionRolePolicy",
    "AWSAppMeshEnvoyAccess",
    "AWSXRayDaemonWriteAccess",
    "CloudWatchLogsFullAccess"
  ]
}

data "aws_iam_policy" "task_execution_role_policies" {
  for_each = var.task_execution_role_policies
  name     = each.value
}

resource "aws_iam_role_policy_attachment" "policies_to_task_execution_role_attach" {
  depends_on = [data.aws_iam_policy.task_execution_role_policies]

  for_each   = var.task_execution_role_policies
  role       = aws_iam_role.ecs_task_execution_role.id
  policy_arn = data.aws_iam_policy.task_execution_role_policies[each.key].arn
}

resource "aws_security_group" "load_balancer_security_group" {
  name = local.sg_lb_full_name

  vpc_id = aws_vpc.fargate_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    { Description = "Allow traffic from load balancer to fargate containers" },
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_security_group" "fargate_instances_security_group" {
  name   = local.sg_fargate_instances_full_name
  vpc_id = aws_vpc.fargate_vpc.id

  tags = merge(
    { Description = "Allow traffic from fargate containers to fargate containers" },
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_from_lb_sg_ingress_rule" {

  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
  security_group_id            = aws_security_group.fargate_instances_security_group.id


  from_port   = -1
  to_port     = -1
  ip_protocol = "-1"

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_from_self_sg_ingress_rule" {

  referenced_security_group_id = aws_security_group.fargate_instances_security_group.id
  security_group_id            = aws_security_group.fargate_instances_security_group.id

  from_port   = -1
  to_port     = -1
  ip_protocol = "-1"

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_for_admin_ingress_rule" {
  security_group_id = aws_security_group.fargate_instances_security_group.id

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}


resource "aws_vpc_security_group_egress_rule" "public_traffic_egress_rule" {
  security_group_id = aws_security_group.fargate_instances_security_group.id

  from_port   = -1
  to_port     = -1
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

}

resource "aws_lb" "public_load_balancer" {
  name               = lower(local.load_balancer_full_name)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_security_group.id]
  subnets            = [aws_subnet.public_subnet_one.id, aws_subnet.public_subnet_two.id]

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_lb_target_group" "default_target_group" {
  name     = local.default_target_group_full_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.fargate_vpc.id

  health_check {
    interval            = 6
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_lb_listener" "default_lb_listener" {

  depends_on = [aws_lb.public_load_balancer]

  load_balancer_arn = aws_lb.public_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default_target_group.arn
  }

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

data "aws_route53_zone" "hosted_zone" {
  name = var.hosted_zone
}

resource "aws_route53_record" "auth_server_record" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "${var.dns_name}.${data.aws_route53_zone.hosted_zone.name}"
  type    = "A"

  alias {
    name                   = aws_lb.public_load_balancer.dns_name
    zone_id                = aws_lb.public_load_balancer.zone_id
    evaluate_target_health = true
  }
}
