# ArgoCD directory structure
> https://www.reddit.com/r/ArgoCD/comments/1jf7u20/comment/mj4ixjb/


The repository that contains argo-cd looks like this:

```
├── apps     # Optional folder, explained below
├── bootstrap
├── projects
└── scripts
```

The `bootstrap` folder contains everything needed to install ArgoCD and bootstrap your applications:

```
├── argocd                 # ArgoCD installation manifests (using Kustomize)
├── argocd-app.yaml        # Application that syncs the ./argocd folder
├── bootstrap-apps.yaml    # Application that syncs apps in the "/projects" folder
├── bootstrap-proj.yaml    # ArgoCD project for bootstrap-apps.yaml
└── kustomization.yaml     # Kustomize manifest that applies ArgoCD and bootstrap
```

To install everything on a cluster, simply run:

```sh
kubectl apply -k ./bootstrap
```

This creates two applications, one for managing ArgoCD itself, and one for bootstrapping all other applications.

In `projects` we organizes all our applications, separated by function:

```
├── apps    # Regular applications
└── infra   # Infrastructure components (monitoring, logging, cert-manager, etc.)
```

Each application gets its own folder with necessary configuration:

```
├── apps
│   └── cyberchef
│       ├── cyberchef-app.yaml     # The ArgoCD Application manifest
│       ├── cyberchef-ns.yaml      # Namespace definition
│       └── kustomization.yaml     # Kustomize manifest
└── infra
    └── cert-manager
        ├── cert-manager-app.yaml  # The ArgoCD Application manifest
        ├── cert-manager-ns.yaml   # Namespace definition
        └── kustomization.yaml     # Kustomize manifest
```

These folders contain the Application manifests and other resources that shouldn't be managed by the applications themselves (namespaces, network policies, ArgoCD projects, etc.).

For multi-environment setups, you can add another layer:

```
└── cert-manager
    ├── dev
    ├── staging
    ├── prod
    └── kustomization.yaml
```

A key best practice: application manifests don't live with application source code. 
For example, cert-manager is installed via Helm, so its actual manifests live in the upstream Helm repository. 
The ArgoCD Application manifest in your repo simply references these external sources.

For the `apps` folder: In enterprise environments, each application typically has its own repository for manifests, Helm values, or Kustomize overlays. However, for smaller setups (like homelabs), you might keep everything in a single repository using the /apps folder:

    
```
├── cert-manager             # Helm example
│   └── values.yaml
└── cyberchef                # Kustomize example
    ├── cyberchef-deploy.yaml
    ├── cyberchef-ingress.yaml
    ├── cyberchef-svc.yaml
    └── kustomization.yaml
```

Here's how the Application manifests might look:

For a Kustomize-based app (cyberchef):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cyberchef
  namespace: argocd
spec:
  project: cyberchef
  source:
    repoURL: https://git.com/argo-cd.git
    path: apps/cyberchef
    targetRevision: HEAD
  destination:
    name: in-cluster
    namespace: cyberchef
```

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cert-manager
  namespace: argocd
spec:
  project: cert-manager
  sources:
    - chart: cert-manager
      repoURL: https://charts.jetstack.io
      targetRevision: v1.17.1
      helm:
        valueFiles:
          - $values/apps/cert-manager/values.yaml
    - repoURL: https://git.com/argo-cd.git
      targetRevision: HEAD
      ref: values
  destination:
    name: in-cluster
    namespace: cert-manager
```
