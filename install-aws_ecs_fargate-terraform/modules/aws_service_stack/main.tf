resource "aws_ecs_task_definition" "nginx_task_definition" {
  family       = "nginx_td"
  cpu          = "256"
  memory       = "512"
  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  execution_role_arn = var.ecs_task_execution_role
  task_role_arn      = length(var.ecs_role) != 0 ? var.ecs_role : null

  container_definitions = jsonencode([
    {
      name         = "nginx"
      image        = "nginx"
      cpu          = 256
      memory       = 512
      essential    = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    },
  ])

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}

resource "aws_lb_target_group" "nginx_target_group" {
  name        = "nginx-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    interval            = 6
    path                = "/"
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

resource "aws_lb_listener_rule" "nginx_listener_rule" {

  listener_arn = var.public_listener
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}

resource "aws_ecs_service" "nginx_ecs_service" {

  depends_on = [aws_lb_listener_rule.nginx_listener_rule]

  name        = "nginx_service"
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

  task_definition = aws_ecs_task_definition.nginx_task_definition.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
    container_name   = "nginx"
    container_port   = 80
  }

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )
}