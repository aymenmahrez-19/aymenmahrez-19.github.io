terraform {
  required_version = ">= 1.6.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.25.0"
    }
  }

  backend "s3" {
    bucket = "aymen-tf-state-bucket"
    key    = "ecr/terraform.tfstate"
    region = "us-east-1"
  }
}