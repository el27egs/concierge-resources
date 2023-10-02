output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.ecs_cluster.arn
}

output "ecs_role" {
  description = "The ARN of the ECS role"
  value       = aws_iam_role.ecs_role.arn
}

output "ecs_task_execution_role" {
  description = "The ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "public_listener" {
  description = "The ARN of the public load balancer's listener"
  value       = aws_lb_listener.default_lb_listener.arn
}

output "external_url" {
  description = "The URL of the external load balancer"
  value       = "http://${aws_lb.public_load_balancer.dns_name}"
}