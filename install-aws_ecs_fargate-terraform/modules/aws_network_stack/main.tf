data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

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

#resource "aws_subnet" "public_subnet_one" {
#  availability_zone       = data.aws_availability_zones.available.names[0]
#  vpc_id                  = aws_vpc.fargate_vpc.id
#  cidr_block              = local.mappings["SubnetConfig"]["PublicOne"]["CIDR"]
#  map_public_ip_on_launch = true
#
#  tags = merge(
#    { Name = local.subnet_one_full_name },
#    { environment = var.environment },
#    { app_name = var.app_name },
#
#    var.default_tags
#  )
#}
#
#resource "aws_subnet" "public_subnet_two" {
#  availability_zone       = data.aws_availability_zones.available.names[1]
#  vpc_id                  = aws_vpc.fargate_vpc.id
#  cidr_block              = local.mappings["SubnetConfig"]["PublicTwo"]["CIDR"]
#  map_public_ip_on_launch = true
#
#  tags = merge(
#    { Name = local.subnet_two_full_name },
#    { environment = var.environment },
#    { app_name = var.app_name },
#
#    var.default_tags
#  )
#}
#
#resource "aws_internet_gateway" "internet_gateway" {
#  tags = merge(
#    { Name = local.internet_gw_full_name },
#    { environment = var.environment },
#    { app_name = var.app_name },
#
#    var.default_tags
#  )
#}
#
#resource "aws_internet_gateway_attachment" "gateway_attachment" {
#  internet_gateway_id = aws_internet_gateway.internet_gateway.id
#  vpc_id              = aws_vpc.fargate_vpc.id
#}
#
#resource "aws_route_table" "public_route_table" {
#  vpc_id = aws_vpc.fargate_vpc.id
#
#  tags = merge(
#    { Name = local.public_route_table_full_name },
#    { environment = var.environment },
#    { app_name = var.app_name },
#
#    var.default_tags
#  )
#}
#
#resource "aws_route" "public_route" {
#  route_table_id         = aws_route_table.public_route_table.id
#  destination_cidr_block = "0.0.0.0/0"
#  gateway_id             = aws_internet_gateway.internet_gateway.id
#  depends_on             = [aws_route_table.public_route_table]
#}
#
#resource "aws_route_table_association" "public_subnet_one_route_table_association" {
#  subnet_id      = aws_subnet.public_subnet_one.id
#  route_table_id = aws_route_table.public_route_table.id
#}
#
#resource "aws_route_table_association" "public_subnet_two_route_table_association" {
#  subnet_id      = aws_subnet.public_subnet_two.id
#  route_table_id = aws_route_table.public_route_table.id
#}
#
#resource "aws_ecs_cluster" "ecs_cluster" {
#  name = local.ecs_cluster_full_name
#
#  setting {
#    name  = "containerInsights"
#    value = "enabled"
#  }
#
#  tags = merge(
#    { environment = var.environment },
#    { app_name = var.app_name },
#
#    var.default_tags
#  )
#}
#
#resource "aws_iam_role" "ecs_role" {
#  name = local.ecs_role_full_name
#
#  assume_role_policy = jsonencode({
#    Version   = "2012-10-17"
#    Statement = [
#      {
#        Action    = ["sts:AssumeRole"]
#        Effect    = "Allow"
#        Sid       = ""
#        Principal = {
#          Service = ["ecs.amazonaws.com"]
#        }
#      },
#    ]
#  })
#
#  path = "/"
#
#  force_detach_policies = true
#
#  tags = merge(
#    { environment = var.environment },
#    { app_name = var.app_name },
#
#    var.default_tags
#  )
#}
#
#data "aws_iam_policy" "managed_ec2_policy" {
#  name = "AmazonEC2ContainerServiceforEC2Role"
#}
#
#resource "aws_iam_role_policy_attachment" "ec2_policy_ecs_role_attach" {
#  role       = aws_iam_role.ecs_role.id
#  policy_arn = data.aws_iam_policy.managed_ec2_policy.arn
#}
#
#resource "aws_iam_role" "ecs_task_execution_role" {
#  name = local.ecs_task_execution_role_full_name
#
#  assume_role_policy = jsonencode({
#    Version   = "2012-10-17"
#    Statement = [
#      {
#        Action    = ["sts:AssumeRole"]
#        Effect    = "Allow"
#        Sid       = ""
#        Principal = {
#          Service = ["ecs-tasks.amazonaws.com"]
#        }
#      },
#    ]
#  })
#
#  path = "/"
#
#  force_detach_policies = true
#
#  tags = merge(
#    { environment = var.environment },
#    { app_name = var.app_name },
#
#    var.default_tags
#  )
#}
#
#data "aws_iam_policy" "managed_ecs_task_execution_policy" {
#  name = "AmazonECSTaskExecutionRolePolicy"
#}
#
#resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_ecs_task_execution_role_attach" {
#  role       = aws_iam_role.ecs_task_execution_role.id
#  policy_arn = data.aws_iam_policy.managed_ecs_task_execution_policy.arn
#}
#
#
#data "aws_iam_policy" "managed_app_mesh_policy" {
#  name = "AWSAppMeshEnvoyAccess"
#}
#
#resource "aws_iam_role_policy_attachment" "app_mesh_policy_ecs_task_execution_role_attach" {
#  role       = aws_iam_role.ecs_task_execution_role.id
#  policy_arn = data.aws_iam_policy.managed_app_mesh_policy.arn
#}
#
#data "aws_iam_policy" "managed_xray_write_access_policy" {
#  name = "AWSXRayDaemonWriteAccess"
#}
#
#resource "aws_iam_role_policy_attachment" "xray_write_access_policy_ecs_task_execution_role_attach" {
#  role       = aws_iam_role.ecs_task_execution_role.id
#  policy_arn = data.aws_iam_policy.managed_xray_write_access_policy.arn
#}
#
#data "aws_iam_policy" "managed_cloudwatch_full_access_policy" {
#  name = "CloudWatchFullAccess"
#}
#
#resource "aws_iam_role_policy_attachment" "cloudwatch_full_access_ecs_task_execution_role_attach" {
#  role       = aws_iam_role.ecs_task_execution_role.id
#  policy_arn = data.aws_iam_policy.managed_cloudwatch_full_access_policy.arn
#}

resource "aws_security_group" "load_balancer_security_group" {
  name = local.sg_lb_full_name

  vpc_id = aws_vpc.fargate_vpc.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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

  from_port   = 0
  to_port     = 0
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

  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_vpc_security_group_egress_rule" "public_traffic_egress_rule" {
  security_group_id = aws_security_group.fargate_instances_security_group.id

  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

}