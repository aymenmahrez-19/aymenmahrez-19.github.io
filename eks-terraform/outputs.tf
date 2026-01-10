output "cluster_access_instructions" {
  value = <<-EOT
  ===========================================
  EKS Cluster Access Instructions
  ===========================================
  
  1. Configure kubectl:
     aws eks update-kubeconfig --name aymen-eks-cluster --region us-east-1
  
  2. Verify cluster access:
     kubectl get nodes
     kubectl get all -n ecommerce
  
  3. Access the frontend service:
     kubectl port-forward svc/frontend-service -n ecommerce 8080:80
     Then open: http://localhost:8080
  
  4. Check created resources:
     kubectl get namespaces
     kubectl get deployments -n ecommerce
     kubectl get services -n ecommerce
  
  Cluster Info:
  - Name: ${data.aws_eks_cluster.aymen_eks.name}
  - Endpoint: ${data.aws_eks_cluster.aymen_eks.endpoint}
  - Status: ${data.aws_eks_cluster.aymen_eks.status}
  ===========================================
  EOT
}

output "created_resources_summary" {
  value = <<-EOT
  Created Kubernetes Resources:
  
  Namespaces:
  - ecommerce: ${kubernetes_namespace.ecommerce.metadata[0].name}
  - monitoring: ${kubernetes_namespace.monitoring.metadata[0].name}
  - argocd: ${kubernetes_namespace.argocd.metadata[0].name}
  
  Deployments:
  - frontend: ${kubernetes_deployment.frontend.metadata[0].name} (2 replicas)
  
  Services:
  - frontend-service: ${kubernetes_service.frontend.metadata[0].name}
  
  ConfigMaps:
  - app-config: ${kubernetes_config_map.app_config.metadata[0].name}
  EOT
}