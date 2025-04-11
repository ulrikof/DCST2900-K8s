#!/bin/bash

set -euo pipefail

# Inputs
user=""
namespace=""
kubeconfig=""

usage() {
  echo "Usage: $0 --user <username> --namespace <ns> --kubeconfig <path>"
  exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --user)
      user="$2"; shift 2 ;;
    --namespace)
      namespace="$2"; shift 2 ;;
    --kubeconfig)
      kubeconfig="$2"; shift 2 ;;
    *)
      echo "Unknown option: $1"; usage ;;
  esac
done

[[ -z "$user" || -z "$namespace" || -z "$kubeconfig" ]] && usage

# Approve the CSR
echo "[+] Approving CSR for user: $user"
kubectl --kubeconfig "$kubeconfig" certificate approve "$user-csr"

# Wait for cert to appear
echo "[~] Waiting for certificate to be signed..."
while [[ -z $(kubectl --kubeconfig "$kubeconfig" get csr "$user-csr" -o jsonpath='{.status.certificate}') ]]; do
  sleep 1
done

# Copy signed cert to user's kube dir
user_kube_dir="/home/$user/.kube"
sudo mkdir -p "$user_kube_dir"
kubectl --kubeconfig "$kubeconfig" get csr "$user-csr" -o jsonpath='{.status.certificate}' \
  | base64 -d | sudo tee "$user_kube_dir/client.crt" > /dev/null

sudo chown "$user:$user" "$user_kube_dir/client.crt"
echo "# Signed certificate installed for $user"