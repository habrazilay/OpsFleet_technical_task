terraform {
  backend "s3" {
    bucket         = "${var.tf_state_bucket}"
    key            = "eks-karpenter/${var.project}/terraform.tfstate"
    region         = "${var.aws_region}"
    dynamodb_table = "${var.tf_state_dynamodb_table}"
    encrypt        = true
  }
}
