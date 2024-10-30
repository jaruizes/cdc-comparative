terraform {
  required_version = ">= 0.13"
}

provider "aws" {
  region = var.aws_region
  profile = "paradigma"
}

module "base" {
  source = "./modules/base"
  base_name = var.base_name
  aws_region = var.aws_region
}

module "eks" {
  source = "./modules/eks"
  eks_cluster_name = var.base_name
  eks_cluster_version = var.eks_cluster_version
  eks_workers_instance_types = var.eks_workers_instance_types
  eks_workers_desired_capacity = var.eks_workers_desired_capacity
  vpc_id = module.base.vpc_id
  vpc_private_subnets = module.base.vpc_private_subnets
}

module "oracle" {
  source = "./modules/oracle"
  vpc_public_subnets = module.base.vpc_public_subnets
  security_group_id = module.base.general_security_group_id
  db_name = var.base_name
}

module "msk" {
  source = "./modules/msk"
  vpc_id = module.base.vpc_id
  security_group_id = module.base.general_security_group_id
  msk_cluster_name = var.base_name
  msk_cluster_version = var.msk_cluster_version
  msk_cluster_broker_nodes = var.msk_broker_nodes
  vpc_private_subnets = module.base.vpc_private_subnets
  msk_cluster_nodes_instance_type = var.msk_cluster_nodes_instance_type
}

module "keypair" {
  source = "./modules/tools/keypair"
  keypair_name = var.base_name
}

module "dbtools" {
  source = "./modules/tools/db-tools"
  security_group_id = module.base.general_security_group_id
  ssh_key_name = module.keypair.keypair_name
  vpc_public_subnets = module.base.vpc_public_subnets
}
