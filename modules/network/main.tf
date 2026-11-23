# Red aislada con DNS para resolver nombres internos y de RDS.
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.name}-vpc" }
}

# Puerta de enlace de Internet para la subred pública.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name}-igw" }
}

# Subred pública en la primera zona.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 0)
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = { Name = "${var.name}-public" }
}

# Dos subredes privadas permiten crear el grupo de subredes de RDS.
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = var.availability_zones[count.index]

  tags = { Name = "${var.name}-private-${count.index + 1}" }
}

# La ruta predeterminada pública apunta al Internet Gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.name}-public-rt" }
}

# Una asociación hace efectiva la tabla pública en la subred.
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# La tabla privada contiene únicamente la ruta local automática de la VPC.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name}-private-rt" }
}

# Ambas subredes privadas usan la tabla sin salida a Internet.
resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# HTTP es público; SSH solo se permite desde el CIDR de confianza.
resource "aws_security_group" "web" {
  name        = "${var.name}-web"
  description = "HTTP publico y SSH restringido"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH desde red de confianza"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    description = "Salida para paquetes y conexiones"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-web-sg" }
}

# Solo instancias con el grupo web pueden conectarse a PostgreSQL.
resource "aws_security_group" "database" {
  name        = "${var.name}-db"
  description = "PostgreSQL solo desde el grupo web"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "PostgreSQL desde EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = { Name = "${var.name}-db-sg" }
}
