###############################################################################
# providers.tf  (environments/dev/providers.tf)
###############################################################################
# terraform {
#   required_providers {
#     aws        = { source = "hashicorp/aws",  version = "~> 5.50" }
#     kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.28" }
#     helm       = { source = "hashicorp/helm", version = "~> 2.17" }
#   }
# }

terraform {
  required_providers {
    aws        = { source = "hashicorp/aws",        version = "~> 5.50" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.37" }
    helm       = { source = "hashicorp/helm",       version = "~> 2.17" }
    tls        = { source = "hashicorp/tls",        version = "~> 4.1"  }
    time       = { source = "hashicorp/time",       version = "~> 0.13" }
    null       = { source = "hashicorp/null",       version = "~> 3.2"  }
    cloudinit  = { source = "hashicorp/cloudinit",  version = "~> 2.3"  }
  }
}


############################
# 1. AWS – baseline creds  #
############################
provider "aws" {
  region  = var.aws_region           # "us‑east‑1"
  profile = "opsfleet-dev"

  default_tags {
    tags = {
      Org      = "opsfleet"
      Env      = var.environment      # "dev"
      Workload = "platform"
    }
  }
}

############################################
# 2. Data sources that discover the cluster
############################################
data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]           
}

data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

locals {
  cluster_ca_decoded = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
}

data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}

###################################
# 3. Kubernetes and Helm providers
###################################
provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  alias = "eks"

  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

