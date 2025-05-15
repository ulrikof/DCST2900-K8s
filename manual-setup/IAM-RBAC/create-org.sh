#!/bin/bash

set -euo pipefail

default_namespaces="default"

usage() {
  echo "Usage: $0 --org <org-name> [--namespaces <ns1,ns2,...>]"
  exit 1
}

org=""
namespaces=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --org)
      org="$2"
      shift 2
      ;;
    --namespaces)
      namespaces="$2"
      shift 2
      ;;
    *)
      echo "Unknown arg: $1"
      usage
      ;;
  esac
done

[[ -z "$org" ]] && usage

if [[ -n "$namespaces" ]]; then
  namespaces="$default_namespaces,$namespaces"
else
  namespaces="$default_namespaces"
fi

group="${org}-admins"
clusterrole="${org}-admin" 
IFS=',' read -ra ns_array <<< "$namespaces"

# for POC we only create admins, but we could easily make a check for role type and create viewers also
if kubectl get clusterrole "$clusterrole" &>/dev/null; then
  echo "[i] Org '$org' already exists. Skipping ClusterRole creation."
else
  echo "[+] Creating ClusterRole '$clusterrole' for org '$org'..."
  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: $clusterrole
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets", "persistentvolumeclaims"]
  verbs: ["*"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets", "daemonsets"]
  verbs: ["*"]
- apiGroups: ["batch"]
  resources: ["jobs", "cronjobs"]
  verbs: ["*"]
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["roles", "rolebindings"]
  verbs: ["create", "get", "list", "watch"]
EOF
fi

echo "[+] Creating namespaces and RoleBindings for group '$group'"
for ns_suffix in "${ns_array[@]}"; do
  ns="${org}-${ns_suffix}"
  echo "  └─ Processing namespace: $ns"

  if kubectl get namespace "$ns" &>/dev/null; then
    echo "    [i] Namespace '$ns' already exists. Skipping creation."
  else
    kubectl create namespace "$ns"
  fi

  echo "    [~] Labeling namespace '$ns'"
  kubectl label namespace "$ns" \
    "org=$org" \
    "tenant=tenant" \
    --overwrite

  binding_name="${group}-binding"
  if kubectl get rolebinding "$binding_name" -n "$ns" &>/dev/null; then
    echo "    [i] RoleBinding '$binding_name' already exists in '$ns'. Skipping."
  else
    kubectl create rolebinding "$binding_name" \
      --namespace="$ns" \
      --clusterrole="$clusterrole" \
      --group="$group"
  fi

  echo "    [+] Applying org-allow-intra-namespace netpol for '$ns'."
  kubectl apply -n $ns -f /home/ubuntu/allow-org-intra-namespace.yaml
done

echo "[✔] Org '$org' now has access to namespaces: $namespaces"