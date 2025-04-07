variable "project_name" {
  type = string
  default = "my"
}

################################################################################################################################################
#                                                                 VPC                                                                          #
################################################################################################################################################
# Import the VPC module to create a VPC
module "vpc" {
  source     = "./modules/vpc"            # Path to the VPC module
  vpc_name   = "${var.project_name}-vpc"                      # Name of the VPC
  vpc_cidr   = "10.0.0.0/16"              # CIDR block for the VPC
  create_igw = true                       # No Internet Gateway for this VPC

  # Subnet definitions for the database VPC
  subnets = {
    "public-subnet-a"   = { name = "${var.project_name}-pub-subnet-a", cidr = "10.0.0.0/24", az = "ap-northeast-2a", public = true }
    "public-subnet-b"   = { name = "${var.project_name}-pub-subnet-b", cidr = "10.0.1.0/24", az = "ap-northeast-2b", public = true }    
    "app-subnet-a"      = { name = "${var.project_name}-priv-subnet-a", cidr = "10.0.2.0/24", az = "ap-northeast-2a", public = false }
    "app-subnet-b"      = { name = "${var.project_name}-priv-subnet-b", cidr = "10.0.3.0/24", az = "ap-northeast-2b", public = false }
  }

  # NAT Gateway configuration is omitted since there are no public subnets
  nat_gateways = { 
    "app-natgw-a"       = { name = "${var.project_name}-natgw-a", subnet_id = "public-subnet-a" }
    "app-natgw-b"       = { name = "${var.project_name}-natgw-b", subnet_id = "public-subnet-b" } 
    }

  # Route table definitions for internal routing
  route_tables = {
    "public-rt"         = "${var.project_name}-pub-rt"
    "app-rt-a"          = "${var.project_name}-priv-rt-a"
    "app-rt-b"          = "${var.project_name}-priv-rt-b"
  }

  # No additional routes are defined
  routes = [
    { 
      rt_name = "public-rt" 
      destination_cidr = "0.0.0.0/0"
      gateway_id = module.vpc.igw_id 
    },
    { 
      rt_name = "app-rt-a" 
      destination_cidr = "0.0.0.0/0" 
      nat_gateway_key ="app-natgw-a"
    },
    { 
      rt_name = "app-rt-b" 
      destination_cidr = "0.0.0.0/0" 
      nat_gateway_key ="app-natgw-b"
    }
  ]

  # Associate subnets with specific route tables
  subnet_associations = {
    "public-subnet-a"      = { subnet_key = "public-subnet-a", route_table_key = "public-rt" }
    "public-subnet-b"      = { subnet_key = "public-subnet-b", route_table_key = "public-rt" }
    "app-subnet-a"         = { subnet_key = "app-subnet-a", route_table_key = "app-rt-a" }
    "app-subnet-b"         = { subnet_key = "app-subnet-b", route_table_key = "app-rt-b" } 
  }
  
  # VPC endpoints are not created in this example
  # ‼️‼️‼️ 주의사항 ‼️‼️‼️
  # 아래 ENDPOINT는 default Security Group을 사용하므로 Inbound 수정해야 함.

  # vpc_endpoints = {
  #   "s3-endpoint" = { 
  #     service_name     = "com.amazonaws.ap-northeast-2.s3" 
  #     route_table_keys = ["public-rt", "app-rt-a", "app-rt-b"]
  #   }
  #   "dynamodb-endpoint" = { 
  #     service_name     = "com.amazonaws.ap-northeast-2.dynamodb"
  #     route_table_keys = ["public-rt", "app-rt-a", "app-rt-b"]
  #   }
  #   "ec2-endpoint" = {
  #     service_name  = "com.amazonaws.ap-northeast-2.ec2"
  #     type          = "Interface"
  #     subnet_keys   = ["app-subnet-a", "app-subnet-b"]
  #   }
  # }
}