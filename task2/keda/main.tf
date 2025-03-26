################################################################################################################################################
#                                                                 VPC                                                                          #
################################################################################################################################################

module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"

    name            = "my-vpc"
    cidr            = "10.0.0.0/16"
    azs             = ["ap-northeast-2a", "ap-northeast-2b"]

    public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
    public_subnet_names = ["my-public-subnet-a" , "my-public-subnet-b"]
    map_public_ip_on_launch = true
    public_subnet_tags = {
      "kubernetes.io/role/elb" = 1
    }

    private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
    private_subnet_names = ["my-private-subnet-a" , "my-private-subnet-b"]
    private_subnet_tags = {
      "kubernetes.io/role/internal-elb" = 1,
      "karpenter.sh/discovery"          = "my-eks-cluster"
    }

    enable_nat_gateway = true
    single_nat_gateway = false
    one_nat_gateway_per_az = true

    enable_dns_hostnames = true
    enable_dns_support   = true
}

################################################################################################################################################
#                                                                 EC2                                                                          #
################################################################################################################################################

data "aws_ami" "amazon_linux_2023" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }
}

module "ec2" {
  source = "./modules/EC2"
  bastion_name           = "bastion"
  ami_id                 = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[0]
  key_pair_name          = "bastion-key"
  iam_role_name          = "BastionAdminRole"
  vpc_id                 = module.vpc.vpc_id
  user_data              = filebase64("${path.module}/user_data/user_data.sh")
}

################################################################################################################################################
#                                                                 EKS                                                                          #
################################################################################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.32"

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  cluster_security_group_additional_rules = {
    hybrid-all = {
      cidr_blocks = [module.vpc.vpc_cidr_block]
      description = "Allow all traffic from remote node/pod network"
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      type        = "ingress"
    }
  }


  enable_cluster_creator_admin_permissions = true

  access_entries = {
  # One access entry with a policy associated
    example = {
      kubernetes_groups = []
      principal_arn     = module.ec2.bastion_role_arn

      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      }
    }
  }

  # Optional
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = [ module.vpc.private_subnets[0], module.vpc.private_subnets[1] ]
  control_plane_subnet_ids = [ module.vpc.public_subnets[0], module.vpc.public_subnets[1], module.vpc.private_subnets[0], module.vpc.private_subnets[1] ]

  eks_managed_node_groups = {
    app-ng = {
      use_name_prefix   = false
      name              = "app-ng"

      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["t3.small"]
      labels          = { app = "nga"}

      desired_size = 2
      min_size     = 2
      max_size     = 10

      iam = {
        with_addon_policies = {
          image_builder = true
          aws_load_balancer_controller = true
          auto_scaler = true
        }
      }
      create_launch_template = true
      launch_template_name   = "app-node-lt"
      launch_template_tags = {
        Name = "app-node"
      }
    }
  }
  tags = {
    "karpenter.sh/discovery" = "my-eks-cluster"
  }
}