#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Install kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

# Install Kind
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install Cilium CLI
curl -Lo cilium-linux-amd64.tar.gz https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
tar -xzf cilium-linux-amd64.tar.gz
sudo mv cilium /usr/local/bin/
rm cilium-linux-amd64.tar.gz

# Install Hubble CLI
curl -Lo hubble-linux-amd64.tar.gz https://github.com/cilium/hubble/releases/latest/download/hubble-linux-amd64.tar.gz
tar -xvf hubble-linux-amd64.tar.gz
sudo mv hubble /usr/local/bin/
rm hubble-linux-amd64.tar.gz

# Create Kind configuration file with port mappings for Ingress
cat << EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
networking:
   disableDefaultCNI: true
   kubeProxyMode: none
EOF

# Create Kind cluster
kind create cluster --config=kind-config.yaml

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh

# Create Cilium values file
cat << EOF > cilium-values.yaml
kubeProxyReplacement: true
k8sServiceHost: kind-control-plane
k8sServicePort: 6443
hostServices:
  enabled: false
externalIPs:
  enabled: true
nodePort:
  enabled: true
hostPort:
  enabled: true
image:
  pullPolicy: IfNotPresent
ipam:
  mode: kubernetes
hubble:
  enabled: true
  relay:
    enabled: true
  ui:
    enabled: true
    ingress:
      enabled: true
      annotations:
        kubernetes.io/ingress.class: nginx
      hosts:
        - hubble.localhost
    service:
      type: ClusterIP
ingressController:
  enabled: true
  default: true
debug:
  enabled: true
tunnel: disabled
autoDirectNodeRoutes: true
EOF

# Install Cilium using Helm
helm repo add cilium https://helm.cilium.io/
helm upgrade --install --namespace kube-system --repo https://helm.cilium.io cilium cilium --values cilium-values.yaml

echo "Waiting for Cilium to be fully operational..."
sleep 120

# Check Cilium status
cilium status --wait

# Enable Hubble explicitly
cilium hubble enable

# Check Cilium and Hubble status
cilium status
cilium hubble status

# Apply a permissive network policy for testing
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/master/examples/minikube/cilium-all-allow.yaml

# Check DNS resolution
kubectl run -it --rm --restart=Never busybox --image=busybox:1.28 -- nslookup kubernetes.default

# Run Cilium connectivity test
cilium connectivity test

# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for NGINX Ingress Controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Verify Ingress controller status
kubectl get pods -n ingress-nginx

# Check Cilium logs
kubectl logs -n kube-system -l k8s-app=cilium

# Port-forward Hubble UI
kubectl port-forward -n kube-system svc/hubble-ui 12000:80 &

echo "Hubble UI is now accessible at http://localhost:12000"
echo "You can now deploy your applications using Helm charts and create Ingress resources for them."
echo "To delete the Kind cluster, run: kind delete cluster"

# Additional helpful commands
echo "To check Cilium status: cilium status"
echo "To check Hubble status: cilium hubble status"
echo "To view Cilium logs: kubectl logs -n kube-system -l k8s-app=cilium"