# Getting started guide: https://docs.crossplane.io/latest/getting-started/provider-azure/

## Install Crossplane

### Manual installation (when not using ArgoCD)

# #Enable the Crossplane Helm Chart repository:
# helm repo add \
# crossplane-stable https://charts.crossplane.io/stable
# helm repo update

# #Install the Crossplane components
# helm install crossplane \
# crossplane-stable/crossplane \
# --namespace crossplane-system \
# --create-namespace

# #Verify
# kubectl get pods -n crossplane-system


### Install the Crossplane CLI
#https://docs.crossplane.io/latest/cli/

#The Crossplane CLI is a single standalone binary with no external dependencies.
curl -sL "https://raw.githubusercontent.com/crossplane/crossplane/main/install.sh" | sh
#The script detects your CPU architecture and downloads the latest stable release.

# ### Install the Azure provider
# cat <<EOF | kubectl apply -f -
# apiVersion: pkg.crossplane.io/v1
# kind: Provider
# metadata:
#   name: provider-azure-network
# spec:
#   package: xpkg.crossplane.io/crossplane-contrib/provider-azure-network:v1.11.2
# EOF


# Install the Azure CLI
#Follow the MS Docs: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt#install-azure-cli
#curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash # This gave me some problems

## Step-by-step install
### Get packages needed for the installation
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

### Download and install the Microsoft signing key
sudo mkdir -p /etc/apt/keyrings
curl -sLS https://packages.microsoft.com/keys/microsoft.asc |
  gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/microsoft.gpg

### Add the Azure CLI software repository
AZ_DIST=$(lsb_release -cs)
echo "Types: deb
URIs: https://packages.microsoft.com/repos/azure-cli/
Suites: ${AZ_DIST}
Components: main
Architectures: $(dpkg --print-architecture)
Signed-by: /etc/apt/keyrings/microsoft.gpg" | sudo tee /etc/apt/sources.list.d/azure-cli.sources

### Update repository information and install the azure-cli package
sudo apt update
sudo apt install -y azure-cli

### Try to login to Azure
az login

### Create an Azure service principal
#Find your Azure subscription ID:
az account list --query "[].{Name:name, ID:id}" -o table

#REPLACE <subscription_id> with your Azure subscription ID.
#Save your Azure JSON output as azure-credentials.json
az ad sp create-for-rbac \
--role Owner \
--scopes /subscriptions/<subscription_id> \
--sdk-auth > azure-credentials.json && cat azure-credentials.json

### Create a Kubernetes secret with the Azure credentials

kubectl create secret \
generic azure-secret \
-n crossplane-system \
--from-file=creds=./azure-credentials.json

#View the secret:
kubectl describe secret azure-secret -n crossplane-system

# ### Create a ProviderConfig
# cat <<EOF | kubectl apply -f -
# apiVersion: azure.upbound.io/v1beta1
# metadata:
#   name: default
# kind: ProviderConfig
# spec:
#   credentials:
#     source: Secret
#     secretRef:
#       namespace: crossplane-system
#       name: azure-secret
#       key: creds
# EOF


## Create a managed resource
#https://docs.crossplane.io/latest/getting-started/provider-azure/#create-a-managed-resource
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
    resourceGroupName: rg-crossplane
EOF


# External Secret Operator
# https://github.com/jonashackt/crossplane-argocd/blob/main/README.md#getting-rid-of-the-manual-k8s-secrets-creation

# Create a secret for the external secret operator, name it according to the ESO you're using
kubectl create secret generic \
    doppler-token-auth-api \
    --from-literal dopplerToken="dp.st.xxxx" # Replace with your own token
