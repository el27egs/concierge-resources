variable "default_tags" {
  description = "Default tags to add to all resources created inside of this module"
  type        = map(string)
  default = {
    module_name    = "aws_network_stack"
    cloud_provider = "AWS"
    iac_tool       = "Terraform"
  }
}

variable "dns_name" {
  type = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.dns_name))
    error_message = "Invalid DNS name. It should start with a letter and contain only alphanumeric characters and hyphens."
  }
}

variable "app_name" {
  description = "Target application name, the default value is 'aws-conciergeapp-stack'"
  type        = string
  default     = "aws-conciergeapp-stack"
}

variable "environment" {
  description = "Environment name to use the resources"
  type        = string
  default     = "dev"
}

variable "task_role_arn" {
  description = "The ARN of the ECS role, default to an empty string"
  default     = ""
}

variable "task_execution_role_arn" {
  description = "The ARN of the ECS task execution role"
}

variable "region_name" {
  description = "Region name where where deploy network resources"
}

variable "vpc_id" {
  description = "The ID of the vpc that this stack is deployed on"
}

variable "http_80_listener_arn" {
  description = "The ARN for http port 80"
}

variable "https_443_listener_arn" {
  description = "The ARN for https port 443"
}

variable "cluster_name" {
  description = "The name of the ECS cluster"
}

variable "subnet_ids" {
  description = "Ids for all subnets created/used by network stack"
}

variable "containers_security_group_id" {
  description = "A security group used to allow Fargate containers to receive traffic"
}

variable "domain_dns_url" {
  description = "Domain URL created by network stack"
}

variable "auth_server_name" {
  description = "The name for the authorization server/service, 'auth-server' is used as default"
  type        = string
  default     = "auth-server"
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

variable "auth_server_max_capacity" {
  description = "Maximum number of copies of the service task to run, 1' is used as default"
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
  description = "The name for the authorization server/service, 'app-server' is used as default"
  type        = string
  default     = "app-server"
}

variable "app_server_image_url" {
  description = "URL to use to pull image for the authorization server/service"
  type        = string
}

variable "app_server_port" {
  description = "Default port for the authorization server/service, 8080 is used as default"
  type        = number
  default     = 8090
}

variable "app_server_protocol" {
  description = "Protocol for the authorization server/service, 'HTTP' is used as default"
  type        = string
  default     = "HTTP"
}

variable "app_server_health_path" {
  description = <<-EOL
  "Health path for the authorization server/service, '/app/health' is used as default.
   Use a different base path for different microservices, those paths are used to route the traffic
   if the microservices are behind of a load balancer with different target groups."
  EOL
  type        = string
  default     = "/app/health"
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

variable "app_server_max_capacity" {
  description = "Maximum number of copies of the service task to run, 5' is used as default"
  type        = number
  default     = 5
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

  namespace_name = "${lower(var.dns_name)}.${lower(var.environment)}"

  database_sg_full_name = "${var.app_name}-database-sg-${var.environment}"

  auth_server_policy_name       = "${var.auth_server_name}_policy"
  auth_server_task_def_name     = "${var.auth_server_name}_task_def"
  auth_server_service_name      = "${var.auth_server_name}_service"
  auth_server_target_group_name = lower("${replace(var.auth_server_name, "_", "-")}-target-group-${var.environment}")

  app_server_policy_name       = "${var.app_server_name}_policy"
  app_server_task_def_name     = "${var.app_server_name}_task_def"
  app_server_service_name      = "${var.app_server_name}_service"
  app_server_target_group_name = lower("${replace(var.app_server_name, "_", "-")}-target-group-${var.environment}")


  services = {

    auth_server = {
      task_definition = {
        environment    = null
        family         = local.auth_server_task_def_name
        cpu            = var.auth_server_cpu
        memory         = var.auth_server_memory
        image          = var.auth_server_image_url
        name           = replace(var.auth_server_name, "_", "-")
        container_name = replace(var.auth_server_name, "_", "-")
        container_port = var.auth_server_port
        host_port      = var.auth_server_port
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
      }
      autoscaling_policy = {
        min_capacity = var.auth_server_desired_count
        max_capacity = var.auth_server_max_capacity
      }
    }

    app_server = {
      task_definition = {
        environment = [
          #          {
          #            name  = "DEBIT_ACCOUNTS_DB_USER",
          #            value = aws_db_instance.concierge_db_instance.username
          #          },
          #          {
          #            name  = "DEBIT_ACCOUNTS_DB_PASSWORD",
          #            value = aws_db_instance.concierge_db_instance.password
          #          },
          #          {
          #            name  = "DEBIT_ACCOUNTS_DB_NAME",
          #            value = aws_db_instance.concierge_db_instance.db_name
          #          },
          #          {
          #            name  = "DEBIT_ACCOUNTS_DB_READ_WRITE_HOST",
          #            value = element(split(":", aws_db_instance.concierge_db_instance.endpoint), 0)
          #          },
          #          {
          #            name  = "DEBIT_ACCOUNTS_DB_READ_WRITE_PORT",
          #            value = tostring(aws_db_instance.concierge_db_instance.port)
          #          },
          #          {
          #            name  = "DEBIT_ACCOUNTS_DB_READ_ONLY_HOST",
          #            value = element(split(":", aws_db_instance.concierge_db_instance.endpoint), 0)
          #          },
          #          {
          #            name  = "DEBIT_ACCOUNTS_DB_READ_ONLY_PORT",
          #            value = tostring(aws_db_instance.concierge_db_instance.port)
          #          },
          {
            name  = "AUTH_URL",
            value = "http://${var.auth_server_name}.${local.namespace_name}"
          },
          {
            name  = "AUTH_PORT",
            value = tostring(var.auth_server_port)
          }
        ]
        family         = local.app_server_task_def_name
        cpu            = var.app_server_cpu
        memory         = var.app_server_memory
        image          = var.app_server_image_url
        name           = replace(var.app_server_name, "_", "-")
        container_name = replace(var.app_server_name, "_", "-")
        container_port = var.app_server_port
        host_port      = var.app_server_port
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
      }
      autoscaling_policy = {
        min_capacity = var.app_server_desired_count
        max_capacity = var.app_server_max_capacity
      }
    }

  }
}