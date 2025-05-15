#!/bin/bash
set -euo pipefail

# DEBUG LOGGER
troubleshoot() { echo "[### $1]"; }

# Uncomment next line when done debugging
# troubleshoot() { echo "[### $1]"; }

user=""
kubeconfig=""

usage() {
  echo "Usage: $0 --user <username> --kubeconfig <path>"
  exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) user="$2"; shift 2 ;;
    --kubeconfig) kubeconfig="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

[[ -z "$user" || -z "$kubeconfig" ]] && usage

csr_name="${user}-csr"
home_kube="/home/$user/.kube"
client_crt_path="$home_kube/client.crt"

troubleshoot "Approving CSR: $csr_name"
kubectl --kubeconfig="$kubeconfig" certificate approve "$csr_name"

troubleshoot "Waiting for signed certificate from API server..."
while [[ -z $(kubectl --kubeconfig="$kubeconfig" get csr "$csr_name" -o jsonpath='{.status.certificate}') ]]; do
  sleep 1
done

troubleshoot "Fetching signed certificate and writing to: $client_crt_path"
kubectl --kubeconfig="$kubeconfig" get csr "$csr_name" -o jsonpath='{.status.certificate}' \
  | base64 -d | sudo tee "$client_crt_path" > /dev/null

sudo chown "$user:$user" "$client_crt_path"

troubleshoot "Certificate installed for user '$user'"
echo "User '$user' is now fully configured and able to access the cluster."