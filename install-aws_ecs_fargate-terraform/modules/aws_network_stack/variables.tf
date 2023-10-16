variable "default_tags" {
  description = "Default tags to add to all resources created inside of this module"
  type        = map(string)
  default = {
    module_name    = "aws_network_stack"
    cloud_provider = "AWS"
    iac_tool       = "Terraform"
  }
}
variable "hosted_zone" {
  description = "Hosted Zone to use to create the alias to reach out it through a DNS, this must be created beforehand"
  type        = string
}

variable "dns_name" {
  type = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.dns_name))
    error_message = "Invalid DNS name. It should start with a letter and contain only alphanumeric characters and hyphens."
  }
}

variable "app_name" {
  description = "Target application name, the default value is 'aws-network-stack'"
  type        = string
  default     = "aws-network-stack"
}


variable "environment" {
  description = "Environment name to use the resources"
  type        = string
  default     = "dev"
}

variable "vpc_cidr_block" {
  description = "CIDR for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_one_cidr_block" {
  description = "CIDR for Subnet One"
  type        = string
  default     = "10.0.0.0/24"
}

variable "subnet_two_cidr_block" {
  description = "CIDR for Subnet Two"
  type        = string
  default     = "10.0.1.0/24"
}

locals {
  mappings = {
    SubnetConfig = {
      VPC = {
        CIDR = var.vpc_cidr_block
      }
    }
  }

  number_az = length(slice(data.aws_availability_zones.availability_zones.names, 0, 2))

  app_name_snake_case = join("", [for word in split("-", var.app_name) : title(word)])

  vpc_full_name                  = "${var.app_name}-vpc-${var.environment}"
  public_subnet_full_name        = "${var.app_name}-public-subnet-${var.environment}"
  private_subnet_full_name       = "${var.app_name}-private-subnet-${var.environment}"
  db_subnet_full_name            = "${var.app_name}-db-subnet-${var.environment}"
  internet_gw_full_name          = "${var.app_name}-internet-gw-${var.environment}"
  private_eip_full_name          = "${var.app_name}-private_eip-${var.environment}"
  nat_gateway_full_name          = "${var.app_name}-nat_gateway-${var.environment}"
  public_route_table_full_name   = "${var.app_name}-public-route-table-${var.environment}"
  private_route_table_full_name  = "${var.app_name}-private-route-table-${var.environment}"
  db_route_table_full_name       = "${var.app_name}-db-route-table-${var.environment}"
  ecs_cluster_full_name          = "${var.app_name}-ecs-cluster-${var.environment}"
  sg_lb_full_name                = "${var.app_name}-load-blancer-sg-${var.environment}"
  sg_fargate_instances_full_name = "${var.app_name}-container-sg-${var.environment}"
  load_balancer_full_name        = "${var.app_name}-load-balancer-${var.environment}"
  default_target_group_full_name = lower("default-target-group-${var.environment}")
  default_lb_listener_full_name  = "${var.app_name}-lb-Listener-${var.environment}"

}

variable "task_execution_policy_set" {
  description = "Policies"
  type        = set(string)
  default = [
    "AmazonECSTaskExecutionRolePolicy",
    "AWSAppMeshEnvoyAccess",
    "AWSXRayDaemonWriteAccess",
    "CloudWatchLogsFullAccess"
  ]
}
