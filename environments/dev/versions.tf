terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws    = { source = "hashicorp/aws",  version = ">= 5.50" }
    helm   = { source = "hashicorp/helm", version = ">= 2.12" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.30" }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile   # optional
}
