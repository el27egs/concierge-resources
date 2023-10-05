output "region_name" {
  description = "Current region name to deploy network stack"
  value       = data.aws_region.current_region.name
}

output "vpc_id" {
  description = "The ID of the vpc that this stack is deployed on"
  value       = aws_vpc.fargate_vpc.id
}

output "public_subnet_one" {
  description = "Public subnet one"
  value       = aws_subnet.public_subnet_one.id
}

output "public_subnet_two" {
  description = "Public subnet two"
  value       = aws_subnet.public_subnet_two.id
}

output "fargate_instances_security_group" {
  description = "A security group used to allow Fargate containers to receive traffic"
  value       = aws_security_group.fargate_instances_security_group.id
}

output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.ecs_cluster.name
}

output "ecs_task_role" {
  description = "The ARN of the ECS role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_task_execution_role" {
  description = "The ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "public_listener" {
  description = "The ARN of the public load balancer's listener"
  value       = aws_lb_listener.default_lb_listener.arn
}

output "balancer_dns_url" {
  description = "The URL of the external load balancer"
  value       = "http://${aws_lb.public_load_balancer.dns_name}"
}

output "domain_dns_url" {
  description = "The URL of the domain"
  value       = "http://${aws_route53_record.auth_server_record.name}"
}