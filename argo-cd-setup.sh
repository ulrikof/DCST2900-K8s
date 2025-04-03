kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


## 2. Download ArgoCD CLI

curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

argocd repo add git@github.com:ulrikof/DCST2900-K8s.git --ssh-private-key-path ~/.ssh/git-argo-key

    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: app-of-apps
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: https://github.com/ulrikof/DCST2900-K8s
        targetRevision: main
        path: ArgoCD/apps
      destination:
        server: https://kubernetes.default.svc
        namespace: argocd
      syncPolicy:
        automated:
          prune: true
          selfHeal: true