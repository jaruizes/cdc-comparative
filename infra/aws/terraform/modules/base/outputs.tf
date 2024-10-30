/*** VPC ***/
output "vpc_id" {
  value       = module.vpc.id
  description = "VPC ID"
}

output "vpc_cidr_block" {
  value       = module.vpc.vpc_cidr_block
  description = "VPC ID"
}

output "vpc_private_subnets" {
  value       = module.vpc.private_subnets
  description = "VPC Private Subnets"
}

output "vpc_public_subnets" {
  value       = module.vpc.public_subnets
  description = "VPC Public Subnets"
}

/*** Security Groups ***/
output "general_security_group_id" {
  description = "General Security Group ID"
  value       = module.general_security_group.security_group_id
}


/*** EKS ***/
#output "eks_cluster_id" {
#  description = "EKS cluster ID"
#  value       = module.eks.cluster_id
#}
