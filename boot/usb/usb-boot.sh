# instal kubectl

sudo snap install kubectl --classic

kubectl version --client


# Install talosctl:

curl -sL https://talos.dev/install | sh

# generate config files (ip needs to be the ip of a control plane node (or lb infront of control plane)):

talosctl gen config K8s https://10.100.38.101:6443

# set default endpoint and node in talosconfig file:

talosctl --talosconfig talosconfig config endpoint 10.100.38.101
talosctl --talosconfig talosconfig config node 10.100.38.101


# Export talosconfig file (shold be added to bashrc to avoid having to do this all the time)

export TALOSCONFIG=~/talos/talosconfig


# edit machineconfg:
     serviceSubnets:
            - 10.112.0.0/12

# Change config to contain the contens of extra-machineconfig.yaml. see: https://longhorn.io/docs/1.7.2/advanced-resources/os-distro-specific/talos-linux-support/

# APPly config to control plane
talosctl apply-config --insecure --nodes 10.100.38.101 --file controlplane.yaml
talosctl apply-config --insecure --nodes 10.100.38.102 --file controlplane.yaml
talosctl apply-config --insecure --nodes 10.100.38.103 --file controlplane.yam

# Add extra machineconfig for workers

talosctl apply-config --insecure --nodes 10.100.38.104 --file worker.yaml
talosctl apply-config --insecure --nodes 10.100.38.105 --file worker.yaml
talosctl apply-config --insecure --nodes 10.100.38.106 --file worker.yaml


# Bootstrap 
talosctl bootstrap

# Retrive kubeconfig

talosctl kubeconfig .

export KUBECONFIG=~/talos/kubeconfig
kubectl get nodes