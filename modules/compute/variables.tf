variable "name" {
  description = "Prefijo de nombres."
  type        = string
}

variable "subnet_id" {
  description = "ID de la subred pública."
  type        = string
}

variable "security_group_id" {
  description = "ID del grupo de seguridad web."
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2."
  type        = string
}

variable "key_name" {
  description = "Key pair existente o null."
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Etiquetas comunes para el volumen EBS."
  type        = map(string)
}
