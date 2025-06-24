###############################################################################
# Opinionated wrapper around terraform-aws-modules/eks v20.x                  #
# * Latest GA version by default (leave cluster_version = null)               #
# * IRSA enabled so add-ons (Karpenter, ALB Controller, etc.) get fine-grained#
#   IAM roles                                                                 #
# * Tiny ON_DEMAND node group (“core”) so Karpenter has somewhere to run      #
###############################################################################
module "this" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.10"             # 2025-06 latest

  cluster_name               = var.cluster_name
  cluster_version            = var.cluster_version
  cluster_endpoint_public_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets          # private only; public for LB-ingress

  enable_irsa = true

  ########################################
  # Minimal managed node group (bootstrap)
  ########################################
  eks_managed_node_groups = {
    core = {
      desired_size = 1
      min_size     = 1
      max_size     = 2
      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = ["t4g.small"]        # cheap Arm, steady on-demand
      capacity_type  = "ON_DEMAND"

      labels = {
        "node-role.kubernetes.io/core" = "true"
      }

      # Taint so only system / Karpenter pods land here
      taints = [
        {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }

  ########################################
  # Core addons (Amazon-managed default) #
  ########################################
  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  tags = var.tags
}
