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

# minimal controller permissions (same as upstream docs)
resource "aws_iam_role_policy" "karpenter" {
  name   = "karpenter-controller"
  role   = aws_iam_role.karpenter.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "ec2:TerminateInstances",
          "ec2:Describe*",
          "ec2:DeleteLaunchTemplate",
          "ec2:DeleteTags",
          "ec2:ModifyLaunchTemplate",
          "ec2:ModifyInstanceAttribute"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "pricing:GetProducts"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameter"
        ],
        "Resource": "arn:aws:ssm:*:*:parameter/aws/service/*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:PassRole"
        ],
        Resource = "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
      }
    ]
  })
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
    controller = { replicas = 1 }
    settings = {
      clusterName     = var.cluster_name
      clusterEndpoint = var.cluster_endpoint
      # optional – Karpenter will create one iff absent
      # interruptionQueueName = "${var.cluster_name}-karpenter-interrupt"
    }

    # allow scheduling on bootstrap node even if tainted
    tolerations = [
      {
        key      = "CriticalAddonsOnly"
        operator = "Exists"
        effect   = "NoSchedule"
      }
    ]

    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter.arn
      }
    }

    logLevel = "info"
  })
}

resource "helm_release" "karpenter" {
  name             = "karpenter"
  namespace        = kubernetes_namespace.karpenter.metadata[0].name
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.helm_chart_version
  create_namespace = false

  values = [
    yamlencode({
      controller = {
        replicaCount = 2
        affinity     = {}   # empty map removes the defaults
      }
    })
  ]

  depends_on = [aws_iam_role_policy.karpenter]
}
