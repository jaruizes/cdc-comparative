variable "base_name" {
  type = string
  description = "Base name"
  default = "cdc"
}
// TODO Cambiar a version 1.21
variable "eks_cluster_version" {
  type = string
  description = "EKS cluster version"
  default = "1.29"
}

variable "eks_workers_instance_types" {
  description = "Workers instance types"
  type        = list(string)
  default     = ["m5.xlarge"]
}

variable "eks_workers_desired_capacity" {
  description = "Number of workers (desired)"
  type        = number
  default     = 3
}

variable "msk_cluster_version" {
  description = "MSK Cluster version"
  default = "3.5.1"
}

variable "msk_broker_nodes" {
  description = "MSK Broker nodes"
  default = 3
}

variable "msk_cluster_nodes_instance_type" {
  description = "Nodes instance type"
  default = "kafka.m5.xlarge"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-1"
}

