output "public_ip" {
  description = "Dirección IPv4 pública de la instancia web."
  value       = aws_instance.web.public_ip
}
