# Helm provider configuration
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.aymen_eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.aymen_eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.aymen_eks_auth.token
  }
}

# Install ArgoCD using Helm (optional)
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.46.8"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# Install Prometheus Stack (optional)
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "48.3.2"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "grafana.adminPassword"
    value = "admin123"
  }

  set {
    name  = "grafana.service.type"
    value = "ClusterIP"
  }

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}