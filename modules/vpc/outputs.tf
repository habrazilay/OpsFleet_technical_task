output "id" {
  value       = module.this.vpc_id
  description = "VPC ID"
}

output "private_subnets" {
  value       = module.this.private_subnets
  description = "Private subnet IDs"
}

output "public_subnets" {
  value       = module.this.public_subnets
  description = "Public subnet IDs"
}
