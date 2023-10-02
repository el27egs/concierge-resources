module "aws_network_stack" {
  source   = "./modules/aws_network_stack"
  app_name = "ConciergeApp"
}

module "aws_service_stack" {
  source = "./modules/aws_service_stack"

  depends_on = [module.aws_network_stack]

  ecs_task_execution_role = module.aws_network_stack.ecs_task_execution_role

  vpc_id            = module.aws_network_stack.vpc_id
  public_listener   = module.aws_network_stack.public_listener
  cluster_name      = module.aws_network_stack.cluster_name
  public_subnet_one = module.aws_network_stack.public_subnet_one
  public_subnet_two = module.aws_network_stack.public_subnet_two

  fargate_instances_security_group = module.aws_network_stack.fargate_instances_security_group
}
