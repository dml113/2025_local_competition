provider "aws" {
  region = "ap-northeast-2"
}

# ========== LOCALS ==========
locals {
  vpc = {
    name = "app-vpc"
    cidr = "172.16.0.0/16"
  }

  availability_zones = ["ap-northeast-2a", "ap-northeast-2b"]

  public_subnets = {
    pub-a = {
      name = "app-pub-sn-a"
      cidr = "172.16.1.0/24"
      az   = "ap-northeast-2a"
    }
    pub-b = {
      name = "app-pub-sn-b"
      cidr = "172.16.2.0/24"
      az   = "ap-northeast-2b"
    }
  }

  private_subnets = {
    priv-a = {
      name = "app-priv-sn-a"
      cidr = "172.16.11.0/24"
      az   = "ap-northeast-2a"
    }
    priv-b = {
      name = "app-priv-sn-b"
      cidr = "172.16.12.0/24"
      az   = "ap-northeast-2b"
    }
  }

  igw_name     = "app-igw"
  natgw_names  = { priv-a = "app-natgw-a", priv-b = "app-natgw-b" }
  route_tables = {
    public      = "app-pub-rt"
    priv-a      = "app-priv-rt-a"
    priv-b      = "app-priv-rt-b"
  }
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

# ========== PRIVATE SUBNETS ==========
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = each.value.name
  }
}

resource "aws_eip" "nat" {
  for_each = local.private_subnets
  vpc      = true

  tags = {
    Name = "${local.natgw_names[each.key]}-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  for_each       = local.private_subnets
  allocation_id  = aws_eip.nat[each.key].id
  subnet_id      = aws_subnet.public[replace(each.key, "priv", "pub")].id
  depends_on     = [aws_internet_gateway.igw]

  tags = {
    Name = local.natgw_names[each.key]
  }
}

resource "aws_route_table" "private" {
  for_each = local.private_subnets

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }

  tags = {
    Name = local.route_tables[each.key]
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
