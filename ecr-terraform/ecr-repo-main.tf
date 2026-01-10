locals {
  services = [
    "email-service",
    "checkout-service",
    "recommendation-service",
    "frontend",
    "payment-service",
    "product-catalog-service",
    "cart-service",
    "load-generator",
    "currency-service",
    "shipping-service",
    "ad-service"
  ]
}

resource "aws_ecr_repository" "microservices" {
  for_each = toset(local.services)

  name = "aymen-${each.value}"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  force_delete = true

  tags = {
    Owner       = "aymen"
    Environment = "dev"
    Project     = "ecommerce-microservices"
    Service     = each.value
  }
}

output "ecr_repository_urls" {
  description = "URLs of all ECR repositories"
  value       = { for service, repo in aws_ecr_repository.microservices : service => repo.repository_url }
}

output "ecr_repository_names" {
  description = "Names of all created ECR repositories"
  value       = [for repo in aws_ecr_repository.microservices : repo.name]
}