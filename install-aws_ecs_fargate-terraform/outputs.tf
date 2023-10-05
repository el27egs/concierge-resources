output "vpc_id" {
  description = "The ID of the vpc that this stack is deployed on"
  value       = module.aws_network_stack.vpc_id
}

output "public_subnet_one" {
  description = "Public subnet one"
  value       = module.aws_network_stack.public_subnet_one
}

output "public_subnet_two" {
  description = "Public subnet two"
  value       = module.aws_network_stack.public_subnet_two
}

output "fargate_container_security_group" {
  description = "A security group used to allow Fargate containers to receive traffic"
  value       = module.aws_network_stack.fargate_instances_security_group
}

output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.aws_network_stack.cluster_name
}

output "ecs_role" {
  description = "The ARN of the ECS role"
  value       = module.aws_network_stack.ecs_role
}

output "ecs_task_execution_role" {
  description = "The ARN of the ECS task execution role"
  value       = module.aws_network_stack.ecs_task_execution_role
}

output "public_listener" {
  description = "The ARN of the public load balancer's listener"
  value       = module.aws_network_stack.public_listener
}

output "balancer_dns_url" {
  description = "The URL of the external load balancer"
  value       = module.aws_network_stack.balancer_dns_url
}

output "domain_dns_url" {
  description = "The URL of the domain"
  value       = module.aws_network_stack.domain_dns_url
}