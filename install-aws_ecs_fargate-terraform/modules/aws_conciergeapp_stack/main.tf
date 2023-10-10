resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/fargate/${var.app_name}"

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}

resource "aws_ecs_task_definition" "task_definition" {

  #  depends_on = [aws_db_instance.concierge_db_instance]

  for_each = local.services

  family       = local.services[each.key]["task_definition"]["family"]
  cpu          = local.services[each.key]["task_definition"]["cpu"]
  memory       = local.services[each.key]["task_definition"]["memory"]
  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  execution_role_arn = var.ecs_task_execution_role
  task_role_arn      = length(var.ecs_task_role) != 0 ? var.ecs_task_role : null

  container_definitions = jsonencode([
    {
      name      = local.services[each.key]["task_definition"]["name"]
      image     = local.services[each.key]["task_definition"]["image"]
      cpu       = local.services[each.key]["task_definition"]["cpu"]
      memory    = local.services[each.key]["task_definition"]["memory"]
      essential = true
      portMappings = [
        {
          containerPort = local.services[each.key]["task_definition"]["container_port"]
          hostPort      = local.services[each.key]["task_definition"]["host_port"]
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

      environment = local.services[each.key]["task_definition"]["environment"]

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

resource "aws_service_discovery_private_dns_namespace" "private_namespace" {
  name = local.namespace_name
  vpc  = var.vpc_id
}

resource "aws_service_discovery_service" "discovery_service_instance" {

  for_each = local.services

  name = local.services[each.key]["task_definition"]["name"]

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.private_namespace.id
    dns_records {
      ttl  = 60
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 10
  }

}

resource "aws_ecs_service" "ecs_service" {

  depends_on = [aws_lb_listener_rule.listener_rule]

  lifecycle {
    ignore_changes        = [desired_count]
    create_before_destroy = true
  }

  for_each = local.services

  # Configure the service to enable auto scaling
  enable_ecs_managed_tags = true

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
    container_name   = local.services[each.key]["task_definition"]["container_name"]
    container_port   = local.services[each.key]["task_definition"]["container_port"]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.discovery_service_instance[each.key].arn
    container_name = local.services[each.key]["task_definition"]["container_name"]
  }

  tags = merge(
    { environment = var.environment },
    { app_name = var.app_name },

    var.default_tags
  )

}

resource "aws_appautoscaling_target" "autoscaling_target" {

  for_each = local.services

  max_capacity       = local.services[each.key]["autoscaling_policy"]["max_capacity"]
  min_capacity       = local.services[each.key]["autoscaling_policy"]["min_capacity"]
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.ecs_service[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "autoscaling_cpu_policy" {

  for_each = local.services

  name               = "AutoScalingCPUPolicy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.autoscaling_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 80
    scale_in_cooldown  = 10
    scale_out_cooldown = 10
  }
}

resource "aws_appautoscaling_policy" "autoscaling_memory_policy" {

  for_each = local.services

  name               = "AutoScalingMemoryPolicy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.autoscaling_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 80
    scale_in_cooldown  = 10
    scale_out_cooldown = 10
  }
}

#resource "aws_security_group" "db_security_group" {
#
#  vpc_id = var.vpc_id
#
#  name        = "concierge-db-sg"
#  description = "Concierge DB security group for RDS"
#
#}
#
#resource "aws_vpc_security_group_ingress_rule" "db_ingress_rule" {
#  security_group_id = aws_security_group.db_security_group.id
#
#  from_port   = 5432
#  to_port     = 5432
#  ip_protocol = "tcp"
#  cidr_ipv4   = "0.0.0.0/0"
#
#  tags = merge(
#    { environment = var.environment },
#    { app_name = var.app_name },
#
#    var.default_tags
#  )
#}
#
#resource "aws_vpc_security_group_egress_rule" "db_egress_rule" {
#  security_group_id = aws_security_group.db_security_group.id
#
#  from_port   = -1
#  to_port     = -1
#  ip_protocol = "-1"
#  cidr_ipv4   = "0.0.0.0/0"
#
#}
#
#resource "aws_db_subnet_group" "db_subnet_group_name" {
#  name       = "main"
#  subnet_ids = [var.public_subnet_one, var.public_subnet_two]
#
#  tags = merge(
#    { Name = "My DB subnet group" },
#    { environment = var.environment },
#    { app_name = var.app_name },
#
#    var.default_tags
#  )
#
#}
#
#resource "aws_db_instance" "concierge_db_instance" {
#  allocated_storage               = 20
#  allow_major_version_upgrade     = false
#  apply_immediately               = true
#  backup_retention_period         = 7
#  db_name                         = "concierge_debit_accounts"
#  db_subnet_group_name            = aws_db_subnet_group.db_subnet_group_name.name
#  delete_automated_backups        = true
#  deletion_protection             = false
#  enabled_cloudwatch_logs_exports = ["postgresql"]
#  engine                          = "postgres"
#  engine_version                  = "14.9"
#  auto_minor_version_upgrade      = true
#  identifier                      = "concierge-debit-accounts"
#  instance_class                  = "db.t3.micro"
#  multi_az                        = true
#  parameter_group_name            = "default.postgres14"
#  password                        = "postgres"
#  port                            = 5432
#  publicly_accessible             = true
#  skip_final_snapshot             = true
#  storage_type                    = "gp2"
#  username                        = "postgres"
#  vpc_security_group_ids          = [aws_security_group.db_security_group.id]
#
#  tags = merge(
#    { environment = var.environment },
#    { app_name = var.app_name },
#
#    var.default_tags
#  )
#
#}
#
#resource "aws_db_instance" "concierge_db_instance_replica" {
#  identifier             = "concierge-debit-accounts-replica"
#  replicate_source_db    = aws_db_instance.concierge_db_instance.identifier
#  instance_class         = "db.t3.micro"
#  apply_immediately      = true
#  publicly_accessible    = true
#  skip_final_snapshot    = true
#  vpc_security_group_ids = [aws_security_group.db_security_group.id]
#  parameter_group_name   = "default.postgres14"
#}

