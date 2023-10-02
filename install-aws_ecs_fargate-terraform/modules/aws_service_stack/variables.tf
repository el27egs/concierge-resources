variable "default_tags" {
  description = "Default tags to add to all resources created inside of this module"
  type        = map(string)
  default     = {
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
  description = "The ARN of the ECS role"
}

variable "ecs_task_execution_role" {
  description = "The ARN of the ECS task execution role"
}

variable "vpc_id" {
  description = "The ID of the vpc that this stack is deployed on"
}
