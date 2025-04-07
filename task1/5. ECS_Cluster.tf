# ################################################################################################################################################
# #                                                               ECS Cluster                                                                    #
# ################################################################################################################################################

# resource "aws_ecs_cluster" "ecs_cluster" {
#   name = "iac-ecs-cluster"
# }

# ################################################################################################################################################
# #                                   To use EC2 as your ECS compute type, refer to the following code.                                          #
# #                                                               ECS EC2 Role                                                                   #
# ################################################################################################################################################

# resource "aws_iam_role" "ecs_instance_role" {
#   name = "ecsInstanceRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       },
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
#   role       = aws_iam_role.ecs_instance_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
# }

# resource "aws_iam_role_policy_attachment" "ecs_ssm_instance_policy" {
#   role       = aws_iam_role.ecs_instance_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# ################################################################################################################################################
# #                                                         ECS Security Group                                                                   #
# ################################################################################################################################################

# resource "aws_security_group" "ecs_instance_sg" {
#   name        = "ecs-instance-sg"
#   description = "Security group for ECS instances"
#   vpc_id      = module.vpc.vpc_id

#   # 기본 아웃바운드 트래픽 허용
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # ECS 에이전트와의 통신
#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     self        = true
#   }

#   # SSH 접근 (필요시)
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # 실제 운영환경에서는 제한적인 IP만 허용하는 것이 좋습니다.
#   }

#   # HTTP 접근 (필요시)
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # HTTPS 접근 (필요시)
#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "ecs-instance-sg"
#   }
# }

# ################################################################################################################################################
# #                                                        ASG Launch Template                                                                   #
# ################################################################################################################################################

# data "aws_ami" "ecs_ami" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
#   }
# }

# resource "aws_launch_template" "ecs_launch_template" {
#   name_prefix   = "ecs-"
#   image_id      = data.aws_ami.ecs_ami.id
#   instance_type = "t3.small"

#   iam_instance_profile {
#     name = aws_iam_instance_profile.ecs_instance_profile.name
#   }

#   network_interfaces {
#     associate_public_ip_address = false
#     security_groups             = [aws_security_group.ecs_instance_sg.id]
#   }

#   user_data = base64encode(<<EOF
# #!/bin/bash
# echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config
# EOF
#   )
# }

# resource "aws_iam_instance_profile" "ecs_instance_profile" {
#   name = "ecsInstanceProfile"
#   role = aws_iam_role.ecs_instance_role.name
# }

# ################################################################################################################################################
# #                                                          Auto Scaling Group                                                                  #
# ################################################################################################################################################

# resource "aws_autoscaling_group" "ecs_asg" {
#   desired_capacity    = 2
#   max_size            = 10
#   min_size            = 2
#   vpc_zone_identifier = [
#     module.vpc.subnet_ids["priv-subnet-a"],
#     module.vpc.subnet_ids["priv-subnet-b"]
#   ]

#   launch_template {
#     id      = aws_launch_template.ecs_launch_template.id
#     version = "$Latest"
#   }

#   tag {
#     key                 = "Name"
#     value               = "ecs-instance"
#     propagate_at_launch = true
#   }

#   tag {
#     key                 = "AmazonECSCluster"
#     value               = aws_ecs_cluster.ecs_cluster.name
#     propagate_at_launch = true
#   }
# }