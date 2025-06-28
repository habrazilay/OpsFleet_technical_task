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
    controller = { replicas = 2 }     #  ← add this line
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

############################
# 4.  Node IAM role + profile
############################
data "aws_iam_policy" "eks_worker" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
data "aws_iam_policy" "cni" {
  arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
data "aws_iam_policy" "ecr_readonly" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role" "karpenter_node" {
  name               = "KarpenterNodeRole-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_nodes.json
  tags               = var.tags
}

data "aws_iam_policy_document" "assume_nodes" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = {
    eks_worker = data.aws_iam_policy.eks_worker.arn
    cni        = data.aws_iam_policy.cni.arn
    ecr        = data.aws_iam_policy.ecr_readonly.arn
  }
  role       = aws_iam_role.karpenter_node.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "karpenter_node" {
  name = aws_iam_role.karpenter_node.name
  role = aws_iam_role.karpenter_node.name
}
