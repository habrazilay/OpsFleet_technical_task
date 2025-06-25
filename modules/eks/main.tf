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
      ami_type       = "AL2_ARM_64"       # ← back to Amazon Linux 2
      instance_types = ["t4g.medium"]     # 2 vCPU / 4 GiB ‑ keeps the CNI happy
      capacity_type  = "ON_DEMAND"
      desired_size   = 1
      min_size       = 1
      max_size       = 2
      iam_role_additional_policies = {
        ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
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

  ########################################################################
  # Use CONFIG_MAP only → the module will render aws‑auth
  ########################################################################
  authentication_mode = "API_AND_CONFIG_MAP"
access_entries = {
  tf_admin = {
    principal_arn     = "arn:aws:iam::851725384896:user/daniel_schmidt"
    kubernetes_groups = ["eks-admins"]
    access_policy_associations = {
      cluster_admin = {
        policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = { type = "cluster" }
      }
    }
  }
}

}




