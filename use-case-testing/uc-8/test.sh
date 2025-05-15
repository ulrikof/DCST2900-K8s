### Start state

# Create north-org and south-org. See ArgoCD/apps/orgs.

# For each org, add users to the virtual cluster through the user scripts.

### Action

# On the management IP of one of the north org, copy the kubeconfig and edit the copy to contain the lb of the other org

cp ~/.kube/config ~/.kube/config-south

vim ~/.kube/config-south

### End state

# Check if access is allowed

# Access should be granted with north org API IP

kubectl --kubeconfig=~/.kube/config get nodes

# Access should be denied with north org API IP

kubectl --kubeconfig=~/.kube/south-config get nodes