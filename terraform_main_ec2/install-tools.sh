#!/bin/bash
set -e

# ============================================
# CONFIGURATION (passed from Terraform user_data)
# ============================================
OWNER="${owner:-aymen}"
ENVIRONMENT="${environment:-dev}"
PROJECT="${project:-ecommerce-microservices}"
EKS_CLUSTER_NAME="${eks_cluster_name:-aymen-eks-cluster}"

echo "==========================================="
echo "Starting DevOps Tools Installation"
echo "Owner: $OWNER"
echo "Environment: $ENVIRONMENT"
echo "Project: $PROJECT"
echo "EKS Cluster: $EKS_CLUSTER_NAME"
echo "==========================================="

# Create log directory
mkdir -p /var/log/devops-setup
LOG_FILE="/var/log/devops-setup/install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Installation log: $LOG_FILE"

# ============================================
# 1. SYSTEM UPDATE & ESSENTIAL TOOLS
# ============================================
echo "=== 1. Updating system and installing essential tools ==="
sudo yum update -y
sudo yum install -y git wget unzip curl jq yum-utils bash-completion

# ============================================
# 2. PROGRAMMING LANGUAGES & RUNTIMES
# ============================================
echo "=== 2. Installing programming languages ==="

# Java (for Jenkins)
sudo amazon-linux-extras enable corretto8
sudo yum install -y java-1.8.0-amazon-corretto-devel
echo "Java version:"
java -version

# Node.js
curl -sL https://rpm.nodesource.com/setup_16.x | sudo bash -
sudo yum install -y nodejs
echo "Node.js version:"
node --version
echo "npm version:"
npm --version

# Python 3
sudo yum install -y python3 python3-pip
echo "Python version:"
python3 --version

# ============================================
# 3. CI/CD TOOLS
# ============================================
echo "=== 3. Installing CI/CD tools ==="

# Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Save Jenkins initial password
JENKINS_INIT_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "NOT_FOUND")
echo "Jenkins initial admin password: $JENKINS_INIT_PASSWORD" | sudo tee /home/ec2-user/jenkins-password.txt
sudo chmod 600 /home/ec2-user/jenkins-password.txt

# Maven
sudo yum install -y maven
echo "Maven version:"
mvn --version

# ============================================
# 4. INFRASTRUCTURE AS CODE
# ============================================
echo "=== 4. Installing Infrastructure as Code tools ==="

# Terraform
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install -y terraform
echo "Terraform version:"
terraform --version

# Ansible
sudo yum install -y ansible
echo "Ansible version:"
ansible --version

# ============================================
# 5. CONTAINER & ORCHESTRATION
# ============================================
echo "=== 5. Installing container & orchestration tools ==="

# Docker
sudo yum install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
sudo usermod -aG docker jenkins
sudo chmod 666 /var/run/docker.sock
echo "Docker version:"
docker --version

# Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
echo "Docker Compose version:"
docker-compose --version

# Kubernetes tools
echo "Installing Kubernetes tools..."

# kubectl (latest version)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo "kubectl version:"
kubectl version --client --short

# eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin/
echo "eksctl version:"
eksctl version

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
echo "Helm version:"
helm version --short

# ============================================
# 6. AWS TOOLS
# ============================================
echo "=== 6. Installing AWS tools ==="

# AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws
echo "AWS CLI version:"
aws --version

# Configure AWS CLI for Learner Lab (uses instance profile)
mkdir -p /home/ec2-user/.aws
cat > /home/ec2-user/.aws/config << EOF
[default]
region = us-east-1
output = json
EOF

# ============================================
# 7. SECURITY & SCANNING TOOLS
# ============================================
echo "=== 7. Installing security tools ==="

# Trivy
sudo yum install -y https://github.com/aquasecurity/trivy/releases/download/v0.48.3/trivy_0.48.3_Linux-64bit.rpm
echo "Trivy version:"
trivy --version

# ============================================
# 8. DATABASES (for local development)
# ============================================
echo "=== 8. Installing local databases ==="

# MariaDB
sudo yum install -y mariadb105-server
sudo systemctl enable mariadb
sudo systemctl start mariadb
echo "MariaDB version:"
mysql --version

# PostgreSQL
sudo yum install -y postgresql15 postgresql15-server
sudo /usr/pgsql-15/bin/postgresql-15-setup initdb
sudo systemctl enable postgresql-15
sudo systemctl start postgresql-15
echo "PostgreSQL version:"
psql --version

# ============================================
# 9. CONFIGURE KUBERNETES ACCESS
# ============================================
echo "=== 9. Configuring Kubernetes access ==="

# Configure kubectl for EKS
if aws eks describe-cluster --name "$EKS_CLUSTER_NAME" --region us-east-1 >/dev/null 2>&1; then
    echo "Configuring kubectl for EKS cluster: $EKS_CLUSTER_NAME"
    aws eks update-kubeconfig --name "$EKS_CLUSTER_NAME" --region us-east-1
    echo "Kubernetes nodes:"
    kubectl get nodes 2>/dev/null || echo "Cannot connect to cluster yet"
else
    echo "EKS cluster '$EKS_CLUSTER_NAME' not found or not accessible"
    echo "To configure later, run:"
    echo "  aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region us-east-1"
fi

# ============================================
# 10. CREATE USEFUL ALIASES & SETUP
# ============================================
echo "=== 10. Creating aliases and final setup ==="

# Create aliases
cat >> /home/ec2-user/.bashrc << 'EOF'

# DevOps Aliases
alias tf='terraform'
alias k='kubectl'
alias kc='kubectl config get-contexts'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias dk='docker'
alias dkc='docker-compose'
alias awswho='aws sts get-caller-identity'
alias list-buckets='aws s3 ls | grep aymen'

# Environment variables
export EDITOR=vim
export KUBE_EDITOR=vim
export TF_VAR_owner="aymen"
export TF_VAR_environment="dev"

# kubectl autocomplete
source <(kubectl completion bash)
complete -o default -F __start_kubectl k

# terraform autocomplete
complete -C /usr/bin/terraform terraform
EOF

# Source the updated bashrc
source /home/ec2-user/.bashrc

# Create project directory
mkdir -p /home/ec2-user/projects
mkdir -p /home/ec2-user/k8s-manifests

# ============================================
# 11. CREATE README FILE WITH ACCESS INFO
# ============================================
cat > /home/ec2-user/README.md << EOF
# DevOps Jumphost - $OWNER

## Access Information
- **Instance Name**: $OWNER-jumphost
- **Owner**: $OWNER
- **Environment**: $ENVIRONMENT
- **Project**: $PROJECT

## Services & Ports
- **Jenkins**: http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080
- **Jenkins Password**: Check /home/ec2-user/jenkins-password.txt
- **Docker**: Running on port 2375
- **SonarQube**: http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9000

## Installed Tools
- Jenkins, Docker, Docker Compose
- Terraform, Ansible
- kubectl, Helm, eksctl
- AWS CLI, Git, Maven, Node.js
- Java, Python, Trivy
- MariaDB, PostgreSQL

## Kubernetes
- **EKS Cluster**: $EKS_CLUSTER_NAME
- **Configure**: aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region us-east-1
- **Test**: kubectl get nodes

## Useful Commands
\`\`\`bash
# Check services
sudo systemctl status jenkins
sudo systemctl status docker

# Get Jenkins password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Test Docker
docker run hello-world

# Test Kubernetes
kubectl get nodes
\`\`\`

## Logs
- Installation log: $LOG_FILE
- System logs: /var/log/cloud-init-output.log
EOF

# ============================================
# 12. FINALIZATION
# ============================================
echo "=== 12. Finalizing installation ==="

# Get public IP for display
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Display completion message
cat << EOF

===========================================
✅ INSTALLATION COMPLETE!
===========================================

📋 Summary:
------------
Owner: $OWNER
Environment: $ENVIRONMENT
Project: $PROJECT
Public IP: $PUBLIC_IP

🔧 Installed Tools:
-------------------
- Jenkins CI/CD
- Docker & Docker Compose  
- Terraform, Ansible
- kubectl, Helm, eksctl
- AWS CLI, Git, Maven
- Java, Node.js, Python
- Security: Trivy
- Databases: MariaDB, PostgreSQL

🌐 Access URLs:
---------------
Jenkins: http://$PUBLIC_IP:8080
SonarQube: http://$PUBLIC_IP:9000

🔐 Credentials:
---------------
Jenkins password: $JENKINS_INIT_PASSWORD
(save in /home/ec2-user/jenkins-password.txt)

📝 Next Steps:
--------------
1. Access Jenkins: http://$PUBLIC_IP:8080
2. Complete Jenkins setup with the password above
3. Configure EKS: aws eks update-kubeconfig --name $EKS_CLUSTER_NAME
4. Start building and deploying!

📊 Logs:
--------
- Installation: $LOG_FILE
- Cloud-init: /var/log/cloud-init-output.log

===========================================
Installation completed at: $(date)
===========================================
EOF

# Create a completion flag
touch /home/ec2-user/.devops-tools-installed
echo "Installation completed successfully!"