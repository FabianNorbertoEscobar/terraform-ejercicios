output "vpc_id" {
  description = "ID de la VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_id" {
  description = "ID de la subred pública."
  value       = aws_subnet.public.id
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas."
  value       = aws_subnet.private[*].id
}

output "web_security_group_id" {
  description = "ID del grupo de seguridad web."
  value       = aws_security_group.web.id
}

output "database_security_group_id" {
  description = "ID del grupo de seguridad de PostgreSQL."
  value       = aws_security_group.database.id
}
