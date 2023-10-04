variable "default_tags" {
  description = "Default tags to add to all resources created inside of this module"
  type        = map(string)
  default = {
    module_name    = "aws_network_stack"
    cloud_provider = "AWS"
    iac_tool       = "Terraform"
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
  default     = "Dev"
}

variable "ecs_role" {
  description = "The ARN of the ECS role, default to an empty string"
  default     = ""
}

variable "ecs_task_execution_role" {
  description = "The ARN of the ECS task execution role"
}

variable "vpc_id" {
  description = "The ID of the vpc that this stack is deployed on"
}

variable "public_listener" {
  description = "The ARN of the public lister of load balancer"
}

variable "cluster_name" {
  description = "The name of the ECS cluster"
}

variable "public_subnet_one" {
  description = "Public subnet one"
}

variable "public_subnet_two" {
  description = "Public subnet two"
}

variable "fargate_instances_security_group" {
  description = "A security group used to allow Fargate containers to receive traffic"
}
