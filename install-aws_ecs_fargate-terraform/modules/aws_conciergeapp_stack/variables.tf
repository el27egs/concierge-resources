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
  description = "Target application name, the default value is 'conciergeapp'"
  type        = string
  default     = "conciergeapp"
}

variable "environment" {
  description = "Environment name to use the resources"
  type        = string
  default     = "Dev"
}

variable "ecs_task_role" {
  description = "The ARN of the ECS role, default to an empty string"
  default     = ""
}

variable "ecs_task_execution_role" {
  description = "The ARN of the ECS task execution role"
}

variable "region_name" {
  description = "Region name where where deploy network resources"
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

variable "auth_server_name" {
  description = "The name for the authorization server/service, 'auth_server' is used as default"
  type        = string
  default     = "auth_server"
}

variable "auth_server_image_url" {
  description = "URL to use to pull image for the authorization server/service"
  type        = string
}

variable "auth_server_port" {
  description = "Default port for the authorization server/service, 8080 is used as default"
  type        = number
  default     = 8080
}

variable "auth_server_protocol" {
  description = "Protocol for the authorization server/service, 'HTTP' is used as default"
  type        = string
  default     = "HTTP"
}

variable "auth_server_health_path" {
  description = "Health path for the authorization server/service, '/auth/realms/concierge/' is used as default"
  type        = string
  default     = "/auth/realms/concierge/"
}

variable "auth_server_health_interval" {
  description = "Interval in seconds to check health path for the authorization server/service, 60 is used as default"
  type        = number
  default     = 60
}

variable "auth_server_health_protocol" {
  description = "Protocol health check for the authorization server/service, 'HTTP' is used as default"
  type        = string
  default     = "HTTP"
}

variable "auth_server_cpu" {
  description = "CPU required for the authorization server/service container, 1024 is used as default"
  type        = number
  default     = 1024
}

variable "auth_server_memory" {
  description = "Memory required for the authorization server/service container, 2048 is used as default"
  type        = number
  default     = 2048
}

variable "auth_server_desired_count" {
  description = "How many copies of the service task to run, 1' is used as default"
  type        = number
  default     = 1
}

variable "auth_server_rule_priority" {
  description = <<-EOL
  "The priority for the routing rule added to the load balancer.
  This only applies if your have multiple services which have been assigned to different paths on the load balancer"
  EOL
  type        = number
  default     = 1
}

variable "auth_server_path_pattern" {
  description = <<-EOL
  "Path pattern to forward traffic from load balancer to authorization server/service target group,
  '/auth/*' is used as default value"
  EOL
  type        = string
  default     = "/auth/*"
}

variable "app_server_name" {
  description = "The name for the authorization server/service, 'app_server' is used as default"
  type        = string
  default     = "app_server"
}

variable "app_server_image_url" {
  description = "URL to use to pull image for the authorization server/service"
  type        = string
}

variable "app_server_port" {
  description = "Default port for the authorization server/service, 8080 is used as default"
  type        = number
  default     = 8080
}

variable "app_server_protocol" {
  description = "Protocol for the authorization server/service, 'HTTP' is used as default"
  type        = string
  default     = "HTTP"
}

variable "app_server_health_path" {
  description = "Health path for the authorization server/service, '/app/hello' is used as default"
  type        = string
  default     = "/app/hello"
}

variable "app_server_health_interval" {
  description = "Interval in seconds to check health path for the authorization server/service, 60 is used as default"
  type        = number
  default     = 60
}

variable "app_server_health_protocol" {
  description = "Protocol health check for the authorization server/service, 'HTTP' is used as default"
  type        = string
  default     = "HTTP"
}

variable "app_server_cpu" {
  description = "CPU required for the authorization server/service container, 1024 is used as default"
  type        = number
  default     = 1024
}

variable "app_server_memory" {
  description = "Memory required for the authorization server/service container, 2048 is used as default"
  type        = number
  default     = 2048
}

variable "app_server_desired_count" {
  description = "How many copies of the service task to run, 1' is used as default"
  type        = number
  default     = 2
}

variable "app_server_rule_priority" {
  description = <<-EOL
  "The priority for the routing rule added to the load balancer.
  This only applies if your have multiple services which have been assigned to different paths on the load balancer"
  EOL
  type        = number
  default     = 2
}

variable "app_server_path_pattern" {
  description = <<-EOL
  "Path pattern to forward traffic from load balancer to authorization server/service target group,
  '/app/*' is used as default value"
  EOL
  type        = string
  default     = "/app/*"
}

locals {

  auth_server_task_def_name     = "${var.auth_server_name}_task_def"
  auth_server_service_name      = "${var.auth_server_name}_service"
  auth_server_target_group_name = "${replace(var.auth_server_name, "_", "-")}-target-group"

  app_server_task_def_name     = "${var.app_server_name}_task_def"
  app_server_service_name      = "${var.app_server_name}_service"
  app_server_target_group_name = "${replace(var.app_server_name, "_", "-")}-target-group"


  services = {

    auth_server = {
      task_definition = {
        family        = local.auth_server_task_def_name
        cpu           = var.auth_server_cpu
        memory        = var.auth_server_memory
        name          = var.auth_server_name
        image         = var.auth_server_image_url
        containerPort = var.auth_server_port
        hostPort      = var.auth_server_port

      }
      target_group = {
        name     = local.auth_server_target_group_name
        port     = var.auth_server_port
        protocol = var.auth_server_protocol
      }
      health_check = {
        interval = var.auth_server_health_interval
        path     = var.auth_server_health_path
        protocol = var.auth_server_health_protocol
      }
      listener_rule = {
        priority = var.auth_server_rule_priority
        values   = [var.auth_server_path_pattern]
      }
      ecs_service = {
        name          = local.auth_server_service_name
        desired_count = var.auth_server_desired_count

        container_name = var.auth_server_name
        container_port = var.auth_server_port
      }
    }

    app_server = {
      task_definition = {
        family        = local.app_server_task_def_name
        cpu           = var.app_server_cpu
        memory        = var.app_server_memory
        name          = var.app_server_name
        image         = var.app_server_image_url
        containerPort = var.app_server_port
        hostPort      = var.app_server_port

      }
      target_group = {
        name     = local.app_server_target_group_name
        port     = var.app_server_port
        protocol = var.app_server_protocol
      }
      health_check = {
        interval = var.app_server_health_interval
        path     = var.app_server_health_path
        protocol = var.app_server_health_protocol
      }
      listener_rule = {
        priority = var.app_server_rule_priority
        values   = [var.app_server_path_pattern]
      }
      ecs_service = {
        name          = local.app_server_service_name
        desired_count = var.app_server_desired_count

        container_name = var.app_server_name
        container_port = var.app_server_port
      }
    }

  }
}