# ################################################################################################################################################
# #                                                                 DynamoDB                                                                     #
# ################################################################################################################################################

# # 🔐 KMS 키 생성 (Customer Managed Key)
# resource "aws_kms_key" "dynamodb_cmk" {
#   description             = "CMK for DynamoDB encryption"
#   deletion_window_in_days = 7
#   enable_key_rotation     = true
# }

# # 🎯 alias 붙여서 관리하기 쉽게 (선택 사항)
# resource "aws_kms_alias" "dynamodb_alias" {
#   name          = "alias/dynamodb-key"
#   target_key_id = aws_kms_key.dynamodb_cmk.key_id
# }

# # 📦 DynamoDB 테이블 생성
# resource "aws_dynamodb_table" "example" {
#   name           = "my-dynamodb-table"

#   # - PAY_PER_REQUEST: 온디맨드 과금 (초당 읽기/쓰기 기준 요금)
#   # - PROVISIONED: 읽기/쓰기 처리량을 고정 수치로 설정 (수동 설정 필요, 저렴할 수도 있음)
#   billing_mode   = "PAY_PER_REQUEST"

#   # 🗝️ hash_key는 파티션 키 (primary key라고 보면 됨)
#   # 테이블의 고유한 key로 사용됨
#   # 필수임. 없으면 에러남
#   hash_key       = "id"

#   # 🔑 속성 정의: 위에 선언한 hash_key에 대한 타입 명시
#   attribute {
#     name = "id"
#     type = "S"  # S = String, N = Number, B = Binary
#   }

#   # 🔐 서버 측 암호화 설정 (CMK 사용)
#   server_side_encryption {
#     enabled     = true
#     kms_key_arn = aws_kms_key.dynamodb_cmk.arn
#   }

#   tags = {
#     Name = "dynamodb-table-with-cmk"
#   }
# }