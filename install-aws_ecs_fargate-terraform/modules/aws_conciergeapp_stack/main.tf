data aws_region "current_region" {}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/fargate/conciergeapp"

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}

resource "aws_ecs_task_definition" "auth_server_task_definition" {

  depends_on = [data.aws_region.current_region, aws_cloudwatch_log_group.log_group]

  family       = "auth_server_task_def"
  cpu          = "1024"
  memory       = "2048"
  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  execution_role_arn = var.ecs_task_execution_role
  task_role_arn      = length(var.ecs_role) != 0 ? var.ecs_role : null

  container_definitions = jsonencode([
    {
      name         = "auth_server"
      image        = "391361142564.dkr.ecr.us-east-1.amazonaws.com/concierge-auth-server:1.0.1"
      cpu          = 1024
      memory       = 2048
      essential    = true
      portMappings = [
        {
          containerPort : 8080
          hostPort : 8080
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.log_group.name
          "awslogs-region"        = data.aws_region.current_region.name
          "awslogs-stream-prefix" = "service"
        }
      }
    }
  ])

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}

resource "aws_lb_target_group" "auth_server_target_group" {
  name        = "auth-server-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    interval            = 60
    path                = "/auth/realms/concierge/"
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

resource "aws_lb_listener_rule" "auth_server_listener_rule" {

  listener_arn = var.public_listener
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth_server_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/auth/*"]
    }
  }

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_ecs_service" "auth_server_ecs_service" {

  depends_on = [aws_lb_listener_rule.auth_server_listener_rule]

  name        = "auth_server_svc"
  cluster     = var.cluster_name
  launch_type = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 75

  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    assign_public_ip = true
    subnets          = [var.public_subnet_one, var.public_subnet_two]
    security_groups  = [var.fargate_instances_security_group]
  }

  task_definition = aws_ecs_task_definition.auth_server_task_definition.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.auth_server_target_group.arn
    container_name   = "auth_server"
    container_port   = 8080
  }

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}