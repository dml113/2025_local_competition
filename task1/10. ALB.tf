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

# ################################################################################################################################################
# #                                                              Target Group                                                                    #
# ################################################################################################################################################

# resource "aws_lb_target_group" "svc1_tg" {
#   name        = "iac-nginx-svc1-tg"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = module.vpc.vpc_id
#   target_type = "ip"
# }

# resource "aws_lb_target_group" "svc2_tg" {
#   name        = "iac-nginx-svc2-tg"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = module.vpc.vpc_id
#   target_type = "ip"
# }

# ################################################################################################################################################
# #                                                                Load Balancer                                                                 #
# ################################################################################################################################################

# resource "aws_lb" "test" {
#   name               = "iac-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.web_server_sg.id]
#   subnets            = [
#     module.vpc.subnet_ids["public-subnet-a"],
#     module.vpc.subnet_ids["public-subnet-b"]
#   ]
# }

# resource "aws_lb_listener_rule" "svc1_rule" {
#   listener_arn = aws_lb_listener.front_end.arn
#   priority     = 10

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.svc1_tg.arn
#   }

#   condition {
#     path_pattern {
#       values = ["/svc1*"]
#     }
#   }
# }

# resource "aws_lb_listener_rule" "svc2_rule" {
#   listener_arn = aws_lb_listener.front_end.arn
#   priority     = 20

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.svc2_tg.arn
#   }

#   condition {
#     path_pattern {
#       values = ["/svc2*"]
#     }
#   }
# }

# resource "aws_lb_listener" "front_end" {
#   load_balancer_arn = aws_lb.test.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "fixed-response"
#     fixed_response {
#       content_type = "text/plain"
#       message_body = "404 Not Found"
#       status_code  = "404"
#     }
#   }
# }