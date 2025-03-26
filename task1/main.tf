################################################################################################################################################
#                                                                 VPC                                                                          #
################################################################################################################################################
# Import the VPC module to create a VPC
module "vpc" {
  source     = "./modules/vpc"    # Path to the VPC module
  vpc_name   = "vpc"              # Name of the VPC
  vpc_cidr   = "10.0.0.0/16"      # CIDR block for the VPC
  create_igw = true               # No Internet Gateway for this VPC

  # Subnet definitions for the database VPC
  subnets = {
    "public-subnet-a"   = { name = "public-subnet-a", cidr = "10.0.0.0/24", az = "ap-northeast-2a", public = true }
    "public-subnet-b"   = { name = "public-subnet-b", cidr = "10.0.1.0/24", az = "ap-northeast-2b", public = true }    
    "app-subnet-a"      = { name = "app-subnet-a", cidr = "10.0.2.0/24", az = "ap-northeast-2a", public = false }
    "app-subnet-b"      = { name = "app-subnet-b", cidr = "10.0.3.0/24", az = "ap-northeast-2b", public = false }
    "db-subnet-a"       = { name = "db-subnet-a", cidr = "10.0.4.0/24", az = "ap-northeast-2a", public = false }
    "db-subnet-b"       = { name = "db-subnet-b", cidr = "10.0.5.0/24", az = "ap-northeast-2b", public = false }    
  }

  # NAT Gateway configuration is omitted since there are no public subnets
  nat_gateways = { 
    "app-natgw-a"       = { name = "app-natgw-a", subnet_id = "public-subnet-a" }
    "app-natgw-b"       = { name = "app-natgw-b", subnet_id = "public-subnet-b" } 
    }

  # Route table definitions for internal routing
  route_tables = {
    "public-rt"         = "public-rt"
    "app-rt-a"          = "app-rt-a"
    "app-rt-b"          = "app-rt-b"
    "db-rt-a"           = "db-rt-a"
    "db-rt-b"           = "db-rt-b"    
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
    "db-subnet-a"          = { subnet_key = "db-subnet-a", route_table_key = "db-rt-a" }
    "db-subnet-b"          = { subnet_key = "db-subnet-b", route_table_key = "db-rt-b" }    
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

################################################################################################################################################
#                                                                 EC2                                                                          #
################################################################################################################################################

module "ec2" {
  source = "./modules/EC2"
  bastion_name           = "bastion"
  ami_id                 = "ami-062cddb9d94dcf95d"
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.subnet_ids["public-subnet-a"]
  key_pair_name          = "bastion-key"
  iam_role_name          = "bastion-role"
  vpc_id                 = module.vpc.vpc_id
  user_data              = filebase64("${path.module}/user_data/user_data.sh")
}

################################################################################################################################################
#                                                                 ECR                                                                          #
################################################################################################################################################

resource "aws_ecr_repository" "backend" {
  name                 = "backend"
  image_tag_mutability = "IMMUTABLE" # MUTABLE or IMMUTABLE
    # MUTABLE is Image tags can be overwritten.

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "frontend"
  image_tag_mutability = "IMMUTABLE" # MUTABLE or IMMUTABLE

  image_scanning_configuration {
    scan_on_push = true
  }
}