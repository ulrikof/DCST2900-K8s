# instal kubectl

sudo snap install kubect

kubectl version --client


# Install talosctl:

curl -sL https://talos.dev/install | sh

# generate config files (ip needs to be the ip of a control plane node (or lb infront of control plane)):

talosctl gen config K8s-test https://192.168.1.66:6443

# set default endpoint and node in talosconfig file:

talosctl --talosconfig talosconfig config endpoint 192.168.1.66
talosctl --talosconfig talosconfig config node 192.168.1.66


# Export talosconfig file (shold be added to bashrc to avoid having to do this all the time)

export TALOSCONFIG=~/talosconfig


# APPly config to control plane
talosctl apply-config --insecure --nodes 192.168.1.66 --file controlplane.yaml

# Apply config to worker

talosctl apply-config --insecure --nodes 192.168.1.94 --file worker.yaml
talosctl apply-config --insecure --nodes 192.168.1.215 --file worker.yaml
talosctl apply-config --insecure --nodes 192.168.1.101 --file worker.yaml


# Bootstrap 
talosctl bootstrap

# Retrive kubeconfig

talosctl kubeconfig .

export KUBECONFIG=./kubeconfig
kubectl get nodes