#!/bin/bash

set -euo pipefail

# Required args
user=""
org_name=""
org_ns=""
role=""


usage() {
  echo "Usage: $0 --user <username> --org <org-name> --namespace <org-namespace> --role <admin|viewer>"
  exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --user)
      user="$2"; shift 2 ;;
    --org)
      org_name="$2"; shift 2 ;;
    --namespace)
      org_ns="$2"; shift 2 ;;
    --role)
      role="$2"; shift 2 ;;
    *)
      echo "Unknown option: $1"; usage ;;
  esac
done

# Validate args
if [[ -z "$user" || -z "$org_name" || -z "$org_ns" || -z "$role" ]]; then
  usage
fi

if [[ "$role" != "admin" && "$role" != "viewer" ]]; then
  echo "[!] Role must be 'admin' or 'viewer'"
  exit 1
fi

# Create the Linux user if it doesn't exist
if id "$user" &>/dev/null; then
  echo "[!] Linux user '$user' already exists, skipping creation."
else
  echo "[+] Creating Linux user '$user'"
  useradd -m "$user"
  echo "$user:changeme" | chpasswd
  chage -d 0 "$user"  # Force password change on first login
fi

# Optional: copy SSH authorized_keys from current user
if [[ -f "/home/$USER/.ssh/authorized_keys" ]]; then
  mkdir -p /home/$user/.ssh
  cp /home/$USER/.ssh/authorized_keys /home/$user/.ssh/authorized_keys
  chown -R $user:$user /home/$user/.ssh
  chmod 700 /home/$user/.ssh
  chmod 600 /home/$user/.ssh/authorized_keys
  echo "[+] SSH access granted to '$user' via authorized_keys"
fi

# Setup paths
user_dir="generated-users/$user"
mkdir -p "$user_dir"
cd "$user_dir"

# Generate private key & CSR
openssl genrsa -out "$user.key" 2048
openssl req -new -key "$user.key" -out "$user.csr" -subj "/CN=$user/O=$org_name-$role"

# Base64 encode the CSR
csr_b64=$(base64 < "$user.csr" | tr -d '\n')

# Save GitOps-friendly snippet
cat <<EOF > $user.yaml
- userName: $user
  csr: |
    $csr_b64
EOF

# Copy certs and kubeconfig to user home
home_kube_dir="/home/$user/.kube"
mkdir -p "$home_kube_dir"

# Simulate CA cert (replace this path if using real CA cert)
cp "/etc/kubernetes/pki/ca.crt" "$home_kube_dir/ca.crt" 2>/dev/null || touch "$home_kube_dir/ca.crt"

# Copy cert/key to user kube dir
cp "$user.key" "$home_kube_dir/client.key"
touch "$home_kube_dir/client.crt"  # Placeholder — Argo will approve and install this

# Create kubeconfig
server_ip=$(talosctl --talosconfig $talosconfig_path get info \
  | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ { print $1 }')
cat <<EOF > "$home_kube_dir/config"
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: $home_kube_dir/ca.crt
    server: https://$server_ip:6443
  name: local-cluster
contexts:
- context:
    cluster: local-cluster
    namespace: $org_ns
    user: $user
  name: ${user}-context
current-context: ${user}-context
users:
- name: $user
  user:
    client-certificate: $home_kube_dir/client.crt
    client-key: $home_kube_dir/client.key
EOF

# Fix permissions
chown -R $user:$user "/home/$user/.kube"
chmod 600 /home/$user/.kube/*

# Set env var for login shells
grep -qxF "export KUBECONFIG=/home/$user/.kube/config" /home/$user/.bashrc || \
  echo "export KUBECONFIG=/home/$user/.kube/config" >> /home/$user/.bashrc

chown $user:$user /home/$user/.bashrc

# Output GitOps snippet
echo ""
echo "# Generated user cert request for '$user'"
echo ""
echo "# Paste the following into your org values.yaml under:"
echo "  org.users.${role}Users:"
echo ""
echo "---------------------------- COPY BELOW -----------------------------"
cat $user.yaml | sed 's/^/      /'
echo "---------------------------- COPY ABOVE -----------------------------"
echo ""
echo "# Done. TLS assets in: $user_dir"
echo "# Kubeconfig set up for user: $user"