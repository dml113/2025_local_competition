################################################################################################################################################
#                                                               ECS Cluster                                                                    #
################################################################################################################################################

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "iac-ecs-cluster"
}

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
# #                                                        ASG Launch Template                                                                  #
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
#   max_size            = 3
#   min_size            = 1
#   vpc_zone_identifier = [
#     module.vpc.subnet_ids["app-subnet-a"],
#     module.vpc.subnet_ids["app-subnet-b"]
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