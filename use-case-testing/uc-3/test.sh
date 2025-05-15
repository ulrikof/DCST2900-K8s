### Start state

## In physical cluster
# Create a virtual cluster that is horizontally scalable, this can be done by applying the v-cluster-app.yaml file to the app folder in Git.

# Verify virtual nodes
kubectl get vm -n k8s-in-k8s

## In the virtual cluster

# Apply resources

kubectl apply -f hpa.yaml -f pod.yaml

## In physical cluster

# Verify that this is below treshold
kubectl get hpa -n k8s-in-k8s


### Action

## In virtual cluster

# Increase amount of pods in the HPA to a large number, for instance 100.

kubectl edit hpa scaling-test-hpa

### End state

## In physical cluster

# Check resource utilization, a new worker node should have been added:

kubectl get hpa -n k8s-in-k8s
kubectl get vm -n k8s-in-k8s


