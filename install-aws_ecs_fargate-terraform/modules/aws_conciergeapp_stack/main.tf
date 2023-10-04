resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/fargate/${var.app_name}"

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}

resource "aws_ecs_task_definition" "auth_server_task_definition" {

  depends_on = [aws_cloudwatch_log_group.log_group]

  family       = local.auth_server_task_def_name
  cpu          = var.auth_server_cpu
  memory       = var.auth_server_memory
  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  execution_role_arn = var.ecs_task_execution_role
  task_role_arn      = length(var.ecs_role) != 0 ? var.ecs_role : null

  container_definitions = jsonencode([
    {
      name         = var.auth_server_name
      image        = var.auth_server_image_url
      cpu          = var.auth_server_cpu
      memory       = var.auth_server_memory
      essential    = true
      portMappings = [
        {
          containerPort : var.auth_server_port
          hostPort : var.auth_server_port
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.log_group.name
          "awslogs-region"        = var.region_name
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
  name        = local.auth_server_target_group_name
  port        = var.auth_server_port
  protocol    = var.auth_server_protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    interval            = var.auth_server_health_interval
    path                = var.auth_server_health_path
    protocol            = var.auth_server_health_protocol
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
  priority     = var.auth_server_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth_server_target_group.arn
  }

  condition {
    path_pattern {
      values = [var.auth_server_path_pattern]
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

  name    = local.auth_server_service_name
  cluster = var.cluster_name

  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"

  health_check_grace_period_seconds  = 60
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  desired_count        = var.auth_server_desired_count
  force_new_deployment = true

  network_configuration {
    assign_public_ip = true
    subnets          = [var.public_subnet_one, var.public_subnet_two]
    security_groups  = [var.fargate_instances_security_group]
  }

  task_definition = aws_ecs_task_definition.auth_server_task_definition.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.auth_server_target_group.arn
    container_name   = var.auth_server_name
    container_port   = var.auth_server_port
  }

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}
