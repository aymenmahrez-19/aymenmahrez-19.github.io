provider "aws" {
  region = var.region
}

# Bucket 1: For Terraform state (used by ALL modules)
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.terraform_state_bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    {
      Name        = "aymen-terraform-state"
      Owner       = var.owner
      Environment = var.environment
      Project     = var.project
      Purpose     = "terraform-state-storage"
    },
    var.tags
  )
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# Bucket 2: For application data/logs
resource "aws_s3_bucket" "application_data" {
  bucket = var.application_data_bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    {
      Name        = "aymen-application-data"
      Owner       = var.owner
      Environment = var.environment
      Project     = var.project
      Purpose     = "application-data-storage"
    },
    var.tags
  )
}

resource "aws_s3_bucket_versioning" "application_data_versioning" {
  bucket = aws_s3_bucket.application_data.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# Outputs (keep your updated outputs.tf as is)