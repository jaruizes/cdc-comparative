variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "msk_cluster_name" {
  description = "Cluster name"
  type        = string
}

variable "msk_cluster_version" {
  description = "Cluster version"
  type        = string
}

variable "msk_cluster_broker_nodes" {
  description = "Broker nodes"
  type    = number
}

variable "msk_cluster_nodes_instance_type" {
  description = "Nodes instance type"
  type    = string
}

variable "vpc_private_subnets" {
  description = "The list of the private subnets"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security Group"
  type        = string
}
