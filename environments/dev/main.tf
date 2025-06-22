#environments/dev/main.tf
 
 data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  org     = "opsfleet"
  env     = var.environment
  region  = var.aws_region

  # Workload bases
  eks_base     = "${local.org}-eks-${local.env}-${local.region}"
  tfstate_base = "${local.org}-tfstate-${local.env}-${local.region}"

  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}


module "vpc" {
  source = "../../modules/vpc"

  name         = "${local.eks_base}-vpc"     # <— was "${var.project}-vpc"
  cidr         = var.vpc_cidr
  azs          = local.azs
  cluster_name = local.eks_base              # <— was "${var.project}-eks"

  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway

  tags = {
    Org  = local.org
    Env  = local.env
    Workload = "eks"
  }
}



module "eks" {
  source = "../../modules/eks"

  cluster_name    = local.eks_base           # <— was "${var.project}-eks"
  cluster_version = var.cluster_version

  vpc_id          = module.vpc.id
  private_subnets = module.vpc.private_subnets

  tags = {
    Org  = local.org
    Env  = local.env
    Workload = "eks"
  }
}

module "karpenter" {
  source = "../../modules/karpenter"

  cluster_name       = module.eks.cluster_name
  cluster_endpoint   = module.eks.cluster_endpoint
  oidc_provider_arn  = module.eks.oidc_provider_arn
  private_subnet_ids = module.vpc.private_subnets
  helm_chart_version = var.karpenter_chart_version

  tags = {
    Org  = local.org
    Env  = local.env
    Workload = "eks"
  }
}
