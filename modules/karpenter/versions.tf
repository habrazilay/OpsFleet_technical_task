# # terraform {
# #   required_providers {
# #     helm = {
# #       source  = "hashicorp/helm"
# #       version = "~> 2.17"      # already in your lockfile
# #     }
# #   }
# # }

terraform {
  required_providers {
    aws        = { source = "hashicorp/aws" }
    kubernetes = { source = "hashicorp/kubernetes" }
    helm       = { source = "hashicorp/helm" }
  }
}


# # provider "helm" {
# #   kubernetes {
# #     host                   = var.cluster_endpoint
# #     cluster_ca_certificate = base64decode(var.cluster_ca)
# #     token                  = data.aws_eks_cluster_auth.this.token
# #   }
# # }

