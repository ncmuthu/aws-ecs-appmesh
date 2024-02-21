# VPC creation
resource "aws_vpc" "vpc" {
  cidr_block       = "${var.vpc_cidr}"

  tags = {
    Name = "${var.env}-vpc"
  }
}

# Subnets creation - ECS Service

resource "aws_subnet" "subnet01" {
  vpc_id     = aws_vpc.vpc.id
  availability_zone = "${var.region}a"
  cidr_block = "10.2.1.0/24"

  tags = {
    Name = "${var.env}-subnet-01"
  }
}

resource "aws_subnet" "subnet02" {
  vpc_id     = aws_vpc.vpc.id
  availability_zone = "${var.region}b"
  cidr_block = "10.2.2.0/24"

  tags = {
    Name = "${var.env}-subnet-02"
  }
}

# Subnet creation - NAT Gateway

resource "aws_subnet" "subnet03" {
  vpc_id     = aws_vpc.vpc.id
  availability_zone = "${var.region}a"
  cidr_block = "10.2.3.0/24"

  tags = {
    Name = "nat-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.env}-rt"
  }
}

##
# NAT Gateway
##

# EIP for Nat
resource "aws_eip" "nat" {
  domain   = "vpc"
}

# NAT gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnet03.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

# Route table association
resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table" "nat_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.env}-rt"
  }
}

resource "aws_route_table_association" "subnet01" {
  subnet_id         = aws_subnet.subnet01.id
  route_table_id = aws_route_table.nat_rt.id
}

resource "aws_route_table_association" "subnet02" {
  subnet_id         = aws_subnet.subnet02.id
  route_table_id = aws_route_table.nat_rt.id
}
