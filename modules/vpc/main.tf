###############################################################################
# Opinionated wrapper around terraform-aws-modules/vpc                        #
###############################################################################

module "this" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"  # latest tested as of 2025-06

  name = var.name
  cidr = var.cidr
  azs  = var.azs

  # ── Subnet layout ──────────────────────────────────────────────────────────
  public_subnets  = [for i in range(length(var.azs)) : cidrsubnet(var.cidr, 8, i)]
  private_subnets = [for i in range(length(var.azs)) : cidrsubnet(var.cidr, 8, i + length(var.azs))]

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  enable_dns_support   = true
  enable_dns_hostnames = true

  # ── Tags for ALB & Karpenter subnet discovery ─────────────────────────────

tags = merge(var.tags, {
  "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  "kubernetes.io/role/internal-elb"           = "1"
  "karpenter.sh/discovery/${var.cluster_name}" = "owned"
})

}

