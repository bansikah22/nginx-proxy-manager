#!/bin/bash

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
- role: worker
- role: worker
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
EOF

# Install Cilium using Helm
helm repo add cilium https://helm.cilium.io/
helm upgrade --install --namespace kube-system --repo https://helm.cilium.io cilium cilium --values cilium-values.yaml

# Check Cilium status
cilium status --wait
cilium connectivity test

# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for NGINX Ingress Controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo "Hubble UI is now accessible at http://hubble.localhost"
echo "You can now deploy your applications using Helm charts and create Ingress resources for them."
echo "To delete the Kind cluster, run: kind delete cluster"