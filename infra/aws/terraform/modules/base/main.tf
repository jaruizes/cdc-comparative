module "vpc" {
  source = "./modules/vpc"
  vpc_name = var.base_name
  aws_region = var.aws_region
}

module "general_security_group" {
  source = "./modules/security_group"
  sg_name = var.base_name
  vpc_cidr_block = module.vpc.vpc_cidr_block
  vpc_id = module.vpc.id
}
