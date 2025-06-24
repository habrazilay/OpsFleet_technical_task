#######################################
# modules/vpc/outputs.tf
#######################################

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.this.vpc_id
}

output "private_subnets" {
  value = module.this.private_subnets
}

output "public_subnets" {
  value = module.this.public_subnets
}
