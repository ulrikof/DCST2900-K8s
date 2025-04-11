#!/bin/bash
set -euo pipefail

# 🛠️ DEBUG LOGGER
troubleshoot() { echo "[🛠️  $1]"; }

# Required args
user=""
namespace=""
role=""
kubeconfig=""

usage() {
  echo "Usage: $0 --user <username> --namespace <namespace> --role <admin|viewer> --kubeconfig <path>"
  exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) user="$2"; shift 2 ;;
    --namespace) namespace="$2"; shift 2 ;;
    --role) role="$2"; shift 2 ;;
    --kubeconfig) kubeconfig="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

[[ -z "$user" || -z "$namespace" || -z "$role" || -z "$kubeconfig" ]] && usage

# Validate role
if [[ "$role" != "admin" && "$role" != "viewer" ]]; then
  echo "[!] Role must be 'admin' or 'viewer'"
  exit 1
fi

# Create Linux user
if id "$user" &>/dev/null; then
  troubleshoot "User '$user' already exists. Skipping useradd."
else
  troubleshoot "Creating Linux user '$user'"
  useradd -m "$user"
  echo "$user:changeme" | chpasswd
  chage -d 0 "$user"
fi

# Copy SSH keys from admin
if [[ -f "/home/$USER/.ssh/authorized_keys" ]]; then
  mkdir -p "/home/$user/.ssh"
  cp "/home/$USER/.ssh/authorized_keys" "/home/$user/.ssh/authorized_keys"
  chown -R "$user:$user" "/home/$user/.ssh"
  chmod 700 "/home/$user/.ssh"
  chmod 600 "/home/$user/.ssh/authorized_keys"
  troubleshoot "SSH access copied for '$user'"
fi

# Setup dirs
user_dir="generated-users/$user"
mkdir -p "$user_dir"
cd "$user_dir"

# Generate TLS key + CSR
openssl genrsa -out "$user.key" 2048
openssl req -new -key "$user.key" -out "$user.csr" -subj "/CN=$user/O=$namespace-$role"
csr_b64=$(base64 < "$user.csr" | tr -d '\n')

# Save for GitOps
cat <<EOF > "$user.yaml"
- userName: $user
  csr: |
    $csr_b64
EOF

# Prepare kubeconfig
home_kube="/home/$user/.kube"
mkdir -p "$home_kube"
chown "$user:$user" "$home_kube"

# Extract CA from kubeconfig
kubectl config view --kubeconfig="$kubeconfig" --raw --flatten \
  -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' \
  | base64 -d > "$home_kube/ca.crt"

# Copy certs
cp "$user.key" "$home_kube/client.key"
touch "$home_kube/client.crt"

# Extract server address
server_url=$(kubectl config view --kubeconfig="$kubeconfig" -o jsonpath='{.clusters[0].cluster.server}')

# Build kubeconfig
cat <<EOF > "$home_kube/config"
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: $home_kube/ca.crt
    server: $server_url
  name: cluster
contexts:
- context:
    cluster: cluster
    namespace: $namespace
    user: $user
  name: ${user}-context
current-context: ${user}-context
users:
- name: $user
  user:
    client-certificate: $home_kube/client.crt
    client-key: $home_kube/client.key
EOF

chown -R "$user:$user" "$home_kube"
chmod 600 "$home_kube"/*

# Export config
grep -qxF "export KUBECONFIG=$home_kube/config" "/home/$user/.bashrc" \
  || echo "export KUBECONFIG=$home_kube/config" >> "/home/$user/.bashrc"

# Output snippet
echo ""
echo "✅ User '$user' created. CSR and files are ready."
echo ""
echo "📦 Paste this into your org's values.yaml:"
echo "  org.users.${role}Users:"
echo ""
echo "--------------------------- COPY BELOW -----------------------------"
cat "$user.yaml" | sed 's/^/      /'
echo "--------------------------- COPY ABOVE -----------------------------"
echo ""
echo "⚠️  REMINDER: After ArgoCD syncs, run:"
echo "     ./approve-user.sh --user $user --kubeconfig $kubeconfig"