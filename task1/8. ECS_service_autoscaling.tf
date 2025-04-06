# ################################################################################################################################################
# #                                             ECS Service Auto Scaling - Service 1 (svc1)                                                     #
# ################################################################################################################################################

# resource "aws_appautoscaling_target" "svc1" {
#   max_capacity       = 4
#   min_capacity       = 2
#   resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service_1.name}"
#   scalable_dimension = "ecs:service:DesiredCount"
#   service_namespace  = "ecs"
# }

# resource "aws_appautoscaling_policy" "svc1_cpu_policy" {
#   name               = "svc1-cpu-scaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.svc1.resource_id
#   scalable_dimension = aws_appautoscaling_target.svc1.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.svc1.service_namespace

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageCPUUtilization"
#     }
#     target_value       = 60.0
#     scale_in_cooldown  = 60
#     scale_out_cooldown = 60
#   }
# }

# ################################################################################################################################################
# #                                             ECS Service Auto Scaling - Service 2 (svc2)                                                     #
# ################################################################################################################################################

# resource "aws_appautoscaling_target" "svc2" {
#   max_capacity       = 4
#   min_capacity       = 2
#   resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service_2.name}"
#   scalable_dimension = "ecs:service:DesiredCount"
#   service_namespace  = "ecs"
# }

# resource "aws_appautoscaling_policy" "svc2_cpu_policy" {
#   name               = "svc2-cpu-scaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.svc2.resource_id
#   scalable_dimension = aws_appautoscaling_target.svc2.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.svc2.service_namespace

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageCPUUtilization"
#     }
#     target_value       = 60.0
#     scale_in_cooldown  = 60
#     scale_out_cooldown = 60
#   }
# }