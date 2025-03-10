### See: https://longhorn.io/docs/1.7.2/deploy/install/install-with-helm/


# Install helm


sudo snap install helm --classic

# Create the longhorn-namespace.yaml, see own file. See: https://longhorn.io/docs/1.7.2/important-notes/#pod-security-policies-disabled--pod-security-admission-introduction

kubectl apply -f longhorn-namespace.yaml 

# Verify

kubectl get namespace

# Install longhorn

helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --version 1.7.2

# Verify, takes some minutes before all pods are online:

kubectl -n longhorn-system get pod


# Enable login for ui
USER=user; PASSWORD=password; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth

kubectl -n longhorn-system create secret generic basic-auth --from-file=auth

kubectl -n longhorn-system apply -f longhorn-ingress.yml


### WEB ui, see: https://longhorn.io/docs/1.7.2/deploy/accessing-the-ui/longhorn-ingress/

# Install this:

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=NodePort

# Find port number:

kubectl get svc -n ingress-nginx

# Find ip of worker:

kubectl get nodes -o wide

# In this instance of the setup it can be reached at:

http://192.168.1.94:30295/#/dashboard