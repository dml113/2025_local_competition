# ################################################################################################################################################
# #                                  Service Discovery Namespace (skills.local)                                                                 #
# ################################################################################################################################################

# resource "aws_service_discovery_private_dns_namespace" "skills_local" {
#   name        = "skills.local"
#   description = "Private DNS namespace for ECS service discovery"
#   vpc         = module.vpc.vpc_id
# }

# ################################################################################################################################################
# #                                      Service Discovery Service (nginx)                                                                       #
# ################################################################################################################################################

# resource "aws_service_discovery_service" "svc1" {
#   name = "svc1"

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

# resource "aws_service_discovery_service" "svc2" {
#   name = "svc2"

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

# ################################################################################################################################################
# #                                                          Service Security Group                                                              #
# ################################################################################################################################################

# resource "aws_security_group" "ecs_service_sg" {
#   name        = "ecs-service-sg"
#   description = "Security group for ECS service (allow HTTP from ALB)"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description      = "Allow HTTP from ALB"
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
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
# #                                        ECS Service 1 (Task 1 연결)                                                                          #
# ################################################################################################################################################

# resource "aws_ecs_service" "ecs_service_1" {
#   name            = "iac-nginx-svc-1"
#   cluster         = aws_ecs_cluster.ecs_cluster.id
#   task_definition = aws_ecs_task_definition.ecs_task_1.arn
#   desired_count   = 2
#   launch_type     = "EC2"

#   network_configuration {
#     security_groups  = [aws_security_group.ecs_service_sg.id]
#     subnets          = [
#       module.vpc.subnet_ids["priv-subnet-a"],
#       module.vpc.subnet_ids["priv-subnet-b"]
#     ]
#     assign_public_ip = false
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.svc1_tg.arn
#     container_name   = "nginx-container"
#     container_port   = 80
#   }

#   service_registries {
#     registry_arn = aws_service_discovery_service.svc1.arn
#   }

#   depends_on = [aws_lb_listener.front_end]
# }

# ################################################################################################################################################
# #                                        ECS Service 2 (Task 2 연결)                                                                          #
# ################################################################################################################################################

# resource "aws_ecs_service" "ecs_service_2" {
#   name            = "iac-nginx-svc-2"
#   cluster         = aws_ecs_cluster.ecs_cluster.id
#   task_definition = aws_ecs_task_definition.ecs_task_2.arn
#   desired_count   = 2
#   launch_type     = "EC2"

#   network_configuration {
#     security_groups  = [aws_security_group.ecs_service_sg.id]
#     subnets          = [
#       module.vpc.subnet_ids["priv-subnet-a"],
#       module.vpc.subnet_ids["priv-subnet-b"]
#     ]
#     assign_public_ip = false
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.svc2_tg.arn
#     container_name   = "nginx-container"
#     container_port   = 80
#   }

#   service_registries {
#     registry_arn = aws_service_discovery_service.svc2.arn
#   }

#   depends_on = [aws_lb_listener.front_end]
# }