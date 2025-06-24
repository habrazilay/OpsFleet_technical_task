terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"

      # Tell the module it can receive an aliased config called kubernetes.eks
      configuration_aliases = [ kubernetes.eks ]
    }

    helm = {
      source = "hashicorp/helm"

      # Accept the alias helm.eks that the root module passes in
      configuration_aliases = [ helm.eks ]
    }
  }
}
