output "security_group_id" {
  description = "General Security Group"
  value       = aws_security_group.general_security_group.id
}
