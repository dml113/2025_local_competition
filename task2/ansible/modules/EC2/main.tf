resource "tls_private_key" "bastion" {
  algorithm = "RSA"      # RSA 알고리즘 사용
  rsa_bits  = 4096       # 2048비트 키 생성
}

resource "aws_key_pair" "bastion_key" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.bastion.public_key_openssh
}

resource "local_file" "bastion_local" {
  filename        = "bastion_key.pem"
  content         = tls_private_key.bastion.private_key_pem
}

resource "aws_security_group" "Bastion_Instance_SG" {
  name        = "${var.bastion_name}-sg"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.bastion_name}-sg"
  }
}

#
# Create Security_Group_Rule
#
  resource "aws_security_group_rule" "Bastion_Instance_SG_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.Bastion_Instance_SG.id}"
}
  resource "aws_security_group_rule" "Bastion_Instance_SG_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.Bastion_Instance_SG.id}"
}

# IAM Role for Bastion Host
resource "aws_iam_role" "bastion" {
  name = var.iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = var.iam_role_name
  }
}

# IAM Policy for Bastion Host
resource "aws_iam_role_policy" "bastion" {
  name   = "${var.iam_role_name}-policy"
  role   = aws_iam_role.bastion.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}

# Instance Profile for Bastion Host
resource "aws_iam_instance_profile" "bastion" {
  name = var.iam_role_name
  role = aws_iam_role.bastion.name
}

# EC2 Instance for Bastion Host
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.bastion_key.key_name
  subnet_id                   = var.subnet_id
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  vpc_security_group_ids      = [aws_security_group.Bastion_Instance_SG.id]
  associate_public_ip_address = true
  user_data              = var.user_data

  tags = {
    Name = var.bastion_name
  }
}