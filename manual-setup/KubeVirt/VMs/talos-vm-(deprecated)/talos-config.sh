# Set the IP as an environment variable
export IP=10.244.8.74

# 1. Generate config
talosctl gen config K8s https://$IP:6443 --config-patch @all-patch.yaml --config-patch-worker @worker-patch.yaml

# 2. Set endpoint and node
talosctl --talosconfig talosconfig config endpoint $IP
talosctl --talosconfig talosconfig config node $IP

# 3. Set TALOSCONFIG path
export TALOSCONFIG=~/talos/talosconfig

# 4. Apply config
talosctl apply-config --insecure --nodes $IP --file controlplane.yaml

# 5. Bootstrap the cluster
talosctl bootstrap

# 6. Retrive Kubeconfig
talosctl kubeconfig .

# 7. Export kubeconfig so that kubectl can get access to the cluster (should be added to bashrc)

export KUBECONFIG=~/talos/kubeconfig

# 8. Verify cluster

# get nodes:
kubectl get nodes