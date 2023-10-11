module "aws_network_stack" {
  source = "./modules/aws_network_stack"

  hosted_zone = "starlingapps.com"
  dns_name    = "concierge"
  app_name    = "concierge-app"
}

module "aws_conciergeapp_stack" {
  source = "./modules/aws_conciergeapp_stack"

  depends_on = [module.aws_network_stack]

  dns_name = "concierge"
  app_name = "concierge-app"

  region_name                  = module.aws_network_stack.region_name
  vpc_id                       = module.aws_network_stack.vpc_id
  default_lb_listener_arn      = module.aws_network_stack.default_lb_listener_arn
  cluster_name                 = module.aws_network_stack.cluster_name
  subnet_ids                   = module.aws_network_stack.subnet_ids
  task_execution_role_arn      = module.aws_network_stack.task_execution_role_arn
  task_role_arn                = module.aws_network_stack.task_role_arn
  containers_security_group_id = module.aws_network_stack.containers_security_group_id
  domain_dns_url               = module.aws_network_stack.domain_dns_url

  auth_server_name          = "auth-server"
  auth_server_rule_priority = 1
  auth_server_image_url     = "391361142564.dkr.ecr.us-east-1.amazonaws.com/concierge-auth-server:latest"

  app_server_name          = "app-server"
  app_server_rule_priority = 2
  app_server_image_url     = "391361142564.dkr.ecr.us-east-1.amazonaws.com/concierge-aws-test:latest"

}
