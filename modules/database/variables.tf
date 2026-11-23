variable "name" {
  description = "Prefijo de nombres."
  type        = string
}

variable "subnet_ids" {
  description = "Subredes privadas para el grupo RDS."
  type        = list(string)
}

variable "security_group_id" {
  description = "ID del grupo de seguridad de la base."
  type        = string
}

variable "instance_class" {
  description = "Clase de instancia RDS."
  type        = string
}

variable "db_name" {
  description = "Nombre inicial de la base."
  type        = string
}

variable "username" {
  description = "Usuario administrador inicial."
  type        = string
}

variable "password" {
  description = "Contraseña del usuario administrador."
  type        = string
  sensitive   = true
}
