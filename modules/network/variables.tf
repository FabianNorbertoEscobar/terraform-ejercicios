variable "name" {
  description = "Prefijo de nombres."
  type        = string
}

variable "vpc_cidr" {
  description = "Bloque IPv4 de la VPC."
  type        = string
}

variable "availability_zones" {
  description = "Dos zonas de disponibilidad distintas."
  type        = list(string)
}

variable "ssh_cidr" {
  description = "Red IPv4 permitida para SSH."
  type        = string
}
