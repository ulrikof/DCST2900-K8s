talosctl gen config K8s https://192.168.0.50:6443

# Set default endpoint and node 

talosctl --talosconfig talosconfig config endpoint 192.168.0.50
talosctl --talosconfig talosconfig config node 192.168.0.50

# Change config to contain the contens of extra-machineconfig.yaml. see: https://longhorn.io/docs/1.7.2/advanced-resources/os-distro-specific/talos-linux-support/

# Export config such that it does not need to be specified in commands
export TALOSCONFIG=~/talos/talosconfig

# Apply config to control plane

talosctl apply-config --insecure --nodes 192.168.0.50 --file controlplane.yaml
talosctl apply-config --insecure --nodes 192.168.0.112 --file controlplane.yaml
talosctl apply-config --insecure --nodes 192.168.0.187 --file controlplane.yaml

# Apply config to worker

talosctl apply-config --insecure --nodes 192.168.0.110 --file worker.yaml
talosctl apply-config --insecure --nodes 192.168.0.32 --file worker.yaml
talosctl apply-config --insecure --nodes 192.168.0.145 --file worker.yaml

# Bootstrap
talosctl bootstrap --nodes 192.168.0.50

# Retrive kubeconfig
talosctl kubeconfig . --nodes 192.168.0.50

# Export it for kubectl
export KUBECONFIG=~/talos/kubeconfig

# Check if it works
kubectl get nodes

# Check health of talos nodes
talosctl health