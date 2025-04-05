resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/nginx"
  retention_in_days = 7
}

################################################################################################################################################
#                                                          First Task Definition                                                               #
################################################################################################################################################

data "template_file" "template_first_container_definitions" {
  template = file("first-container-definitions.json.tpl")
}

resource "aws_ecs_task_definition" "ecs_task_1" {
  family                   = "iac-ecs-task1"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  container_definitions    = data.template_file.template_first_container_definitions.rendered
}

################################################################################################################################################
#                                                          Second Task Definition                                                              #
################################################################################################################################################

data "template_file" "template_second_container_definitions" {
  template = file("second-container-definitions.json.tpl")
}

resource "aws_ecs_task_definition" "ecs_task_2" {
  family                   = "iac-ecs-task2"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  container_definitions    = data.template_file.template_second_container_definitions.rendered
}

################################################################################################################################################
#                                  Service Discovery Namespace (skills.local)                                                                 #
################################################################################################################################################

resource "aws_service_discovery_private_dns_namespace" "skills_local" {
  name        = "skills.local"
  description = "Private DNS namespace for ECS service discovery"
  vpc         = module.vpc.vpc_id
}

################################################################################################################################################
#                                      Service Discovery Service (nginx)                                                                       #
################################################################################################################################################

resource "aws_service_discovery_service" "svc1" {
  name = "svc1"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.skills_local.id

    dns_records {
      type = "A"
      ttl  = 10
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "svc2" {
  name = "svc2"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.skills_local.id

    dns_records {
      type = "A"
      ttl  = 10
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

################################################################################################################################################
#                                        ECS Service 1 (Task 1 연결)                                                                          #
################################################################################################################################################

resource "aws_ecs_service" "ecs_service_1" {
  name            = "iac-nginx-svc-1"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_1.arn
  desired_count   = 2
# FARGATE_SPOT을 사용한다면 아래 launch_type 주석처리  
  launch_type     = "FARGATE"

#   capacity_provider_strategy {
#     capacity_provider = "FARGATE_SPOT"
#     weight            = 1
#   }

  network_configuration {
    security_groups  = [aws_security_group.ecs_service_sg.id]
    subnets          = [
      module.vpc.subnet_ids["app-subnet-a"],
      module.vpc.subnet_ids["app-subnet-b"]
    ]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.svc1_tg.arn
    container_name   = "nginx-container"
    container_port   = 80
  }

  service_registries {
    registry_arn = aws_service_discovery_service.svc1.arn
  }

  depends_on = [aws_lb_listener.front_end]
}

################################################################################################################################################
#                                        ECS Service 2 (Task 2 연결)                                                                          #
################################################################################################################################################

resource "aws_ecs_service" "ecs_service_2" {
  name            = "iac-nginx-svc-2"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_2.arn
  desired_count   = 2
# FARGATE_SPOT을 사용한다면 아래 launch_type 주석 처리 (혼합 사용할 때도 주석 처리)
  launch_type     = "FARGATE"

#   capacity_provider_strategy {
#     capacity_provider = "FARGATE_SPOT"
#     weight            = 1
#   }

  network_configuration {
    security_groups  = [aws_security_group.ecs_service_sg.id]
    subnets          = [
      module.vpc.subnet_ids["app-subnet-a"],
      module.vpc.subnet_ids["app-subnet-b"]
    ]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.svc2_tg.arn
    container_name   = "nginx-container"
    container_port   = 80
  }

  service_registries {
    registry_arn = aws_service_discovery_service.svc2.arn
  }

  depends_on = [aws_lb_listener.front_end]
}

################################################################################################################################################
#                                             ECS Service Auto Scaling - Service 1 (svc1)                                                     #
################################################################################################################################################

resource "aws_appautoscaling_target" "svc1" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service_1.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "svc1_cpu_policy" {
  name               = "svc1-cpu-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.svc1.resource_id
  scalable_dimension = aws_appautoscaling_target.svc1.scalable_dimension
  service_namespace  = aws_appautoscaling_target.svc1.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

################################################################################################################################################
#                                             ECS Service Auto Scaling - Service 2 (svc2)                                                     #
################################################################################################################################################

resource "aws_appautoscaling_target" "svc2" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service_2.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "svc2_cpu_policy" {
  name               = "svc2-cpu-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.svc2.resource_id
  scalable_dimension = aws_appautoscaling_target.svc2.scalable_dimension
  service_namespace  = aws_appautoscaling_target.svc2.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

################################################################################################################################################
#                                                          ALB Security Group                                                                  #
################################################################################################################################################

resource "aws_security_group" "web_server_sg" {
  name        = "alb-sg"
  description = "Security group for ALB (allow HTTP from internet)"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

################################################################################################################################################
#                                                              Target Group                                                                    #
################################################################################################################################################

resource "aws_lb_target_group" "svc1_tg" {
  name        = "iac-nginx-svc1-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}

resource "aws_lb_target_group" "svc2_tg" {
  name        = "iac-nginx-svc2-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}

################################################################################################################################################
#                                                                Load Balancer                                                                 #
################################################################################################################################################

resource "aws_lb" "test" {
  name               = "iac-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_server_sg.id]
  subnets            = [
    module.vpc.subnet_ids["public-subnet-a"],
    module.vpc.subnet_ids["public-subnet-b"]
  ]
}

resource "aws_lb_listener_rule" "svc1_rule" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.svc1_tg.arn
  }

  condition {
    path_pattern {
      values = ["/svc1*"]
    }
  }
}

resource "aws_lb_listener_rule" "svc2_rule" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.svc2_tg.arn
  }

  condition {
    path_pattern {
      values = ["/svc2*"]
    }
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.test.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 Not Found"
      status_code  = "404"
    }
  }
}