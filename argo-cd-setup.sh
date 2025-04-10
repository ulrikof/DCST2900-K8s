kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


## 2. Download ArgoCD CLI (if manager doesnt have it)

curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# expose argocd instance and connect to repo
(kubectl port-forward svc/argocd-server -n argocd 8080:443 &> /dev/null) &
# If you leave the CLI without setting up permanent port-forwarding you will need to repeat this ^
pw=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
#argocd account update-password # Change password if you want to
argocd login localhost:8080 --username admin --password $pw --insecure
argocd repo add git@github.com:ulrikof/DCST2900-K8s.git --ssh-private-key-path ~/.ssh/git-argo-key

# start app-of-apps
pwd=$(pwd)
kubectl apply -f $pwd/app-of-apps.yaml

until [[ $(kubectl get -n metallb-system ipaddresspools.metallb.io 2>/dev/null | wc -l) -gt 1 ]]; do
    sleep 2
    echo "Waiting for IP address pools..."
done

# patch loadbalancer into config for argo cli
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
ip=$(kubectl get service argocd-server -n argocd --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')

argocd login $ip --username admin --password $pw --insecure

# we should probably change password at some point