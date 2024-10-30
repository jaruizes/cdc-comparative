output "public_ip" {
  description = "Oracle Tools public IP"
  value       = aws_instance.oracle.public_ip
}

output "public_dns" {
  description = "Oracle Tools public DNS"
  value       = aws_instance.oracle.public_dns
}
