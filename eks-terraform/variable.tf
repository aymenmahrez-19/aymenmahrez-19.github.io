variable "cluster_name" {
  description = "Name of the existing EKS cluster (created via Console)"
  type        = string
  default     = "aymen-eks-cluster"
}

variable "node_group_name" {
  description = "Name of the existing EKS node group"
  type        = string
  default     = "aymen-eks-nodes"
}

variable "owner" {
  description = "Owner name for tagging resources"
  type        = string
  default     = "aymen"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "ecommerce-microservices"
}