output "terraform_state_bucket" {
  description = "Name of the S3 bucket for Terraform state storage"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "terraform_state_bucket_region" {
  description = "Region where the Terraform state bucket is located"
  value       = aws_s3_bucket.terraform_state.region
}

output "application_data_bucket" {
  description = "Name of the S3 bucket for application data storage"
  value       = aws_s3_bucket.application_data.bucket
}

output "application_data_bucket_arn" {
  description = "ARN of the application data S3 bucket"
  value       = aws_s3_bucket.application_data.arn
}

output "application_data_bucket_region" {
  description = "Region where the application data bucket is located"
  value       = aws_s3_bucket.application_data.region
}

output "all_buckets" {
  description = "Map of all created S3 buckets with their details"
  value = {
    terraform_state = {
      name   = aws_s3_bucket.terraform_state.bucket
      arn    = aws_s3_bucket.terraform_state.arn
      region = aws_s3_bucket.terraform_state.region
    }
    application_data = {
      name   = aws_s3_bucket.application_data.bucket
      arn    = aws_s3_bucket.application_data.arn
      region = aws_s3_bucket.application_data.region
    }
  }
}

output "bucket_urls" {
  description = "S3 URLs for accessing the buckets"
  value = {
    terraform_state = "s3://${aws_s3_bucket.terraform_state.bucket}"
    application_data = "s3://${aws_s3_bucket.application_data.bucket}"  # FIXED: was aws_s_s3_bucket
  }
}

output "versioning_status" {
  description = "Versioning status of each bucket"
  value = {
    terraform_state = aws_s3_bucket_versioning.terraform_state_versioning.versioning_configuration[0].status
    application_data = aws_s3_bucket_versioning.application_data_versioning.versioning_configuration[0].status
  }
}

output "setup_instructions" {
  description = "Instructions for using the S3 buckets"
  value = <<-EOT
  ✅ S3 Buckets Successfully Created!
  
  ===========================================
  Bucket Information:
  ===========================================
  
  1. Terraform State Bucket:
     Name: ${aws_s3_bucket.terraform_state.bucket}
     ARN: ${aws_s3_bucket.terraform_state.arn}
     URL: s3://${aws_s3_bucket.terraform_state.bucket}
     Versioning: ${aws_s3_bucket_versioning.terraform_state_versioning.versioning_configuration[0].status}
  
  2. Application Data Bucket:
     Name: ${aws_s3_bucket.application_data.bucket}
     ARN: ${aws_s3_bucket.application_data.arn}
     URL: s3://${aws_s3_bucket.application_data.bucket}
     Versioning: ${aws_s3_bucket_versioning.application_data_versioning.versioning_configuration[0].status}
  
  ===========================================
  Next Steps:
  ===========================================
  
  1. All other Terraform modules should use this backend configuration:
     
     backend "s3" {
       bucket = "${aws_s3_bucket.terraform_state.bucket}"
       key    = "module-name/terraform.tfstate"
       region = "us-east-1"
     }
  
  2. Update these files to use the bucket name above:
     - ecr-terraform/backend.tf
     - eks-terraform/backend.tf  
     - terraform_main_ec2/terraform.tf
  
  3. To list all buckets:
     aws s3 ls | grep aymen
     
  4. To see bucket details:
     aws s3api list-buckets --query "Buckets[?contains(Name, 'aymen')]"
  EOT
}