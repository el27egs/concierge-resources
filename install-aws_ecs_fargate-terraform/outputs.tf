output "balancer_dns_url" {
  description = "The URL of the external load balancer"
  value       = module.aws_network_stack.balancer_dns_url
}

output "domain_dns_url" {
  description = "The URL of the domain"
  value       = module.aws_network_stack.domain_dns_url
}
