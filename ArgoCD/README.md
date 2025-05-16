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

## Using Argo CD to Deploy Manifests

All add-ons are installed under the `ArgoCD/apps/addons` directory. Any new add-ons should be placed here, as the virtual clusters reference this folder to install only the add-ons. 

To deploy a manifest using Argo CD, create a folder containing the manifest inside the `ArgoCD/deployments` directory. Then, define an Argo CD application in the `ArgoCD/apps` directory that points to this folder. Argo CD will then automatically synchronize the application and deploy the manifest.

You can also deploy instances of Helm Charts, which serve as reusable manifest templates. These charts are located in the `ArgoCD/charts` directory, and only require an application that references them.

Examples of both direct manifest deployments and Helm Chart-based deployments can be found in `ArgoCD/apps/application-examples`.

Under `ArgoCD/apps/orgs`, there exists an example of how to deploy an entire tenant. There are two apps by defualt, each specifying a seperate tenant but with the same content. The org-apps create a virtual cluster along with other testing resources as well as setting up users and such.