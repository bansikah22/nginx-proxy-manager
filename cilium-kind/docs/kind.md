# Useful Kind and Kubernetes Commands

## Kind-specific Commands

1. Create a cluster:
   `kind create cluster --name my-cluster`

2. Delete a cluster:
   `kind delete cluster --name my-cluster`

3. Get cluster information:
   `kind get clusters`

4. Load a Docker image into your Kind cluster:
   `kind load docker-image my-image:tag --name my-cluster`

5. Export kubeconfig:
   `kind export kubeconfig --name my-cluster`

## Kubernetes Commands for Kind Clusters

1. Get nodes in the cluster:
   `kubectl get nodes`

2. Get pods in all namespaces:
   `kubectl get pods --all-namespaces`

3. Get services in all namespaces:
   `kubectl get services --all-namespaces`

4. Describe a specific node:
   `kubectl describe node <node-name>`

5. Get cluster information:
   `kubectl cluster-info`

6. Get API resources:
   `kubectl api-resources`

## Network-related Commands

1. Get the IP address of the Kind control-plane node:
```bash   
   docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' my-cluster-control-plane
```
2. Port-forward a service:
   `kubectl port-forward service/my-service 8080:80`

3. Get ingress resources:
   `kubectl get ingress --all-namespaces`

## Cilium and Hubble Commands

1. Check Cilium status:
   `cilium status`

2. Run Cilium connectivity test:
   `cilium connectivity test`

3. Enable Hubble:
   `cilium hubble enable`

4. Access Hubble UI (after port-forwarding):
   `kubectl port-forward -n kube-system svc/hubble-ui 12000:80`

## Debugging Commands

1. Get logs from a pod:
   `kubectl logs <pod-name>`

2. Execute a command in a pod:
   `kubectl exec -it <pod-name> -- /bin/bash`

3. Describe a pod:
   `kubectl describe pod <pod-name>`

4. Get events:
   `kubectl get events --sort-by=.metadata.creationTimestamp`

## Helm Commands (if using Helm)

1. List releases:
   `helm list`

2. Install a chart:
   `helm install my-release my-chart`

3. Upgrade a release:
   `helm upgrade my-release my-chart`

4. Uninstall a release:
   `helm uninstall my-release`

Remember to replace placeholders like `<node-name>, <pod-name>,` etc., with actual values from your cluster.


```bash
echo "127.0.0.1 hubble.localhost" | sudo tee -a /etc/hosts
##intall nginx controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
## add timing
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
## apply ingress
kubectl apply -f hubble-ui-ingress.yaml
## verify ingress resource
kubectl get ingress -n kube-system

cilium hubble enable

kubectl port-forward -n kube-system svc/hubble-ui 8080:80

ssh -L 8080:localhost:8080 user@remote-machine-ip

kubectl port-forward -n kube-system svc/hubble-ui 8080:80