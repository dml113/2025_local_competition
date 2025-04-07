# locals {
#   ecs_task_definitions = {
#     task_1 = {
#       family                   = "iac-ecs-task1"
#       cpu                      = "256"
#       memory                   = "512"
#       network_mode             = "awsvpc"
#       requires_compatibilities = ["EC2"]
#     }

#     task_2 = {
#       family                   = "iac-ecs-task2"
#       cpu                      = "512"
#       memory                   = "1024"
#       network_mode             = "awsvpc"
#       requires_compatibilities = ["EC2"]
#     }
#   }
# }

# ################################################################################################################################################
# #                                                          Task Definitons - Role                                                              #
# ################################################################################################################################################

# resource "aws_iam_role" "ecs_task_execution_role" {
#   name = "ecsTaskExecutionRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "ecs-tasks.amazonaws.com"
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

# resource "aws_iam_role" "ecs_task_role" {
#   name = "ecsTaskAppRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "ecs-tasks.amazonaws.com"
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ecs_task_admin_attach" {
#   role       = aws_iam_role.ecs_task_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }

# ################################################################################################################################################
# #                                                          First Task Definition                                                               #
# ################################################################################################################################################

# data "template_file" "template_first_container_definitions" {
#   template = file("first-container-definitions.json.tpl")
# }

# resource "aws_ecs_task_definition" "ecs_task_1" {
#   family                   = local.ecs_task_definitions.task_1.family
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   task_role_arn            = aws_iam_role.ecs_task_role.arn
#   network_mode             = local.ecs_task_definitions.task_1.network_mode
#   requires_compatibilities = local.ecs_task_definitions.task_1.requires_compatibilities
#   cpu                      = local.ecs_task_definitions.task_1.cpu
#   memory                   = local.ecs_task_definitions.task_1.memory
#   container_definitions    = data.template_file.template_first_container_definitions.rendered
# }

# ################################################################################################################################################
# #                                                          Second Task Definition                                                              #
# ################################################################################################################################################

# data "template_file" "template_second_container_definitions" {
#   template = file("second-container-definitions.json.tpl")
# }

# resource "aws_ecs_task_definition" "ecs_task_2" {
#   family                   = local.ecs_task_definitions.task_2.family
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   task_role_arn            = aws_iam_role.ecs_task_role.arn
#   network_mode             = local.ecs_task_definitions.task_2.network_mode
#   requires_compatibilities = local.ecs_task_definitions.task_2.requires_compatibilities
#   cpu                      = local.ecs_task_definitions.task_2.cpu
#   memory                   = local.ecs_task_definitions.task_2.memory
#   container_definitions    = data.template_file.template_second_container_definitions.rendered
# }