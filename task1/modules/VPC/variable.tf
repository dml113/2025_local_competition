variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "create_igw" {
  description = "Whether to create an Internet Gateway"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "Subnet definitions"
  type = map(object({
    name   = string
    cidr   = string
    az     = string
    public = bool
  }))
}

variable "nat_gateways" {
  description = "NAT Gateway definitions"
  type = map(object({
    name      = string
    subnet_id = string
  }))
  default = {}
}

variable "route_tables" {
  description = "Route Table definitions"
  type        = map(string)
}

variable "routes" {
  description = "Route definitions"
  type = list(object({
    rt_name           = string
    destination_cidr  = string
    gateway_id        = optional(string)
    nat_gateway_key   = optional(string)
    transit_gateway_id = optional(string)
  }))
  default = []
}

variable "subnet_associations" {
  description = "Associations between subnets and route tables"
  type = map(object({
    subnet_key      = string
    route_table_key = string
  }))
}

variable "vpc_endpoints" {
  description = "VPC Endpoint Setting"
  type = map(object({
    service_name    = string
    type            = optional(string)  # 기본값: 게이트웨이
    subnet_keys     = optional(list(string))       # 인터페이스 엔드포인트용 서브넷 목록
    route_table_keys = optional(list(string))      # 게이트웨이 엔드포인트용 라우트 테이블 목록
  }))
  default = {}
}