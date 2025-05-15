### Start state

# Verify nodes in the cluster
kubectl get node

### Action

# Turn on new server, allow it to PXE boot into Talos

### End state

# After the server is running, check if it has joined the cluster

kubectl get node

# The new server should new be visible