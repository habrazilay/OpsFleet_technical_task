provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Org      = "opsfleet"
      Env      = var.environment
      Workload = "platform"   # or eks / tf / etc.
    }
  }
}
