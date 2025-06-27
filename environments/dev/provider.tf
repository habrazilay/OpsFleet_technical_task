provider "aws" {
  region  = var.aws_region         # already us-east-1
  profile = "opsfleet-dev"

  default_tags {
    tags = {
      Org      = "opsfleet"
      Env      = var.environment
      Workload = "platform"   # or eks / tf / etc.
    }
  }
}
