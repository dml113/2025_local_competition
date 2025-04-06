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