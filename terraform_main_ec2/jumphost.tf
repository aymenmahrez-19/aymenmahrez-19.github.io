resource "aws_instance" "jumphost" {
  ami           = var.ami_id
  instance_type = var.instance_type

  key_name               = "vockey"
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.security_group.id]

  # Learner Lab pre-created instance profile
  iam_instance_profile = "LabInstanceProfile"

  # Enforce IMDSv2 (required best practice)
  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true

    tags = {
      Name        = "${var.instance_name}-root"
      Owner       = var.owner
      Environment = var.environment
    }
  }

  user_data = file("${path.module}/install-tools.sh")

  tags = merge(
    {
      Name        = var.instance_name
      Owner       = var.owner
      Environment = var.environment
      Project     = var.project
      Role        = "jumphost-devops"
      ManagedBy   = "terraform"
    },
    var.common_tags
  )
}

# --------------------
# Outputs
# --------------------
output "jumphost_instance_id" {
  description = "ID of the EC2 jumphost instance"
  value       = aws_instance.jumphost.id
}

output "jumphost_public_ip" {
  description = "Public IP address of the EC2 jumphost"
  value       = aws_instance.jumphost.public_ip
}

output "jumphost_public_dns" {
  description = "Public DNS name of the EC2 jumphost"
  value       = aws_instance.jumphost.public_dns
}

output "jumphost_ssh_command" {
  description = "SSH command to connect to the jumphost"
  value       = "ssh -i ~/.ssh/labsuser.pem ec2-user@${aws_instance.jumphost.public_ip}"
}

output "jumphost_access_instructions" {
  description = "Instructions for accessing the jumphost"
  value = <<-EOT
===================================================
Jumphost Access Instructions
===================================================

Instance:
- Name: ${var.instance_name}
- ID: ${aws_instance.jumphost.id}
- Type: ${var.instance_type}
- Public IP: ${aws_instance.jumphost.public_ip}

1. SSH:
   ssh -i ~/.ssh/labsuser.pem ec2-user@${aws_instance.jumphost.public_ip}

2. EC2 Instance Connect:
   AWS Console → EC2 → Instances → Connect

3. Jenkins:
   http://${aws_instance.jumphost.public_ip}:8080

   Initial admin password:
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword

Installed Tools:
- Jenkins
- Docker & Docker Compose
- Terraform
- AWS CLI
- kubectl
- eksctl
- Helm
- Java, Maven, Node.js
- Ansible

===================================================
EOT
}
