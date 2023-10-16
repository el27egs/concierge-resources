data "aws_region" "current_region" {}

data "aws_availability_zones" "availability_zones" {
  state = "available"
}

data "aws_acm_certificate" "domain_certificate" {
  domain      = var.certificate_domain_name
  statuses    = ["ISSUED"]
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

resource "aws_vpc" "vpc" {
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

resource "aws_subnet" "public_subnets" {
  count                   = local.number_az
  availability_zone       = data.aws_availability_zones.availability_zones.names[count.index]
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)
  map_public_ip_on_launch = true

  tags = merge(
    { Name = local.public_subnet_full_name },
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}

resource "aws_subnet" "private_subnets" {
  count                   = local.number_az
  availability_zone       = data.aws_availability_zones.availability_zones.names[count.index]
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, (1 * local.number_az) + count.index)
  map_public_ip_on_launch = false

  tags = merge(
    { Name = local.private_subnet_full_name },
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_subnet" "db_subnets" {
  count                   = local.number_az
  availability_zone       = data.aws_availability_zones.availability_zones.names[count.index]
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, (2 * local.number_az) + count.index)
  map_public_ip_on_launch = false

  tags = merge(
    { Name = local.db_subnet_full_name },
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
  vpc_id              = aws_vpc.vpc.id
}

resource "aws_eip" "private_eip" {
  tags = merge(
    { Name = local.private_eip_full_name },
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}

resource "aws_nat_gateway" "private_nat_gateway" {

  depends_on = [aws_internet_gateway.internet_gateway]

  allocation_id = aws_eip.private_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = merge(
    { Name = local.nat_gateway_full_name },
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    { Name = local.public_route_table_full_name },
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    { Name = local.private_route_table_full_name },
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_route_table" "db_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    { Name = local.db_route_table_full_name },
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.private_nat_gateway.id
}

resource "aws_route_table_association" "public_subnet_route_table_assoc" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_route_table_assoc" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "db_subnet_route_table_assoc" {
  count          = length(aws_subnet.db_subnets)
  subnet_id      = aws_subnet.db_subnets[count.index].id
  route_table_id = aws_route_table.db_route_table.id
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

resource "aws_iam_role" "task_role" {
  name = "${local.app_name_snake_case}DefaultTaskRole"

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
  name        = "${local.app_name_snake_case}S3ReadAccessPolicy"
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

resource "aws_iam_role_policy_attachment" "s3_policy_to_task_role_attach" {
  role       = aws_iam_role.task_role.id
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_role" "task_execution_role" {
  name = "${local.app_name_snake_case}DefaultTaskExecutionRole"

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

data "aws_iam_policy" "task_execution_role_policies" {
  for_each = var.task_execution_policy_set
  name     = each.value
}

resource "aws_iam_role_policy_attachment" "policies_for_task_execution_role_attach" {
  for_each   = var.task_execution_policy_set
  role       = aws_iam_role.task_execution_role.id
  policy_arn = data.aws_iam_policy.task_execution_role_policies[each.key].arn
}

resource "aws_security_group" "load_balancer_security_group" {
  name = local.sg_lb_full_name

  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
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

resource "aws_security_group" "containers_sg" {
  name   = local.sg_fargate_instances_full_name
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    { Description = "Allow traffic from container to container inside ecs cluster" },
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_vpc_security_group_ingress_rule" "traffic_from_lb_sg_ingress_rule" {

  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
  security_group_id            = aws_security_group.containers_sg.id


  from_port   = -1
  to_port     = -1
  ip_protocol = "-1"

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}

resource "aws_vpc_security_group_ingress_rule" "traffic_from_sg_self_ingress_rule" {

  referenced_security_group_id = aws_security_group.containers_sg.id
  security_group_id            = aws_security_group.containers_sg.id

  from_port   = -1
  to_port     = -1
  ip_protocol = "-1"

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_vpc_security_group_egress_rule" "public_traffic_egress_rule" {
  security_group_id = aws_security_group.containers_sg.id

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
  # Use private or public subnets according your needs
  subnets = [for subnet in aws_subnet.public_subnets : subnet.id]

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
  vpc_id   = aws_vpc.vpc.id

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

resource "aws_lb_listener" "http_80_listener" {

  load_balancer_arn = aws_lb.public_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_lb_listener" "https_443_listener" {

  load_balancer_arn = aws_lb.public_load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.domain_certificate.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
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

resource "aws_route53_record" "default_dsn_alias_record" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "${var.dns_name}.${data.aws_route53_zone.hosted_zone.name}"
  type    = "A"

  alias {
    name                   = aws_lb.public_load_balancer.dns_name
    zone_id                = aws_lb.public_load_balancer.zone_id
    evaluate_target_health = true
  }
}
