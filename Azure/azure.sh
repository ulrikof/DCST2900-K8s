# Getting started guide: https://docs.crossplane.io/latest/getting-started/provider-azure/

## Install Crossplane

### Install the Crossplane Helm chart
#Enable the Crossplane Helm Chart repository:
helm repo add \
crossplane-stable https://charts.crossplane.io/stable
helm repo update

#Run the Helm dry-run to see all the Crossplane components Helm installs.
helm install crossplane \
crossplane-stable/crossplane \
--dry-run --debug \
--namespace crossplane-system \
--create-namespace

#Install the Crossplane components using helm install.
helm install crossplane \
crossplane-stable/crossplane \
--namespace crossplane-system \
--create-namespace

#Verify Crossplane installed:
kubectl get pods -n crossplane-system

#Installing Crossplane creates new Kubernetes API end-points. Look at the new API end-points:
kubectl api-resources  | grep crossplane

## Install the Azure provider

#Install the Azure Network resource provider into the Kubernetes cluster with a Kubernetes configuration file.
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-azure-network
spec:
  package: xpkg.crossplane.io/crossplane-contrib/provider-azure-network:v1.11.2
EOF

#Verify the provider installed
kubectl get providers

## Create a Kubernetes secret for Azure

### Install the Azure CLI
#Follow the MS Docs: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt#install-azure-cli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login

### Create an Azure service principal
#Find your Azure subscription ID:
az account list --query "[].{Name:name, ID:id}" -o table

#REPLACE <subscription_id> with your Azure subscription ID.
#Save your Azure JSON output as azure-credentials.json
az ad sp create-for-rbac \
--sdk-auth \
--role Owner \
--scopes /subscriptions/<subscription_id> \ 
> azure-credentials.json | cat azure-credentials.json

### Create a Kubernetes secret with the Azure credentials

kubectl create secret \
generic azure-secret \
-n crossplane-system \
--from-file=creds=./azure-credentials.json

#View the secret:
kubectl describe secret azure-secret -n crossplane-system

## Create a ProviderConfig

cat <<EOF | kubectl apply -f -
apiVersion: azure.upbound.io/v1beta1
metadata:
  name: default
kind: ProviderConfig
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: azure-secret
      key: creds
EOF

## Create a managed resource

cat <<EOF | kubectl create -f -
apiVersion: network.azure.upbound.io/v1beta1
kind: VirtualNetwork
metadata:
  name: crossplane-quickstart-network
spec:
  forProvider:
    addressSpace:
      - 10.0.0.0/16
    location: "West Europe"
    resourceGroupName: rg-crossplane-testing
EOF

#Verify the resource created:
kubectl get virtualnetwork.network

## Delete the managed resource

kubectl delete virtualnetwork.network crossplane-quickstart-network
