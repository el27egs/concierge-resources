variable "default_tags" {
  description = "Default tags to add to all resources created inside of this module"
  type        = map(string)
  default = {
    module_name    = "aws_network_stack"
    cloud_provider = "AWS"
    iac_tool       = "terraform"
  }
}

variable "app_name" {
  description = "Target application name, the default value is 'aws_network_stack'"
  type        = string
  default     = "aws_network_stack"
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
      PublicOne = {
        CIDR = var.subnet_one_cidr_block
      }
      PublicTwo = {
        CIDR = var.subnet_two_cidr_block
      }
    }
  }

  vpc_full_name                = "${var.app_name}-vpc-${var.environment}"
  subnet_one_full_name         = "${var.app_name}-subnet_one-${var.environment}"
  subnet_two_full_name         = "${var.app_name}-subnet_two-${var.environment}"
  internet_gw_full_name        = "${var.app_name}-internet_gw-${var.environment}"
  public_route_table_full_name = "${var.app_name}-public_route_table-${var.environment}"
  ecs_cluster_full_name        = "${var.app_name}-ecs_cluster-${var.environment}"

}
