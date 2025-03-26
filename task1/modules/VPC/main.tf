resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "this" {
  count = var.create_igw ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_subnet" "this" {
  for_each = var.subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = each.value.public
  tags = {
    Name = each.value.name
  }
}

resource "aws_route_table" "this" {
  for_each = var.route_tables
  vpc_id = aws_vpc.this.id
  tags = {
    Name = each.key
  }
}

# Elastic IP 생성
resource "aws_eip" "this" {
  for_each = var.nat_gateways
  vpc      = true
  tags = {
    Name = each.value.name
  }
}

# NAT Gateway 생성
resource "aws_nat_gateway" "this" {
  for_each       = var.nat_gateways
  subnet_id      = aws_subnet.this[each.value.subnet_id].id
  allocation_id  = aws_eip.this[each.key].id
  tags = {
    Name = each.value.name
  }
}

resource "aws_route" "this" {
  for_each = { for idx, route in var.routes : idx => route }

  route_table_id         = aws_route_table.this[each.value.rt_name].id
  destination_cidr_block = each.value.destination_cidr

  gateway_id = lookup(each.value, "gateway_id", null)
  nat_gateway_id = lookup(each.value, "nat_gateway_key", null) != null ? aws_nat_gateway.this[each.value.nat_gateway_key].id : null
  transit_gateway_id = lookup(each.value, "transit_gateway_id", null)
}

resource "aws_route_table_association" "this" {
  for_each = var.subnet_associations
  subnet_id      = aws_subnet.this[each.value.subnet_key].id
  route_table_id = aws_route_table.this[each.value.route_table_key].id
}

# VPC 엔드포인트 생성
resource "aws_vpc_endpoint" "this" {
  for_each = var.vpc_endpoints

  vpc_id       = aws_vpc.this.id
  service_name = each.value.service_name
  vpc_endpoint_type = lookup(each.value, "type", "Gateway")

  # 인터페이스 엔드포인트일 경우 서브넷 지정
  subnet_ids = lookup(each.value, "subnet_keys", null) != null ? [for key in each.value.subnet_keys : aws_subnet.this[key].id] : null


  # 게이트웨이 엔드포인트일 경우 라우트 테이블 지정
  route_table_ids = lookup(each.value, "route_table_keys", null) != null ? [for key in each.value.route_table_keys : aws_route_table.this[key].id] : null

  tags = {
    Name = each.key
  }
}