## set up multipass
```bash
multipass launch --name cilium-kind --cpus 4 --memory 4G --disk 20G
```
## Install docker or will use ansible script
```bash
sudo apt update
sudo apt install -y docker.io
sudo usermod -aG docker $USER
newgrp docker
```

# Setting Up Kubernetes with KinD and Cilium

## Overview

Getting started with Kubernetes in a local development environment has never been easier thanks to Kind (Kubernetes in Docker). Kind enables you to quickly spin up a Kubernetes cluster using Docker containers, offering a lightweight and efficient way to experiment with Kubernetes features.

This guide will walk through the steps to set up a local Kubernetes cluster using Kind, install Cilium as CNI, and enable Hubble for enhanced networking and observability. With this setup, you'll have an environment for testing and developing cloud-native applications right on your local machine.

## Technologies Used

### Cilium
Cilium is an open-source networking, security, and observability solution for container-based workloads. It uses eBPF (extended Berkeley Packet Filter) technology to provide advanced networking features, security policies, and visibility into application behavior.

**Key Features:**
- Network policy enforcement
- Load balancing
- Multi-cluster connectivity
- Observability with Hubble

### KinD (Kubernetes in Docker)
KinD is a tool for running local Kubernetes clusters using Docker containers as nodes. It's designed for testing Kubernetes itself, local development, and CI pipelines.

**Key Features:**
- Quick and easy local Kubernetes cluster setup
- Supports multi-node clusters
- Customizable cluster configurations

## Setup Instructions

### Install Required Binaries

1. **Install Kind**
   ```bash
   [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
   chmod +x ./kind
   sudo mv ./kind /usr/local/bin/kind

```
2. **Install cilium**
```bash
 curl -Lo cilium-linux-amd64.tar.gz https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
tar -xzf cilium-linux-amd64.tar.gz
sudo mv cilium /usr/local/bin/
rm cilium-linux-amd64.tar.gz
```

3. **Install Hubble**
```bash
curl -Lo hubble-linux-amd64.tar.gz https://github.com/cilium/hubble/releases/latest/download/hubble-linux-amd64.tar.gz
tar -xvf hubble-linux-amd64.tar.gz
sudo mv hubble /usr/local/bin/
rm hubble-linux-amd64.tar.gz
```

### Create the Kind Cluster
1. ** Create a configuration file `kind-config.yaml`
```yml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
networking:
  disableDefaultCNI: true
  kubeProxyMode: none
```
2. Create the Kind cluster
```bash
kind create cluster --config=kind-config.yaml
```

#### Install Helm
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh
```
### Install Cilium
1. **Create a Values File** `cilium-values.yaml`
```text
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
```
2. **Install Cilium Using Helm**
```bash
helm repo add cilium https://helm.cilium.io/
helm upgrade --install --namespace kube-system --repo https://helm.cilium.io cilium cilium --values cilium-values.yaml
```
### Check the cilium status
```bash
cilium status --wait 
cilium connectivity test 
```

#### Access Hubble Ui 
To find the NodePort assigned to the Hubble ui, run:
```bash
kubectl -n kube-system get svc hubble-ui 
```
**output example**
```text
NAME         TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)           AGE 
hubble-ui    NodePort   10.96.193.233  <none>        80:<node-port>/TCP      5m 
```
**To access Hubble UI, use port forwarding:
```bash
kubectl -n kube-system port-forward svc/hubble-ui <node-port>:80 
```
Then access it at
```bash
http://localhost:<node-port>
```
Delete kind cluster
```bash
kind delete cluster
```

#### Summary
Setting up a local Kubernetes environment with Kind and Cilium lets you explore Kubernetes features in a lightweight and efficient way. By skipping kube-proxy, you leverage Cilium’s advanced networking capabilities, making it an ideal playground for cloud-native applications.
```bash
Summary
Setting up a local Kubernetes environment with Kind and Cilium lets you explore Kubernetes features in a lightweight and efficient way. By skipping kube-proxy, you leverage Cilium’s advanced networking capabilities, making it an ideal playground for cloud-native applications.
```