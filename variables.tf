variable "aws_region" {
  description = "Región AWS donde crear los recursos."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "Indica una región AWS válida, como us-east-1."
  }
}

variable "project_name" {
  description = "Prefijo corto para nombres y etiquetas."
  type        = string
  default     = "terraform-lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}$", var.project_name)) && !endswith(var.project_name, "-")
    error_message = "Usa 2-20 caracteres minúsculos, números o guiones; comienza con una letra y no termines en guion."
  }
}

variable "environment" {
  description = "Nombre del entorno de aprendizaje."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "El entorno debe ser dev o prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR IPv4 /16 para la VPC; se subdivide en redes /24."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrsubnet(var.vpc_cidr, 8, 2)) && try(tonumber(split("/", var.vpc_cidr)[1]) == 16 && !strcontains(var.vpc_cidr, ":"), false)
    error_message = "Indica un CIDR IPv4 válido con máscara /16."
  }
}

variable "ssh_cidr" {
  description = "CIDR IPv4 de confianza permitido para SSH, preferentemente tu IP /32."
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_cidr, 0)) && !strcontains(var.ssh_cidr, ":") && try(tonumber(split("/", var.ssh_cidr)[1]) > 0, false)
    error_message = "Indica un CIDR IPv4 válido diferente de 0.0.0.0/0."
  }
}

variable "key_name" {
  description = "Nombre de una key pair EC2 existente; null deshabilita el acceso SSH mediante clave."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Tipo pequeño de instancia EC2."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro"], var.instance_type)
    error_message = "Selecciona t2.micro o t3.micro."
  }
}

variable "db_instance_class" {
  description = "Clase de instancia PostgreSQL para el laboratorio."
  type        = string
  default     = "db.t3.micro"

  validation {
    condition     = contains(["db.t3.micro", "db.t3.small", "db.t4g.micro"], var.db_instance_class)
    error_message = "Selecciona db.t3.micro, db.t3.small o db.t4g.micro."
  }
}

variable "db_name" {
  description = "Nombre inicial de la base PostgreSQL."
  type        = string
  default     = "labdb"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]{0,62}$", var.db_name))
    error_message = "Usa 1-63 caracteres alfanuméricos, comenzando con una letra."
  }
}

variable "db_username" {
  description = "Usuario administrador inicial de PostgreSQL."
  type        = string
  default     = "labadmin"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,15}$", var.db_username))
    error_message = "Usa 1-16 caracteres alfanuméricos o guion bajo, comenzando con una letra."
  }
}

variable "db_password" {
  description = "Contraseña de PostgreSQL. Proporcionar con TF_VAR_db_password."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8 && length(var.db_password) <= 128 && can(regex("^[!-~]+$", var.db_password)) && !strcontains(var.db_password, "\"") && !strcontains(var.db_password, "/") && !strcontains(var.db_password, "@")
    error_message = "Usa 8-128 caracteres ASCII imprimibles sin espacios ni comillas dobles, / o @."
  }
}
