variable "environment" {
  description = "Deployment stage (dev | staging | prod). Used only for tagging and names."
  type        = string
  default     = "dev"
}

############################
# Global project settings  #
############################
variable "project" {
  description = "Canonical short name used as prefix for nearly all AWS resources."
  type        = string
  default     = "innovate"     # ← change to taste
}

variable "aws_region" {
  description = "AWS region in which all resources will live."
  type        = string
  default     = "eu-central-1" # ← update if needed
}

variable "aws_profile" {
  description = "Local AWS CLI profile (optional). Leave empty to rely on environment variables."
  type        = string
  default     = ""
}

############################
# Networking               #
############################
variable "vpc_cidr" {
  description = "CIDR block for the new VPC."
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "Must be a valid IPv4 CIDR."
  }
}

variable "az_count" {
  description = "How many AZs to span (min 2, max 3 recommended)."
  type        = number
  default     = 3
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "single_nat_gateway" {
  description = "Use one shared NAT Gateway (true) or one per AZ (false)"
  type        = bool
  default     = true   # cheaper for dev
}

############################
# EKS                      #
############################
variable "cluster_version" {
  description = <<EOF
(Optional) Desired EKS control-plane version. Leave null for the latest GA
version supported by terraform-aws-modules/eks.
EOF
  type    = string
  default = null
}

############################
# Karpenter                #
############################
variable "karpenter_chart_version" {
  description = "Helm chart version to install."
  type        = string
  default     = "0.40.0"       # ≥0.40 advertises compatibility with 1.32
}

############################
# Remote state backend     #
############################
# variable "tf_state_bucket" {
#   description = "S3 bucket where Terraform state is stored."
#   type        = string
# }

# variable "tf_state_dynamodb_table" {
#   description = "DynamoDB table for state locking."
#   type        = string
# }
