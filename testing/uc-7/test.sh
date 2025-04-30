### Start state

# Verify a cluster with three worker nodes
kubectl get nodes

# If any extra nodes are there, delete them
kubectl delete node <node-name>

### Action

# Taint and label the nodes
kubectl taint nodes talos-hmo-npk talos-q4c-s8s talos-us7-2js dedicated=talos:NoSchedule

kubectl label node talos-hmo-npk talos-q4c-s8s talos-us7-2js dedicated=talos 

# Verify

kubectl get nodes talos-hmo-npk talos-q4c-s8s talos-us7-2js -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints[*].key,DEDICATED_LABEL:.metadata.labels.dedicated

# Ensure that longhorn tolerates taints
# Set the setting: "Kubernetes Taint Toleration" to ":"

# Apply the cluster
# Apply the Chart found under 
ArgoCD/charts/k8s-in-k8s-with-taint

# A template app for this is under: ArgoCD/apps/deprec-or-testing/k8s-in-k8s-with-taint.yaml

# Veriy the cluster is running
kubectl get all -n k8s-in-k8s

# Apply a test pod
kubectl run test-pod --image=alpine -- sleep 3600

### End state
# Verify that the virtual cluster is running on the three nodes
kubectl get nodes
kubectl get all -n k8s-in-k8s

# Verify pod is unscheduable
kubectl get pod

kubectl describe pod | grep Warning


# Restart the nodes originally removed, they should then join the cluster automatically

# when the new nodes join the cluster, the pod should automatically be scheduled on one of the new nodes
kubectl get pod -o wide
