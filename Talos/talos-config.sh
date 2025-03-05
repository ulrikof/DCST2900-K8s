# 1. Deploy nodes in openstack with talos os

# 2. Generate config

talosctl gen-config k8s-cluster https://192.168.0.82:6443

# 3. Send config to one control plane node:

talosctl --talosconfig=./talosconfig \
    apply-config --insecure --nodes 192.168.0.82 \
    --file controlplane.yaml

# 4. Validate control plane 

talosctl --talosconfig=./talosconfig \
    --nodes 192.168.0.82 -e 192.168.0.82 version

# 5. Bootsrap control plane

talosctl bootstrap --nodes 192.168.0.82 --endpoints 192.168.0.82 \
  --talosconfig=./talosconfig

# 6. Retrive kubeconfig

talosctl --talosconfig=./talosconfig \
    --nodes 192.168.0.82 \
    kubeconfig ./

# 7. Test kubernetes access

export KUBECONFIG=./kubeconfig
kubectl get nodes

# 8. Send config to rest of control plane nodes

talosctl apply-config --insecure \
  --nodes 192.168.0.38 \
  --file ./controlplane.yaml

talosctl apply-config --insecure \
  --nodes 192.168.0.55 \
  --file ./controlplane.yaml

# 9. Send config to worker nodes:

talosctl apply-config --insecure \
  --nodes 192.168.0.77 \
  --file ./worker.yaml

talosctl apply-config --insecure \
  --nodes 192.168.0.119 \
  --file ./worker.yaml

  talosctl apply-config --insecure \
  --nodes 192.168.0.156 \
  --file ./worker.yaml

# 10. Verify node health
talosctl --nodes 192.168.0.82 --endpoints 192.168.0.82  health --talosconfig=./talosconfig

# 11. basic kubectl commands

# Hent noder
kubectl get node
kubectl get pod -o wide
 
kubectl cluster-info

kubectl get svc

kubectl describe svc test-nginx

kubectl describe pod ...

curl 192.168.0.82:31431
