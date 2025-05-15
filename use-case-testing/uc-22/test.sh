### Start state

# Ensure cluster with Argo CD access exists

### Action

# Open the Azure portal in webbrowser to monitor the state of Azure


# Run the following commands

kubectl create -f resourcegroup.yaml

kubectl get resourcegroup

kubectl create -f vnet.yaml

kubectl get virtualnetwork.network

kubectl delete -f vnet.yaml

kubectl delete -f resourcegroup.yaml

kubectl get virtualnetwork.network

kubectl get resourcegroup

### End state

# Output of the commands should be as expected

# The result of the commands should be shown in the azure portal