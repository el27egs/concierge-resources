output "region_name" {
  description = "Current region name to deploy network stack"
  value       = data.aws_region.current_region.name
}

output "vpc_id" {
  description = "The ID of the vpc that this stack is deployed on"
  value       = aws_vpc.vpc.id
}

output "subnet_ids" {
  description = "Ids for all subnets used for the network stack"
  #  Es posible mover las instancias a las subredes privadas sin problema
  #  value       = aws_subnet.private_subnets[*].id
  value = aws_subnet.public_subnets[*].id
}

output "containers_security_group_id" {
  description = "A security group used to allow Fargate containers to receive traffic"
  value       = aws_security_group.containers_sg.id
}

output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.ecs_cluster.name
}

output "task_role_arn" {
  description = "The ARN of the IAM role"
  value       = aws_iam_role.task_role.arn
}

output "task_execution_role_arn" {
  description = "The ARN of the ECS task execution role"
  value       = aws_iam_role.task_execution_role.arn
}

output "http_80_listener_arn" {
  description = "The ARN for http lister for port 80"
  value       = aws_lb_listener.http_80_listener.arn
}

output "https_443_listener_arn" {
  description = "The ARN for https lister for port 443"
  value       = aws_lb_listener.https_443_listener.arn
}

output "balancer_dns_url" {
  description = "The URL of the external load balancer"
  value       = "http://${aws_lb.public_load_balancer.dns_name}"
}

output "domain_dns_url" {
  description = "The URL of the domain"
  value       = "http://${aws_route53_record.default_dsn_alias_record.name}"
}