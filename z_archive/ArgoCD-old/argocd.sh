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

### Service Type NodePort

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
# Get the ip addresses of the nodes in the cluster 
k get nodes -o wide
# Get the nodePort of the argocd-server service.
k get svc -n argocd argocd-server

## 4. Login using the CLI

### Get the initial password

argocd admin initial-password -n argocd

### Login

#argocd login <ARGOCD_SERVER>:<ARGOCD_PORT>
argocd login localhost:8080

### Change the password

argocd account update-password


## 5. Register A Cluster To Deploy Apps To (Optional)


## 6. Create An Application From A Git Repository

### Creating Apps via CLI

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
#example guestbook app
argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default


## 7. Sync (Deploy) The Application

### View the application status
#argocd app get <APP_NAME>
argocd app get guestbook

### Sync (Deploy) the application
#argocd app sync <APP_NAME>
argocd app sync guestbook


## 8. Make changes to the application

### Find the Argo CD Server Endpoint
kubectl get svc argocd-server -n argocd

### Change namespace
#argocd app set guestbook --dest-namespace <NEW_NAMESPACE>
argocd app set guestbook --dest-namespace guestbook

### Sync application manually
#argocd app sync <APP_NAME>
argocd app sync guestbook

### Sync application automatically
#argocd app set <APP_NAME> --sync-policy <POLICY>
argocd app set guestbook --sync-policy automated

### Refresh app status
#argocd app get <APP_NAME> --refresh
argocd app get guestbook --refresh

### Enable self-healing
#argocd app set <APP_NAME> --auto-prune --self-heal
argocd app set guestbook --auto-prune --self-heal

### Delete the application
#argocd app delete <APP_NAME>
argocd app delete guestbook


# Deploy an application using the YAML file

## Add SSH key to ArgoCD
####(and to the Git repository as a deploy key)
#argocd repo add <REPO_SSH_URL> --ssh-private-key-path ~/.ssh/<NAME_OF_KEY>
argocd repo add git@github.com:ulrikof/DCST2900-K8s.git --ssh-private-key-path ~/.ssh/id_argocd

### Check if the repo is added
argocd repo list

## Create an application from a YAML file
#kubectl apply -f <YAML_FILE>
kubectl apply -f ArgoCD/guestbook.yaml
