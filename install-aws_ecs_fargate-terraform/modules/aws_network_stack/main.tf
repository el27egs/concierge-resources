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
  tags   = merge(
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

