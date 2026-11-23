output "vpc_id" {
  description = "ID de la VPC del laboratorio."
  value       = module.network.vpc_id
}

output "ec2_public_ip" {
  description = "IP pública de la instancia web."
  value       = module.compute.public_ip
}

output "web_url" {
  description = "URL HTTP de Nginx."
  value       = "http://${module.compute.public_ip}"
}

output "bucket_name" {
  description = "Nombre del bucket S3."
  value       = module.storage.bucket_name
}

output "db_endpoint" {
  description = "Endpoint privado de PostgreSQL, incluido el puerto."
  value       = module.database.endpoint
}
