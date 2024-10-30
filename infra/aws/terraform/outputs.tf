output "eks_cluster_id" {
  value = module.eks.cluster_id
}

output "db_rds_oracle_endpoint" {
  value = module.oracle.oracle_endpoint
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "dbtools_public_ip" {
  value = module.dbtools.public_ip
}

output "public_dns" {
  description = "Oracle Tools public DNS"
  value       = module.dbtools.public_dns
}

output "kafka_bootstrap" {
  description = "Kafka Bootstrap"
  value       =  module.msk.bootstrap_brokers
}

output "vpc_private_subnets" {
  value       = module.base.vpc_private_subnets
  description = "VPC Private Subnets"
}

output "general_security_group_id" {
  description = "General Security Group ID"
  value       = module.base.general_security_group_id
}
