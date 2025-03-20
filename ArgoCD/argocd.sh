# Getting started guide: https://argo-cd.readthedocs.io/en/stable/getting_started/

## 1. Install ArgoCD

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

## 2. Download ArgoCD CLI

curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

## 3. Access The ArgoCD API Server

### Port Forwarding

kubectl port-forward svc/argocd-server -n argocd 8080:443

## 4. Login using the CLI

### Get the initial password

argocd admin initial-password -n argocd

### Login

#argocd login <ARGOCD_SERVER>
argocd login localhost:8080

### Change the password

argocd account update-password

## 5. Register A Cluster To Deploy Apps To (Optional)

## 6. Create An Application From A Git Repository

### Creating Apps via CLI

kubectl config set-context --current --namespace=argocd
#example guestbook app
argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default
