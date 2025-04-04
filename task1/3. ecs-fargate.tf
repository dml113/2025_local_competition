# ################################################################################################################################################
# #                                                               ECS Cluster                                                                    #
# ################################################################################################################################################

# # define Cluster
# resource "aws_ecs_cluster" "ecs_cluster" {
#   name = "iac-ecs-cluster"
# }

# ################################################################################################################################################
# #                                                          First Task Definitons                                                               #
# ################################################################################################################################################

# # define Task
# data "template_file" "template_first_container_defintions" {
#   template = "${file("first-container-definitions.json.tpl")}"
# }

# resource "aws_ecs_task_definition" "ecs_task" {
#   family                   = "iac-ecs-task1"
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   task_role_arn            = aws_iam_role.ecs_task_role.arn
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["EC2"]
#   cpu                      = "512"
#   memory                   = "1024"
#   container_definitions    = "${data.template_file.template_first_container_defintions.rendered}"
# }

# ################################################################################################################################################
# #                                                          Second Task Definitons                                                              #
# ################################################################################################################################################

# # define Task
# data "template_file" "template_second_container_defintions" {
#   template = "${file("second-container-definitions.json.tpl")}"
# }

# resource "aws_ecs_task_definition" "ecs_task" {
#   family                   = "iac-ecs-task2"
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   task_role_arn            = aws_iam_role.ecs_task_role.arn
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["EC2"]
#   cpu                      = "512"
#   memory                   = "1024"
#   container_definitions    = "${data.template_file.template_second_container_defintions.rendered}"
# }

# ########################################################################################################
# #                                  Service Discovery Namespace (skills.local)                          #
# ########################################################################################################

# resource "aws_service_discovery_private_dns_namespace" "skills_local" {
#   name        = "skills.local"
#   description = "Private DNS namespace for ECS service discovery"
#   vpc         = module.vpc.vpc_id
# }

# ########################################################################################################
# #                                      Service Discovery Service (nginx)                               #
# ########################################################################################################

# resource "aws_service_discovery_service" "nginx" {
#   name = "nginx"

#   dns_config {
#     namespace_id = aws_service_discovery_private_dns_namespace.skills_local.id

#     dns_records {
#       type = "A"
#       ttl  = 10
#     }

#     routing_policy = "MULTIVALUE"
#   }

#   health_check_custom_config {
#     failure_threshold = 1
#   }
# }

# ########################################################################################################
# #                                        ECS Service (with Service Discovery)                          #
# ########################################################################################################

# resource "aws_ecs_service" "ecs_service" {
#   name            = "iac-nginx-svc"
#   cluster         = aws_ecs_cluster.ecs_cluster.id
#   task_definition = aws_ecs_task_definition.ecs_task.arn
#   desired_count   = 2
#   launch_type     = "FARGATE"

#   network_configuration {
#     security_groups  = [aws_security_group.ecs_service_sg.id]
#     subnets          = [
#       module.vpc.subnet_ids["app-subnet-a"],
#       module.vpc.subnet_ids["app-subnet-b"]
#     ]
#     assign_public_ip = false
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.iac_nginx_alb.id
#     container_name   = "nginx-container"
#     container_port   = 80
#   }

#   service_registries {
#     registry_arn = aws_service_discovery_service.nginx.arn
#   }

#   depends_on = [aws_lb_listener.front_end]
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
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
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