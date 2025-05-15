### Start state

# Have cluster with crossplane and external secrets working
# Add azure secrets to cluster

### Action

# Apply azure resource without references to secrets

kubectl apply -f resource-group.yaml

### End state

# Verify that resource group exists

kubectl get resourcegroups