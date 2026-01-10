#!/bin/bash
set -e

# ============================================
# CONFIGURATION
# ============================================
EKS_CLUSTER_NAME="${1:-aymen-eks-cluster}"
REGION="${2:-us-east-1}"
OWNER="${3:-aymen}"

echo "==========================================="
echo "Kubernetes Tools Installation"
echo "EKS Cluster: $EKS_CLUSTER_NAME"
echo "Region: $REGION"
echo "Owner: $OWNER"
echo "==========================================="

# Create log directory
mkdir -p /var/log/k8s-setup
LOG_FILE="/var/log/k8s-setup/k8s-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Installation log: $LOG_FILE"

# ============================================
# 1. VERIFY KUBERNETES ACCESS
# ============================================
echo "=== 1. Verifying Kubernetes access ==="

# Configure kubectl for EKS
if ! aws eks describe-cluster --name "$EKS_CLUSTER_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "❌ ERROR: EKS cluster '$EKS_CLUSTER_NAME' not found or not accessible"
    echo "Please create the cluster first via AWS Console or verify the name"
    exit 1
fi

echo "Configuring kubectl for EKS cluster: $EKS_CLUSTER_NAME"
aws eks update-kubeconfig --name "$EKS_CLUSTER_NAME" --region "$REGION"

# Verify kubectl access
if ! kubectl get nodes >/dev/null 2>&1; then
    echo "❌ ERROR: Cannot access Kubernetes cluster"
    echo "Check cluster status and IAM permissions"
    exit 1
fi

echo "✅ Kubernetes cluster accessible"
echo "Nodes:"
kubectl get nodes

# ============================================
# 2. CREATE NAMESPACES
# ============================================
echo "=== 2. Creating namespaces ==="

NAMESPACES=("argocd" "monitoring" "cert-manager" "ingress-nginx" "ebs-csi")

for ns in "${NAMESPACES[@]}"; do
    if ! kubectl get namespace "$ns" >/dev/null 2>&1; then
        kubectl create namespace "$ns"
        echo "✅ Created namespace: $ns"
        
        # Add labels
        kubectl label namespace "$ns" \
            owner="$OWNER" \
            environment=dev \
            managed-by=script \
            project=ecommerce-microservices
    else
        echo "ℹ️  Namespace already exists: $ns"
    fi
done

# ============================================
# 3. INSTALL ARGOCD (GitOps)
# ============================================
echo "=== 3. Installing ArgoCD ==="

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD pods
echo "Waiting for ArgoCD pods to be ready..."
sleep 30
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "NOT_AVAILABLE_YET")

# Create NodePort service for easier access (since LoadBalancer might not work in Learner Lab)
cat <<EOF | kubectl apply -n argocd -f -
apiVersion: v1
kind: Service
metadata:
  name: argocd-server-nodeport
  labels:
    app.kubernetes.io/name: argocd-server
    app.kubernetes.io/part-of: argocd
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
  selector:
    app.kubernetes.io/name: argocd-server
EOF

echo "✅ ArgoCD installed"
echo "ArgoCD Admin Password: $ARGOCD_PASSWORD"

# ============================================
# 4. INSTALL PROMETHEUS & GRAFANA (Monitoring)
# ============================================
echo "=== 4. Installing Prometheus & Grafana ==="

# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
if ! helm status prometheus -n monitoring >/dev/null 2>&1; then
    helm install prometheus prometheus-community/kube-prometheus-stack \
        -n monitoring \
        --set grafana.adminPassword="admin123" \
        --set grafana.service.type="NodePort" \
        --set grafana.service.nodePort="30090" \
        --set prometheus.service.type="NodePort" \
        --set prometheus.service.nodePort="30091" \
        --set alertmanager.service.type="NodePort" \
        --set alertmanager.service.nodePort="30092" \
        --set prometheus.prometheusSpec.resources.requests.memory="512Mi" \
        --set prometheus.prometheusSpec.resources.requests.cpu="250m"
    
    echo "✅ Prometheus stack installed"
else
    echo "ℹ️  Prometheus stack already installed"
fi

# ============================================
# 5. INSTALL EBS CSI DRIVER (Storage)
# ============================================
echo "=== 5. Installing EBS CSI Driver ==="

# Add Helm repo
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update

# Install EBS CSI Driver
if ! helm status aws-ebs-csi-driver -n kube-system >/dev/null 2>&1; then
    helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
        -n kube-system \
        --set controller.serviceAccount.create=true \
        --set controller.serviceAccount.name=ebs-csi-controller-sa \
        --set enableVolumeScheduling=true \
        --set enableVolumeResizing=true \
        --set enableVolumeSnapshot=true
    
    echo "✅ EBS CSI Driver installed"
else
    echo "ℹ️  EBS CSI Driver already installed"
fi

# ============================================
# 6. INSTALL NGINX INGRESS CONTROLLER
# ============================================
echo "=== 6. Installing Nginx Ingress Controller ==="

# Install using Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

if ! helm status ingress-nginx -n ingress-nginx >/dev/null 2>&1; then
    helm install ingress-nginx ingress-nginx/ingress-nginx \
        -n ingress-nginx \
        --set controller.service.type="NodePort" \
        --set controller.service.nodePorts.http="30080" \
        --set controller.service.nodePorts.https="30443" \
        --set controller.replicaCount=2 \
        --set controller.resources.requests.memory="256Mi" \
        --set controller.resources.requests.cpu="100m"
    
    echo "✅ Nginx Ingress installed"
else
    echo "ℹ️  Nginx Ingress already installed"
fi

# ============================================
# 7. CREATE TEST APPLICATION
# ============================================
echo "=== 7. Creating test application ==="

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: test-app
  labels:
    owner: "$OWNER"
    purpose: testing
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  namespace: test-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: test-app
spec:
  selector:
    app: nginx-test
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: test-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /test
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
EOF

echo "✅ Test application deployed"

# ============================================
# 8. DISPLAY ACCESS INFORMATION
# ============================================
echo "=== 8. Generating access information ==="

# Get cluster information
CLUSTER_ENDPOINT=$(aws eks describe-cluster --name "$EKS_CLUSTER_NAME" --region "$REGION" --query "cluster.endpoint" --output text)
NODE_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}')

cat <<EOF

===========================================
✅ KUBERNETES SETUP COMPLETE!
===========================================

📋 Cluster Information:
-----------------------
Cluster Name: $EKS_CLUSTER_NAME
Region: $REGION
Endpoint: $CLUSTER_ENDPOINT
Owner: $OWNER

🔧 Installed Components:
------------------------
1. ArgoCD (GitOps)
   - URL: Use port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:80
   - Admin Password: $ARGOCD_PASSWORD
   - NodePort: 30080

2. Prometheus & Grafana (Monitoring)
   - Grafana: NodePort 30090 (admin/admin123)
   - Prometheus: NodePort 30091

3. EBS CSI Driver (Storage)
   - For dynamic volume provisioning

4. Nginx Ingress Controller
   - HTTP: NodePort 30080
   - HTTPS: NodePort 30443

5. Test Application
   - Namespace: test-app
   - Ingress path: /test

📊 Cluster Status:
------------------
$(kubectl get nodes)
$(kubectl get all -n argocd)
$(kubectl get all -n monitoring)

🔗 Access URLs (via NodePort):
------------------------------
Assuming one of these node IPs: $NODE_IPS

1. ArgoCD: http://<NODE_IP>:30080
2. Grafana: http://<NODE_IP>:30090
3. Test App: http://<NODE_IP>:30080/test

🛠️ Useful Commands:
-------------------
# Port forwarding (local access):
kubectl port-forward svc/argocd-server -n argocd 8080:80
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80

# Get passwords:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Monitor pods:
watch kubectl get pods -A

# Test storage:
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp2
  resources:
    requests:
      storage: 1Gi
EOF

📝 Logs:
--------
Installation log: $LOG_FILE

===========================================
Setup completed at: $(date)
===========================================
EOF

# Save access information to file
cat > /home/ec2-user/k8s-access-info.md << EOF
# Kubernetes Access Information

## Cluster Details
- **Name**: $EKS_CLUSTER_NAME
- **Region**: $REGION
- **Endpoint**: $CLUSTER_ENDPOINT

## Installed Tools

### ArgoCD
- **Password**: $ARGOCD_PASSWORD
- **Access**: 
  - NodePort: 30080
  - Port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:80

### Grafana
- **URL**: NodePort 30090
- **Credentials**: admin/admin123

### Prometheus
- **URL**: NodePort 30091

## Node IPs
$NODE_IPS

## Commands
\`\`\`bash
# Configure kubectl
aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $REGION

# Check cluster
kubectl get nodes
kubectl get all -A

# Access via port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:80 &
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80 &
\`\`\`
EOF

echo "Access information saved to: /home/ec2-user/k8s-access-info.md"