########### Providers ############################

provider "aws" {
  region = var.region
}


########### Data and misc ########################

resource "random_string" "env" {
  length  = 4
  special = false
  upper   = false
}

locals {
  name = "${var.name}-${random_string.env.result}"
  tags = merge(
    var.tags,
    {
      "X-Contact"     = var.contact
      "X-Environment" = "kong-mesh-accelerator"
    },
  )
  cluster_1_credentials = {
    "user"     = "admin"
    "password" = "p@55w0rd!"
    "database" = "customers"
  }
}

########### VPC ##################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = "10.99.0.0/18"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnets  = ["10.99.0.0/24", "10.99.1.0/24", "10.99.2.0/24"]
  private_subnets = ["10.99.3.0/24", "10.99.4.0/24", "10.99.5.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames   = true
  enable_dns_support     = true

  tags = local.tags
}

locals {
  vpc_id = module.vpc.vpc_id
}


data "aws_vpc" "this" {
  id = module.vpc.vpc_id
}

data "aws_subnets" "this" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  tags = {
    Name = "*private*"
  }
}


########### Data and misc ########################

data "aws_eks_cluster" "global_cp_cluster" {
  name = module.cluster-1.0.cluster_id
}

data "aws_eks_cluster_auth" "global_cp_cluster" {
  name = module.cluster-1.0.cluster_id
}

########### Global CP Cluster ####################

provider "kubernetes" {
  alias                  = "cluster_1"
  host                   = data.aws_eks_cluster.global_cp_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.global_cp_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.global_cp_cluster.token
}

provider "helm" {
  alias = "cluster_1"
  kubernetes {
    host                   = data.aws_eks_cluster.global_cp_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.global_cp_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.global_cp_cluster.token
  }
}

module "cluster-1" {
  count = var.cluster_1_create ? 1 : 0
  providers = {
    kubernetes = kubernetes.cluster_1
  }
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "18.29.0"
  cluster_name                    = "cluster-1-${local.name}"
  cluster_version                 = var.eks_kubernetes_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  enable_irsa                     = true


  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  eks_managed_node_groups = {
    global_cp = {
      create_launch_template = false
      launch_template_name   = ""
      disk_size              = 50
      instance_types         = [var.eks_instance_size]
      min_size               = var.eks_min_size
      max_size               = var.eks_max_size
      desired_size           = var.eks_desired_size
      tags                   = local.tags
    }
  }
  cluster_tags = local.tags
  tags         = local.tags
}

resource "aws_kms_key" "custom_key" {
  description             = "cluster-1-kms-key"
  deletion_window_in_days = 7
  tags                    = local.tags
}

resource "aws_secretsmanager_secret" "cluster_1_credentials" {
  name                    = "credentials_secret-${local.name}"
  recovery_window_in_days = 0
  tags                    = local.tags
  kms_key_id              = aws_kms_key.custom_key.id
}

resource "aws_secretsmanager_secret_version" "cluster_1_credentials" {
  secret_id     = aws_secretsmanager_secret.cluster_1_credentials.id
  secret_string = jsonencode(local.cluster_1_credentials)
}

module "external-secrets" {
  source = "/home/steveb/terraform_modules/terraform-aws-eks-external-secrets"
  providers = {
    helm       = helm.cluster_1
    kubernetes = kubernetes.cluster_1
  }
  oidc_provider_arn = module.cluster-1.0.oidc_provider_arn
  tags              = local.tags
}

#module "external-dns" {
#  source = "/home/steveb/terraform_modules/terraform-aws-eks-external-dns"
#  providers = {
#    helm       = helm.cluster_1
#    kubernetes = kubernetes.cluster_1
#  }
#  zone_id           = var.zone_id
#  zone_type         = "public"
#  oidc_provider_arn = module.cluster-1.0.oidc_provider_arn
#  region            = var.region
#  vpc_id            = module.vpc.vpc_id
#}

#module "cluster_1_alb" {
#  source = "./modules/alb"
#  providers = {
#    helm       = helm.cluster_1
#    kubernetes = kubernetes.cluster_1
#  }
#  oidc_provider_arn = module.cluster-1.0.oidc_provider_arn
#  region            = var.region
#  vpc_id            = module.vpc.vpc_id
#  cluster_name      = "cluster-1-${local.name}"
#}
