provider "aws" {
  region = "ap-northeast-2"
}

# ========== LOCALS ==========
locals {
  vpc = {
    name = "onprem-vpc"
    cidr = "10.0.0.0/16"
  }

  availability_zones = ["ap-northeast-2a", "ap-northeast-2b"]

  public_subnets = {
    pub-a = {
      name = "onprem-pub-sn-a"
      cidr = "10.0.1.0/24"
      az   = "ap-northeast-2a"
    }
    pub-b = {
      name = "onprem-pub-sn-b"
      cidr = "10.0.2.0/24"
      az   = "ap-northeast-2b"
    }
  }

  igw_name     = "onprem-igw"
}

# ========== VPC & IGW ==========
resource "aws_vpc" "main" {
  cidr_block           = local.vpc.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = local.vpc.name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = local.igw_name
  }
}

# ========== PUBLIC SUBNETS ==========
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = each.value.name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = local.route_tables.public
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}