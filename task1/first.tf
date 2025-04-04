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

################################################################################################################################################
#                                                                 EC2                                                                          #
################################################################################################################################################

module "ec2" {
  source = "./modules/EC2"
  bastion_name           = "bastion"
  ami_id                 = "ami-0a463f27534bdf246"
  instance_type          = "t3.small"
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
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
    # CMK로 암호화 안 할거면 kms_key 부분 주석
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "frontend"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
    # CMK로 암호화 안 할거면 kms_key 부분 주석
  }
}

# KMS 키 리소스 예시
resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR image encryption"
  deletion_window_in_days = 7
}

################################################################################################################################################
#                                                                 DynamoDB                                                                     #
################################################################################################################################################

# 🔐 KMS 키 생성 (Customer Managed Key)
resource "aws_kms_key" "dynamodb_cmk" {
  description             = "CMK for DynamoDB encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# 🎯 alias 붙여서 관리하기 쉽게 (선택 사항)
resource "aws_kms_alias" "dynamodb_alias" {
  name          = "alias/dynamodb-key"
  target_key_id = aws_kms_key.dynamodb_cmk.key_id
}

# 📦 DynamoDB 테이블 생성
resource "aws_dynamodb_table" "example" {
  name           = "my-dynamodb-table"

  # - PAY_PER_REQUEST: 온디맨드 과금 (초당 읽기/쓰기 기준 요금)
  # - PROVISIONED: 읽기/쓰기 처리량을 고정 수치로 설정 (수동 설정 필요, 저렴할 수도 있음)
  billing_mode   = "PAY_PER_REQUEST"

  # 🗝️ hash_key는 파티션 키 (primary key라고 보면 됨)
  # 테이블의 고유한 key로 사용됨
  # 필수임. 없으면 에러남
  hash_key       = "id"

  # 🔑 속성 정의: 위에 선언한 hash_key에 대한 타입 명시
  attribute {
    name = "id"
    type = "S"  # S = String, N = Number, B = Binary
  }

  # 🔐 서버 측 암호화 설정 (CMK 사용)
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_cmk.arn
  }

  tags = {
    Name = "dynamodb-table-with-cmk"
  }
}