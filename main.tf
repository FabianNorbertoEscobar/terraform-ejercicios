# Los data sources consultan información existente, sin crear recursos.
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "network" {
  source = "./modules/network"

  name               = local.name
  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  ssh_cidr           = var.ssh_cidr
}

module "compute" {
  source = "./modules/compute"

  name              = local.name
  subnet_id         = module.network.public_subnet_id
  security_group_id = module.network.web_security_group_id
  instance_type     = var.instance_type
  key_name          = var.key_name
  common_tags       = local.common_tags

  # El primer arranque necesita la ruta pública para instalar Nginx.
  depends_on = [module.network]
}

module "storage" {
  source = "./modules/storage"

  name        = local.name
  bucket_name = "${local.name}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}

module "database" {
  source = "./modules/database"

  name              = local.name
  subnet_ids        = module.network.private_subnet_ids
  security_group_id = module.network.database_security_group_id
  instance_class    = var.db_instance_class
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password
}
