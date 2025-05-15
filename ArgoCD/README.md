# Installation of Argo CD and Setup of Automatic Design Installation

Argo CD can be installed using the `argo-cd-setup.sh` script. However, due to known issues, it is recommended to run the commands manually, one at a time. A detailed step-by-step installation and setup is described below.

## Installation of Argo CD

To install Argo CD in the cluster, run the following commands:

```sh
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Then, install the Argo CD CLI:

```sh
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

Wait until all Argo CD resources have been deployed. All Argo CD pods should be running. You can verify this with:

```sh
kubectl get all -n argocd
```

## Configure Argo CD

*(Note: If the repository is private, add authentication steps here. This section can be skipped for public repositories.)*

## Apply App-of-Apps

To enable Argo CD to install the cluster design, you need to manually create an Application that points to the `ArgoCD/apps` folder. This is done by applying the `ArgoCD/app-of-apps.yaml` manifest to the cluster:

```sh
kubectl apply -f ArgoCD/app-of-apps.yaml
```

Once applied, Argo CD should automatically begin installing the add-ons and default applications. You can confirm this by checking for new namespaces:

```sh
kubectl get ns
```

If namespaces like `kubevirt` and `longhorn-system` exist and contain running pods, the installation was successful.

## Configure Argo CLI to Work with Argo CD

The design uses MetalLB to expose the Argo CD frontend via a load balancer, which simplifies CLI usage. Make sure that MetalLB is configured correctly for your network. See `ArgoCD/deployments/metalLb` for an example configuration.

After MetalLB is installed and configured, expose the Argo CD server using:

```sh
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

Then use the following to log in with the CLI:

```sh
ip=$(kubectl get service argocd-server -n argocd --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
pw=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

argocd login $ip --username admin --password $pw --insecure
```

You can now use the Argo CLI to inspect and manage your applications. For example:

```sh
argocd app get app-of-apps
argocd app sync app-of-apps
```