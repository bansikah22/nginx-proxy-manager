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

# Create Kind configuration file
cat << EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
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
      enabled: false
    service:
      type: NodePort
EOF

# Install Cilium using Helm
helm repo add cilium https://helm.cilium.io/
helm upgrade --install --namespace kube-system --repo https://helm.cilium.io cilium cilium --values cilium-values.yaml

# Check Cilium status
cilium status --wait
cilium connectivity test

# Access Hubble UI
echo "To find the NodePort assigned to the Hubble UI, run:"
echo "kubectl -n kube-system get svc hubble-ui"
echo "To access the Hubble UI, use port forwarding:"
echo "kubectl -n kube-system port-forward svc/hubble-ui <node-port>:80"
echo "Then access http://localhost:<node-port> in your browser"

echo "To delete the Kind cluster, run:"
echo "kind delete cluster"