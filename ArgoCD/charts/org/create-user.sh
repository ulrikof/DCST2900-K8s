#!/bin/bash
set -euo pipefail

# DEBUG LOGGER
troubleshoot() { echo "[### $1]"; }

# Uncomment next line when done debugging
# troubleshoot() { echo "[### $1]"; }

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

if [[ "$role" != "admin" && "$role" != "viewer" ]]; then
  echo "[!] Role must be 'admin' or 'viewer'"
  exit 1
fi

# Create Linux user
if id "$user" &>/dev/null; then
  troubleshoot "User '$user' already exists. Skipping useradd."
else
  troubleshoot "Creating Linux user '$user'"
  sudo useradd -m "$user"
  echo "$user:changeme" | sudo chpasswd
  sudo chage -d 0 "$user"
fi

# Copy SSH keys
if [[ -f "/home/$USER/.ssh/authorized_keys" ]]; then
  troubleshoot "Copying SSH authorized_keys to $user"
  sudo mkdir -p "/home/$user/.ssh"
  sudo cp "/home/$USER/.ssh/authorized_keys" "/home/$user/.ssh/authorized_keys"
  sudo chown -R "$user:$user" "/home/$user/.ssh"
  sudo chmod 700 "/home/$user/.ssh"
  sudo chmod 600 "/home/$user/.ssh/authorized_keys"
fi

# Generate key + CSR
user_dir="generated-users/$user"
mkdir -p "$user_dir"
cd "$user_dir"

troubleshoot "Generating TLS key and CSR"
openssl genrsa -out "$user.key" 2048
openssl req -new -key "$user.key" -out "$user.csr" -subj "/CN=$user/O=$namespace-$role"
csr_b64=$(base64 < "$user.csr" | tr -d '\n')

cat <<EOF > "$user.yaml"
- userName: $user
  csr: |
    $csr_b64
EOF

# Setup kubeconfig paths
home_kube="/home/$user/.kube"
troubleshoot "Creating .kube directory for $user"
sudo mkdir -p "$home_kube"

# Extract CA
troubleshoot "Extracting CA from kubeconfig"
kubectl config view --kubeconfig="$kubeconfig" --raw --flatten \
  -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' \
  | base64 -d | sudo tee "$home_kube/ca.crt" > /dev/null

# Copy certs
sudo cp "$user.key" "$home_kube/client.key"
sudo touch "$home_kube/client.crt"

# Extract API server
server_url=$(kubectl config view --kubeconfig="$kubeconfig" -o jsonpath='{.clusters[0].cluster.server}')
troubleshoot "API server is $server_url"

# Build kubeconfig
troubleshoot "Building kubeconfig for $user"
sudo tee "$home_kube/config" > /dev/null <<EOF
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

sudo chown -R "$user:$user" "$home_kube"
if sudo test -d "$home_kube"; then
  troubleshoot "Setting file permissions for $user"
  sudo find "$home_kube" -type f -exec chmod 600 {} \;
else
  troubleshoot "Expected kube dir $home_kube not found!"
fi

# Export KUBECONFIG on login
export_line="export KUBECONFIG=$home_kube/config"

# Check if the line already exists
if ! sudo grep -qxF "$export_line" "/home/$user/.bashrc"; then
  troubleshoot "Adding KUBECONFIG export to $user's .bashrc"
  echo "$export_line" | sudo tee -a "/home/$user/.bashrc" > /dev/null
  sudo chown "$user:$user" "/home/$user/.bashrc"
fi
sudo chown "$user:$user" "/home/$user/.bashrc"

# Done
echo ""
echo "User '$user' created. CSR and files are ready."
echo ""
echo "Paste this into your org's values.yaml:"
echo "  org.users.${role}Users:"
echo ""
echo "--------------------------- COPY BELOW -----------------------------"
cat "$user.yaml" | sed 's/^/      /'
echo "--------------------------- COPY ABOVE -----------------------------"
echo ""
echo "REMINDER: After ArgoCD syncs, run:"
echo "     ./approve-user.sh --user $user --kubeconfig $kubeconfig"