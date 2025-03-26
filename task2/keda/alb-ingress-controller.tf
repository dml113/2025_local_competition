data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

variable "alb_chart" {
  type        = map(string)
  description = "AWS Load Balancer Controller chart"
  default = {
    name       = "aws-load-balancer-controller"
    namespace  = "kube-system"
    repository = "eks"
    chart      = "aws-load-balancer-controller"
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

module "alb_controller_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${module.eks.cluster_name}-${var.alb_chart.name}"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    one = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:${var.alb_chart.name}"]
    }
  }
}

resource "kubernetes_service_account" "alb_controller" {
  metadata {
    name      = var.alb_chart.name
    namespace = var.alb_chart.namespace

    annotations = {
      "eks.amazonaws.com/role-arn" = module.alb_controller_irsa.iam_role_arn
    }
  }
}

resource "null_resource" "helm_repo_update" {
  provisioner "local-exec" {
    command = <<EOT
      helm repo add eks https://aws.github.io/eks-charts || true
      helm repo update
    EOT
  }
}

resource "helm_release" "alb_controller" {
  namespace  = var.alb_chart.namespace
  repository = var.alb_chart.repository
  name       = var.alb_chart.name
  chart      = var.alb_chart.chart

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.alb_controller.metadata.0.name
  }

  depends_on = [
    kubernetes_service_account.alb_controller,
    null_resource.helm_repo_update  # Helm 저장소 업데이트 이후 실행
  ]
}


# resource "kubernetes_deployment" "echo" {
#   metadata {
#     name = "nginx-deploy"
#   }
#   spec {
#     replicas = 2
#     selector {
#       match_labels = {
#         "app.kubernetes.io/name" = "nginx"
#       }
#     }
#     template {
#       metadata {
#         labels = {
#           "app.kubernetes.io/name" = "nginx"
#         }
#       }
#       spec {
#         container {
#           image = "nginx"
#           name  = "nginx"
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service" "nginx" {
#   metadata {
#     name = "nginx-svc"
#   }
#   spec {
#     selector = {
#       "app.kubernetes.io/name" = "nginx"
#     }
#     port {
#       port        = 80
#       target_port = 80
#     }
#     type = "NodePort"
#   }
# }

# resource "kubernetes_ingress_v1" "alb" {
#   metadata {
#     name = "alb"
#     annotations = {
#       "alb.ingress.kubernetes.io/load-balancer-name" = "nginx-alb"
#       "alb.ingress.kubernetes.io/scheme"      = "internet-facing",
#       "alb.ingress.kubernetes.io/target-type" = "instance"
#     }
#   }
#   spec {
#     ingress_class_name = "alb"
#     rule {
#       http {
#         path {
#           backend {
#             service {
#               name = "nginx-svc"
#               port {
#                 number = 80
#               }
#             }
#           }
#           path = "/*"
#         }
#       }
#     }
#   }
# }