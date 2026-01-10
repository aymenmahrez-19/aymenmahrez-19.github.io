variable "terraform_state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  type        = string
  default     = "aymen-tf-state-bucket"
}

variable "application_data_bucket_name" {
  description = "Name of the S3 bucket for application data storage"
  type        = string
  default     = "aymen-app-data-bucket"
}

variable "environment" {
  description = "Environment tag for all resources"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner name for tagging resources"
  type        = string
  default     = "aymen"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "ecommerce-microservices"
}

variable "enable_versioning" {
  description = "Enable versioning on S3 buckets"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {
    ManagedBy   = "terraform"
    Repository  = "Microservices-E-Commerce-eks-project"
    CostCenter  = "learning"
  }
}

variable "force_destroy" {
  description = "Allow bucket to be destroyed even if it contains objects (use with caution)"
  type        = bool
  default     = false
}

variable "region" {
  description = "AWS region for S3 buckets"
  type        = string
  default     = "us-east-1"
}