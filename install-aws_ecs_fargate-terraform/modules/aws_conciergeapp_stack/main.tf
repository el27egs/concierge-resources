resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/fargate/${var.app_name}"

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}

resource "aws_ecs_task_definition" "task_definition" {

  for_each = local.services

  family       = local.services[each.key]["task_definition"]["family"]
  cpu          = local.services[each.key]["task_definition"]["cpu"]
  memory       = local.services[each.key]["task_definition"]["memory"]
  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  execution_role_arn = var.ecs_task_execution_role
  task_role_arn      = length(var.ecs_role) != 0 ? var.ecs_role : null

  container_definitions = jsonencode([
    {
      name      = local.services[each.key]["task_definition"]["name"]
      image     = local.services[each.key]["task_definition"]["image"]
      cpu       = local.services[each.key]["task_definition"]["cpu"]
      memory    = local.services[each.key]["task_definition"]["memory"]
      essential = true
      portMappings = [
        {
          containerPort = local.services[each.key]["task_definition"]["containerPort"]
          hostPort      = local.services[each.key]["task_definition"]["hostPort"]
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
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

resource "aws_lb_target_group" "target_group" {

  for_each = local.services

  name        = local.services[each.key]["target_group"]["name"]
  port        = local.services[each.key]["target_group"]["port"]
  protocol    = local.services[each.key]["target_group"]["protocol"]
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    interval            = local.services[each.key]["health_check"]["interval"]
    path                = local.services[each.key]["health_check"]["path"]
    protocol            = local.services[each.key]["health_check"]["protocol"]
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

resource "aws_lb_listener_rule" "listener_rule" {

  for_each = local.services

  listener_arn = var.public_listener
  priority     = local.services[each.key]["listener_rule"]["priority"]

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[each.key].arn
  }

  condition {
    path_pattern {
      values = local.services[each.key]["listener_rule"]["values"]
    }
  }

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}

resource "aws_ecs_service" "ecs_service" {

  depends_on = [aws_lb_listener_rule.listener_rule]

  for_each = local.services

  name    = local.services[each.key]["ecs_service"]["name"]
  cluster = var.cluster_name

  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"

  health_check_grace_period_seconds  = 60
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  desired_count        = local.services[each.key]["ecs_service"]["desired_count"]
  force_new_deployment = true

  network_configuration {
    assign_public_ip = true
    subnets          = [var.public_subnet_one, var.public_subnet_two]
    security_groups  = [var.fargate_instances_security_group]
  }

  task_definition = aws_ecs_task_definition.task_definition[each.key].arn

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group[each.key].arn
    container_name   = local.services[each.key]["ecs_service"]["container_name"]
    container_port   = local.services[each.key]["ecs_service"]["container_port"]
  }

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}
