variable "name" {
  description = "Prefix for all VPC resources"
  type        = string
}

variable "cidr" {
  description = "Root CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of AZs to span (e.g. [\"eu-central-1a\", ...])"
  type        = list(string)
  validation {
    condition     = length(var.azs) >= 2
    error_message = "Must specify at least two AZs."
  }
}

variable "cluster_name" {
  description = "EKS cluster name (used only for subnet discovery tags)"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateway(s) for private subnet egress?"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "If true, share one NAT GW across all AZs (cheaper, less HA)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags propagated to all resources"
  type        = map(string)
  default     = {}
}
