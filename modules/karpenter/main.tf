###############################################################################
# Karpenter controller – Helm + IRSA                                          #
###############################################################################

############################
# 1. IAM role for service‑account (IRSA)
############################
data "aws_iam_policy_document" "assume_karpenter" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]          # from the EKS module
    }

    condition {
      test     = "StringEquals"
      variable = "${split("oidc-provider/", var.oidc_provider_arn)[1]}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }
  }
}

resource "aws_iam_role" "karpenter" {
  name               = "${var.cluster_name}-karpenter-controller"
  assume_role_policy = data.aws_iam_policy_document.assume_karpenter.json
  tags               = var.tags
}

resource "aws_iam_policy" "karpenter_controller" {
  name        = "${var.cluster_name}-karpenter-controller"
  path        = "/"
  description = "Permissions for Karpenter to manage compute resources"
  policy      = file("${path.module}/policy-karpenter-controller.json")
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  role       = aws_iam_role.karpenter.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}


############################
# 2.  Namespace
############################
resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
  }
}

############################
# 3.  Helm release
############################
locals {
  karpenter_values = yamlencode({
    controller = {
      replicas = 1                            
    }

    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter.arn
      }
    }

    settings = {
      clusterName     = var.cluster_name
      clusterEndpoint = var.cluster_endpoint
    }

    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Exists"
      effect   = "NoSchedule"
    }]
  })
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  chart      = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  version    = var.helm_chart_version   # e.g. "0.37.2"
  namespace  = kubernetes_namespace.karpenter.metadata[0].name

  atomic           = true   # one‑step transaction; auto‑rollback on error
  cleanup_on_fail  = true   # purge the bad revision + lock if rollback fails
  timeout          = 900    # give CRDs/webhooks time
  recreate_pods    = true

  depends_on       = [aws_iam_role_policy_attachment.karpenter_controller_attach]
  values           = [local.karpenter_values]
}
