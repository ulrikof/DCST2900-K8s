### See: https://www.talos.dev/v1.10/kubernetes-guides/configuration/deploy-metrics-server/

# Patch the machineconfig with the following patch:
machine:
  kubelet:
    extraArgs:
      rotate-server-certificates: true

# Apply the manifests (NB! The first manifest must be applied to avoid the patch over breaking the cluster.)
kubectl apply -f https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/main/deploy/standalone-install.yaml
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

