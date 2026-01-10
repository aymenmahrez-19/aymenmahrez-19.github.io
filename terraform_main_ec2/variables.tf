variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# --------------------
# Networking
# --------------------
variable "vpc_name" {
  description = "VPC Name"
  type        = string
  default     = "aymen-vpc"
}

variable "igw_name" {
  description = "Internet Gateway Name"
  type        = string
  default     = "aymen-igw"
}

variable "subnet_name1" {
  description = "Public Subnet 1 Name"
  type        = string
  default     = "aymen-public-subnet-1"
}

variable "subnet_name2" {
  description = "Public Subnet 2 Name"
  type        = string
  default     = "aymen-public-subnet-2"
}

variable "private_subnet_name1" {
  description = "Private Subnet 1 Name"
  type        = string
  default     = "aymen-private-subnet-1"
}

variable "private_subnet_name2" {
  description = "Private Subnet 2 Name"
  type        = string
  default     = "aymen-private-subnet-2"
}

variable "rt_name" {
  description = "Public Route Table Name"
  type        = string
  default     = "aymen-public-rt"
}

variable "sg_name" {
  description = "Security Group Name"
  type        = string
  default     = "aymen-sg"
}

# --------------------
# Project metadata
# --------------------
variable "owner" {
  description = "Owner name for tagging"
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

# --------------------
# EC2 (Jumphost)
# --------------------
variable "ami_id" {
  description = "AMI ID for the EC2 instance (Amazon Linux 2)"
  type        = string
  default     = "ami-0150ccaf51ab55a51"
}

variable "instance_type" {
  description = "EC2 instance type (Learner Lab compatible)"
  type        = string
  default     = "t2.medium"
}

variable "instance_name" {
  description = "EC2 Instance name"
  type        = string
  default     = "aymen-jumphost"
}

# --------------------
# Tags
# --------------------
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    ManagedBy  = "terraform"
    Repository = "Microservices-E-Commerce-eks-project"
    CostCenter = "learning"
    StudentLab = "aws-learner-lab"
  }
}
