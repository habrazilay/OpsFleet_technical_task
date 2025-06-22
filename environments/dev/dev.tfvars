# ── Global ────────────────
project         = "innovate"
environment     = "dev"

aws_region      = "us-central-1"
aws_profile     = "default"

# ── Networking ────────────
vpc_cidr        = "10.0.0.0/16"
az_count        = 3
single_nat_gateway = true   # save $ while experimenting

# ── EKS ───────────────────
cluster_version = null      # latest GA

# ── Karpenter ─────────────
karpenter_chart_version = "0.37.0"
