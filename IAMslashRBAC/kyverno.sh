kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.13.0/install.yaml
kubectl get pods -n kyverno

path="."
kubectl apply -f $path/require-org-label.yaml