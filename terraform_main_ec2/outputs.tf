# ============================================
# BASIC OUTPUTS
# ============================================

output "region" {
  description = "AWS region where resources are deployed"
  value       = var.region
}

output "jumphost_public_ip" {
  description = "Public IP address of the EC2 jumphost"
  value       = aws_instance.ec2.public_ip
}

output "jumphost_public_dns" {
  description = "Public DNS name of the EC2 jumphost"
  value       = aws_instance.ec2.public_dns
}

output "jumphost_instance_id" {
  description = "Instance ID of the EC2 jumphost"
  value       = aws_instance.ec2.id
}

output "jumphost_instance_type" {
  description = "Instance type of the EC2 jumphost"
  value       = aws_instance.ec2.instance_type
}

output "jumphost_availability_zone" {
  description = "Availability zone where the jumphost is deployed"
  value       = aws_instance.ec2.availability_zone
}

# ============================================
# NETWORKING OUTPUTS
# ============================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value = {
    subnet1 = aws_subnet.public-subnet1.id
    subnet2 = aws_subnet.public-subnet2.id
  }
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value = {
    subnet1 = aws_subnet.private-subnet1.id
    subnet2 = aws_subnet.private-subnet2.id
  }
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.security-group.id
}

# ============================================
# ACCESS COMMANDS
# ============================================

output "ssh_command" {
  description = "SSH command to connect to the jumphost"
  value       = "ssh -i ~/.ssh/labsuser.pem ec2-user@${aws_instance.ec2.public_ip}"
}

output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = "http://${aws_instance.ec2.public_ip}:8080"
}

output "sonarqube_url" {
  description = "URL to access SonarQube"
  value       = "http://${aws_instance.ec2.public_ip}:9000"
}

# ============================================
# CONFIGURATION INFORMATION
# ============================================

output "configuration" {
  description = "Configuration details"
  value = {
    owner       = var.owner
    environment = var.environment
    project     = var.project
    region      = var.region
    ami_id      = var.ami_id
    instance_type = var.instance_type
  }
}

output "tags" {
  description = "Tags applied to all resources"
  value       = var.common_tags
}

# ============================================
# COMPREHENSIVE ACCESS GUIDE
# ============================================

output "access_guide" {
  description = "Comprehensive access guide for the jumphost"
  value = <<-EOT
  ============================================
  🚀 JUMPHOST DEPLOYMENT COMPLETE!
  ============================================
  
  📍 Basic Information:
  ---------------------
  Instance Name: ${var.instance_name}
  Public IP: ${aws_instance.ec2.public_ip}
  Instance ID: ${aws_instance.ec2.id}
  Region: ${var.region}
  AZ: ${aws_instance.ec2.availability_zone}
  Type: ${var.instance_type}
  
  🔐 SSH Access:
  --------------
  Command: ssh -i ~/.ssh/labsuser.pem ec2-user@${aws_instance.ec2.public_ip}
  
  Note: Use 'vockey' key pair from Learner Lab
  
  🌐 Web Services:
  ----------------
  1. Jenkins CI/CD: http://${aws_instance.ec2.public_ip}:8080
     - Initial password: Check /var/lib/jenkins/secrets/initialAdminPassword on the instance
  
  2. SonarQube: http://${aws_instance.ec2.public_ip}:9000
  
  3. Docker Registry: Local on port 2375
  
  🛠️ Installed Tools:
  -------------------
  - Jenkins, Docker, Docker Compose
  - Terraform, Ansible, AWS CLI
  - kubectl, Helm, eksctl
  - Java, Maven, Node.js, Python
  - Git, Trivy, Vault
  - MariaDB, PostgreSQL
  
  📊 Network Information:
  -----------------------
  VPC ID: ${aws_vpc.vpc.id}
  Security Group: ${aws_security_group.security-group.id}
  
  Public Subnets:
  - ${aws_subnet.public-subnet1.id} (${aws_subnet.public-subnet1.availability_zone})
  - ${aws_subnet.public-subnet2.id} (${aws_subnet.public-subnet2.availability_zone})
  
  Private Subnets:
  - ${aws_subnet.private-subnet1.id} (${aws_subnet.private-subnet1.availability_zone})
  - ${aws_subnet.private-subnet2.id} (${aws_subnet.private-subnet2.availability_zone})
  
  ⚙️ Configuration:
  -----------------
  Owner: ${var.owner}
  Environment: ${var.environment}
  Project: ${var.project}
  
  🚦 Next Steps:
  --------------
  1. SSH to the instance and verify tools are installed
  2. Access Jenkins and complete setup
  3. Configure kubectl for your EKS cluster
  4. Start building and deploying applications
  
  📝 Troubleshooting:
  -------------------
  - If SSH fails: Ensure you're using the correct key (~/.ssh/labsuser.pem)
  - If Jenkins not accessible: Check security group allows port 8080
  - If tools missing: Check /var/log/cloud-init-output.log
  
  ============================================
  ✅ Deployment completed successfully!
  ============================================
  EOT
}

# ============================================
# TERRAFORM STATE INFORMATION
# ============================================

output "terraform_state_info" {
  description = "Information about Terraform state storage"
  value = <<-EOT
  Terraform state is stored in S3 bucket: aymen-tf-state-bucket
  Key: ec2/terraform.tfstate
  Region: ${var.region}
  
  To view state:
  terraform state list
  terraform show
  
  To import existing resources:
  terraform import aws_instance.ec2 <instance-id>
  EOT
}

# ============================================
# EKS INTEGRATION (if cluster exists)
# ============================================

output "eks_integration_commands" {
  description = "Commands to integrate with EKS cluster"
  value = <<-EOT
  To connect to your EKS cluster:
  
  1. Configure kubectl:
     aws eks update-kubeconfig --name aymen-eks-cluster --region ${var.region}
  
  2. Verify connection:
     kubectl get nodes
  
  3. Deploy Kubernetes tools:
     ./kubernetes.sh aymen-eks-cluster ${var.region} ${var.owner}
  
  4. Access ArgoCD:
     kubectl port-forward svc/argocd-server -n argocd 8080:80
     Then open: http://localhost:8080
  EOT
}

# ============================================
# VERIFICATION COMMANDS
# ============================================

output "verification_commands" {
  description = "Commands to verify the installation"
  value = <<-EOT
  Verification Commands (run on jumphost):
  
  # Check system
  hostname
  whoami
  
  # Check installed tools
  docker --version
  terraform --version
  kubectl version --client
  java -version
  node --version
  
  # Check services
  sudo systemctl status jenkins
  sudo systemctl status docker
  sudo docker ps
  
  # Check Jenkins
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
  
  # Check Kubernetes access
  kubectl get nodes 2>/dev/null || echo "Configure EKS first"
  EOT
}

# ============================================
# QUICK REFERENCE
# ============================================

output "quick_reference" {
  description = "Quick reference for common tasks"
  value = {
    ssh         = "ssh -i ~/.ssh/labsuser.pem ec2-user@${aws_instance.ec2.public_ip}"
    jenkins     = "http://${aws_instance.ec2.public_ip}:8080"
    sonarqube   = "http://${aws_instance.ec2.public_ip}:9000"
    eks_config  = "aws eks update-kubeconfig --name aymen-eks-cluster --region ${var.region}"
    terraform   = "cd ~/environment/Microservices-E-Commerce-eks-project && terraform"
    logs        = "cat /var/log/cloud-init-output.log"
  }
}