# ---- Global ----
environment = "dev"
aws_region  = "us-east-1"

# ---- Networking ----
vpc_cidr           = "10.0.0.0/16"
az_count           = 3
single_nat_gateway = true   # cheaper during PoC

# ---- EKS / Karpenter ----
cluster_version         = null   # latest GA
karpenter_chart_version = "0.37.0"
