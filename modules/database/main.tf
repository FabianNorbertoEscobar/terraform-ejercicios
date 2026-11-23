# RDS requiere subredes de al menos dos zonas de disponibilidad.
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.subnet_ids

  tags = { Name = "${var.name}-db-subnets" }
}

# PostgreSQL privado, pequeño y efímero; no apto para datos de producción.
resource "aws_db_instance" "this" {
  identifier              = "${var.name}-postgres"
  engine                  = "postgres"
  instance_class          = var.instance_class
  allocated_storage       = 20
  storage_type            = "gp3"
  storage_encrypted       = true
  db_name                 = var.db_name
  username                = var.username
  password                = var.password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [var.security_group_id]
  publicly_accessible     = false
  multi_az                = false
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = { Name = "${var.name}-postgres" }
}
