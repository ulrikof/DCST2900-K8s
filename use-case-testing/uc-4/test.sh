### Start state

## In a virtual cluster

# Apply resources

kubectl apply -f configmap.yaml -f deployment.yaml -f expose.yaml

# Find external IP of LB

kubectl get svc test-nginx

# Verify deployment is working

curl <lb-ip>

# Find the virtual node that the pod is running on

kubectl get pod -o wide

# In the physical cluster

# Find which physical node the virtual node hosting the pod is running on

kubectl get vmi <virtual-node-name>

### Action

# Cut power to the physical which the virtual node hosting the pod is running on

### End state

## In virtual cluster

# Inspect all resources, after a while, a new pod should be created on a new node:

kubectl get pod -o wide

# This should be reachable over same IP

curl <lb-ip>
