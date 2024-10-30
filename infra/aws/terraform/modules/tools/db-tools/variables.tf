variable "vpc_public_subnets" {
  description = "The list of the public subnets"
  type        = list(string)
}

variable "security_group_id" {
  description = "Oracle Security Group"
  type        = string
}

variable "ssh_key_name" {
  description = "Oracle SSH KEY"
  type        = string
}
