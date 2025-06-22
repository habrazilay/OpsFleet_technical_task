variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "EKS control-plane version (null = latest GA)"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "ID of the VPC that hosts the cluster"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs where worker nodes live"
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
