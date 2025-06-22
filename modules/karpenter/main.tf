###############################################################################
# Karpenter controller via Helm + IAM role for service account (IRSA)        #
###############################################################################

##################
# IAM -- IRSA role
##################
data "aws_iam_policy_document" "assume_karpenter" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_arn, "arn:aws:iam::", "")}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }
  }
}

resource "aws_iam_role" "karpenter" {
  name               = "${var.cluster_name}-karpenter-controller"
  assume_role_policy = data.aws_iam_policy_document.assume_karpenter.json
  tags               = var.tags
}

locals {
  karpenter_controller_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # ---- minimal policy from AWS docs (v0.37) ----
      { Effect = "Allow",
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "ec2:TerminateInstances",
          "ec2:Describe*",
          "ec2:DeleteLaunchTemplate",
          "ssm:GetParameter"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "karpenter" {
  name   = "karpenter-controller"
  role   = aws_iam_role.karpenter.id
  policy = local.karpenter_controller_policy
}

##################
# Kubernetes bits
##################
resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
  }
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  chart      = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.karpenter.metadata[0].name

  values = [yamlencode({
    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter.arn
      }
    }
    clusterName = var.cluster_name
    clusterEndpoint = var.cluster_endpoint
    logLevel = "info"
  })]

  depends_on = [aws_iam_role_policy.karpenter]
}
