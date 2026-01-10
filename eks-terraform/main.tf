provider "aws" {
  region = "us-east-1"
}

# ----------------------------
# Data source for existing EKS cluster
# (You need to create this cluster via AWS Console first)
# ----------------------------
data "aws_eks_cluster" "aymen_eks" {
  name = "aymen-eks-cluster"
}

data "aws_eks_cluster_auth" "aymen_eks_auth" {
  name = "aymen-eks-cluster"
}

# ----------------------------
# Kubernetes provider configuration
# ----------------------------
provider "kubernetes" {
  host                   = data.aws_eks_cluster.aymen_eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.aymen_eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.aymen_eks_auth.token
  
  # Optional: Load kubeconfig file
  config_path = "~/.kube/config"
}

# ----------------------------
# Data source for EKS node groups
# ----------------------------
data "aws_eks_node_group" "nodes" {
  cluster_name    = "aymen-eks-cluster"
  node_group_name = "aymen-eks-nodes"
}

# ----------------------------
# Deploy Kubernetes Namespaces
# ----------------------------
resource "kubernetes_namespace" "ecommerce" {
  metadata {
    name = "ecommerce"
    labels = {
      owner       = "aymen"
      project     = "ecommerce-microservices"
      environment = "dev"
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      owner       = "aymen"
      purpose     = "monitoring"
      environment = "dev"
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      owner       = "aymen"
      purpose     = "gitops"
      environment = "dev"
      managed-by  = "terraform"
    }
  }
}

# ----------------------------
# Deploy Sample Microservices
# ----------------------------
resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.ecommerce.metadata[0].name
    labels = {
      app     = "frontend"
      owner   = "aymen"
      service = "frontend"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }

      spec {
        container {
          image = "nginx:alpine"
          name  = "frontend"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend" {
  metadata {
    name      = "frontend-service"
    namespace = kubernetes_namespace.ecommerce.metadata[0].name
    labels = {
      app   = "frontend"
      owner = "aymen"
    }
  }

  spec {
    selector = {
      app = "frontend"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

# ----------------------------
# ConfigMap for sample configuration
# ----------------------------
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.ecommerce.metadata[0].name
    labels = {
      owner = "aymen"
    }
  }

  data = {
    "app.name"        = "E-Commerce Microservices"
    "app.owner"       = "aymen"
    "app.environment" = "dev"
    "database.host"   = "localhost"
    "database.port"   = "5432"
  }
}

# ----------------------------
# Outputs
# ----------------------------
output "eks_cluster_name" {
  value       = data.aws_eks_cluster.aymen_eks.name
  description = "Name of the EKS cluster"
}

output "eks_cluster_endpoint" {
  value       = data.aws_eks_cluster.aymen_eks.endpoint
  description = "Endpoint URL of the EKS cluster"
}

output "eks_cluster_version" {
  value       = data.aws_eks_cluster.aymen_eks.version
  description = "Kubernetes version of the EKS cluster"
}

output "eks_cluster_status" {
  value       = data.aws_eks_cluster.aymen_eks.status
  description = "Status of the EKS cluster"
}

output "kubeconfig_command" {
  value       = "aws eks update-kubeconfig --name aymen-eks-cluster --region us-east-1"
  description = "Command to configure kubectl for this cluster"
}

output "node_group_status" {
  value       = data.aws_eks_node_group.nodes.status
  description = "Status of the EKS node group"
}

output "namespaces_created" {
  value = [
    kubernetes_namespace.ecommerce.metadata[0].name,
    kubernetes_namespace.monitoring.metadata[0].name,
    kubernetes_namespace.argocd.metadata[0].name
  ]
  description = "Names of created Kubernetes namespaces"
}

output "frontend_service_info" {
  value = {
    name      = kubernetes_service.frontend.metadata[0].name
    namespace = kubernetes_service.frontend.metadata[0].namespace
    cluster_ip = kubernetes_service.frontend.spec[0].cluster_ip
  }
  description = "Information about the frontend service"
}