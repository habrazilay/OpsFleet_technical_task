locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

module "vpc" {
  source = "../../modules/vpc"

  name         = "${var.project}-vpc"
  cidr         = var.vpc_cidr
  azs          = local.azs
  cluster_name = "${var.project}-eks"

  enable_nat_gateway = true            # or var.enable_nat_gateway if you expose it
  single_nat_gateway = false           # flip to true to save $

  tags = {
    Project = var.project
    Env     = "dev"
  }
}


module "eks" {
  source = "../../modules/eks"

  cluster_name     = "${var.project}-eks"
  cluster_version  = var.cluster_version

  vpc_id           = module.vpc.id
  private_subnets  = module.vpc.private_subnets

  tags = {
    Project = var.project
    Env     = "dev"
  }
}


# module "karpenter" {
#   source = "../../modules/karpenter"

#   cluster_name        = module.eks.cluster_name
#   cluster_endpoint    = module.eks.cluster_endpoint
#   oidc_provider_arn   = module.eks.oidc_provider_arn
#   private_subnet_ids  = module.vpc.private_subnets
#   helm_chart_version  = var.karpenter_chart_version

#   tags = {
#     "Project" = var.project
#   }
# }
