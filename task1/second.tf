# ################################################################################################################################################
# #                                                          Service Security Group                                                              #
# ################################################################################################################################################

# resource "aws_security_group" "ecs_service_sg" {
#   name        = "ecs-service-sg"
#   description = "Security group for ECS service (allow HTTP from ALB)"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description      = "Allow HTTP from ALB"
#     from_port        = 80
#     to_port          = 80
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]  # 필요시 ALB SG로 제한 가능
#   }

#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "ecs-service-sg"
#   }
# }

# ################################################################################################################################################
# #                                                               ECS Cluster                                                                    #
# ################################################################################################################################################

# # define Cluster
# resource "aws_ecs_cluster" "ecs_cluster" {
#   name = "iac-ecs-cluster"
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

# resource "aws_iam_policy_attachment" "ecs_task_dynamodb_attach" {
#   name       = "attach-dynamodb-access"
#   roles      = [aws_iam_role.ecs_task_role.name]
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }

# ################################################################################################################################################
# #                                                          Task Definitons                                                                     #
# ################################################################################################################################################

# # define Task
# data "template_file" "template_container_definitions" {
#   template = "${file("container-definitions.json.tpl")}"
# }

# resource "aws_ecs_task_definition" "ecs_task" {
#   family                   = "iac-ecs-task"
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   task_role_arn            = aws_iam_role.ecs_task_role.arn
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = "512"
#   memory                   = "1024"
#   container_definitions    = "${data.template_file.template_container_definitions.rendered}"
# }

# resource "aws_cloudwatch_log_group" "ecs_log_group" {
#   name              = "/ecs/nginx"
#   retention_in_days = 7
# }

# ################################################################################################################################################
# #                                                             ECS Service                                                                      #
# ################################################################################################################################################

# resource "aws_ecs_service" "ecs_service" {
#   name            = "iac-nginx-svc"
#   cluster         = "${aws_ecs_cluster.ecs_cluster.id}"
#   task_definition = "${aws_ecs_task_definition.ecs_task.arn}"
#   desired_count   = "2"
#   launch_type     = "FARGATE"

#   network_configuration {
#     security_groups  = [aws_security_group.ecs_service_sg.id]
#     subnets          = [module.vpc.subnet_ids["app-subnet-a"], module.vpc.subnet_ids["app-subnet-b"]]
#     assign_public_ip = false
#   }

#   load_balancer {
#     target_group_arn = "${aws_lb_target_group.iac_nginx_alb.id}"
#     container_name   = "nginx-container"
#     container_port   = "80"
#   }

#   depends_on = ["aws_lb_listener.front_end"]
# }

# ################################################################################################################################################
# #                                                          ALB Security Group                                                                  #
# ################################################################################################################################################

# resource "aws_security_group" "web_server_sg" {
#   name        = "alb-sg"
#   description = "Security group for ALB (allow HTTP from internet)"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description      = "Allow HTTP from anywhere"
#     from_port        = 80
#     to_port          = 80
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "alb-sg"
#   }
# }

# ################################################################################################################################################
# #                                                              Target Group                                                                    #
# ################################################################################################################################################

# resource "aws_lb_target_group" "iac_nginx_alb" {
#   name     = "iac-nginx-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = module.vpc.vpc_id
#   target_type = "ip"
# }

# ################################################################################################################################################
# #                                                                 Load Balancer                                                                #
# ################################################################################################################################################

# resource "aws_lb" "test" {
#   name               = "iac-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups = [aws_security_group.web_server_sg.id]
#   subnets            =  [module.vpc.subnet_ids["public-subnet-a"], module.vpc.subnet_ids["public-subnet-b"]]
# }

# resource "aws_lb_listener" "front_end" {
#   load_balancer_arn = aws_lb.test.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.iac_nginx_alb.arn
#   }
# }