


## 2. Download ArgoCD CLI (if manager doesnt have it)

# curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
# sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
# rm argocd-linux-amd64

# !!!!!!!!!!!!!!! DONT RUN THIS SCRIPT ON AUTO LOL

if ! command -v argocd >/dev/null 2>&1; then
  echo "🔍 'argocd' not found. Installing Argo CD CLI..."
  curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
  sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
  rm argocd-linux-amd64
  echo "✅ 'argocd' CLI installed successfully."
else
  echo "✅ 'argocd' is already installed at: $(command -v argocd)"
fi

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl wait deployment argocd-server -n argocd --for=condition=Available=True --timeout=180s 
# expose argocd instance and connect to repo
# kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "PortForward"}}'

kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# If you leave the CLI without setting up permanent port-forwarding you will need to repeat this ^
pw=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login localhost:8080 --username admin --password $pw --insecure
argocd repo add git@github.com:ulrikof/DCST2900-K8s.git --ssh-private-key-path ~/.ssh/git-argo-key

argocd app create app-of-apps --repo git@github.com:ulrikof/DCST2900-K8s.git --path ArgoCD 

# start app-of-apps
pwd=$(pwd)
kubectl apply -f $pwd/app-of-apps.yaml

sleep 10

# kubectl apply -f $pwd/app-of-apps.yaml

kubectl patch configmap argocd-cm \
  -n argocd \
  --type merge \
  -p '{"data": {"timeout.reconciliation": "30s"}}'
configmap/argocd-cm patched

argocd app sync metallb-config

until [[ $(kubectl get -n metallb-system ipaddresspools.metallb.io 2>/dev/null | wc -l) -gt 1 ]]; do
    sleep 2
    echo "Waiting for IP address pools..."
done

# patch loadbalancer into config for argo cli
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
sleep 5
ip=$(kubectl get service argocd-server -n argocd --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
pw=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

argocd login $ip --username admin --password $pw --insecure

# kubectl patch configmap argocd-cm \
#   -n argocd \
#   --type merge \
#   -p '{"data": {"timeout.reconciliation": "30s"}}'
# configmap/argocd-cm patched

# we should probably change password at some point
