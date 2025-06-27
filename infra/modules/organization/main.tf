terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    awsorganizations = {
      source  = "aws-ia/organizations"
      version = "~> 2.0"
    }
  }
}

locals {
  accounts = {
    management     = { email = var.org_root_email,  name = "Management" }
    shared_services = { email = var.shared_email,   name = "Shared-Services" }
    dev            = { email = var.dev_email,      name = "Dev" }
    prod           = { email = var.prod_email,     name = "Prod" }
  }
}

module "org" {
  source  = "aws-ia/organizations/aws"
  version = "~> 2.0"

  root_email        = var.org_root_email
  organization_name = "Innovate-Inc"

  accounts = {
    for k, v in local.accounts :
    k => {
      name          = v.name
      email         = v.email
      iam_role_name = "OrganizationAccountAccessRole"
    }
  }

  # Baseline SCPs
  service_control_policies = [
    file("${path.module}/policies/deny-delete-cloudtrail.json"),
    file("${path.module}/policies/deny-leave-org.json"),
  ]
}
