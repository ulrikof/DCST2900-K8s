#!/bin/bash

set -euo pipefail

# 💬 Debug logging function
troubleshoot() {
  echo "[🛠️  troubleshoot] $1"
}

# Required args
user=""
org_name=""
org_ns=""
role=""
talosconfig=""

usage() {
  if [[ -z $talosconfig ]]; then
  echo "[!] talosconfig is not set — please use --talosconfig flag"
  echo "[!] You can use \$TALOSCONFIG if this is exported in your ~/.bashrc"

  fi
  if [[ "$role" != "admin" && "$role" != "viewer" ]]; then
  echo "[!] Role must be 'admin' or 'viewer'"
  fi
  echo "Usage: $0 --user <username> --org <org-name> --namespace <org-namespace> --role <admin|viewer> --talosconfig <\$TALOSCONFIG>"
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
    --talosconfig)
      talosconfig="$2"; shift 2 ;;
    *)
      echo "Unknown option: $1"; usage ;;
  esac
done

# Validate args
if [[ -z "$user" || -z "$org_name" || -z "$org_ns" || -z "$role" ||  -z "$talosconfig" ]]; then
  usage
fi

if [[ "$role" != "admin" && "$role" != "viewer" ]]; then
  usage
fi

troubleshoot "Starting user creation for '$user' in namespace '$org_ns' with role '$role'"

# Create the Linux user if it doesn't exist
if id "$user" &>/dev/null; then
  troubleshoot "Linux user '$user' already exists, skipping useradd"
  echo "[!] Linux user '$user' already exists, skipping creation."
else
  echo "[+] Creating Linux user '$user'"
  useradd -m "$user"
  echo "$user:changeme" | chpasswd
  chage -d 0 "$user"
  troubleshoot "Linux user '$user' created and password set"
fi

# Optional: copy SSH authorized_keys from current user
if [[ -f "/home/$USER/.ssh/authorized_keys" ]]; then
  troubleshoot "Copying SSH keys from $USER to $user"
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
troubleshoot "Working in $user_dir"

# Generate private key & CSR
troubleshoot "Generating TLS private key"
openssl genrsa -out "$user.key" 2048
troubleshoot "Creating CSR for CN=$user, O=$org_name-$role"
openssl req -new -key "$user.key" -out "$user.csr" -subj "/CN=$user/O=$org_name-$role"

# Base64 encode the CSR
csr_b64=$(base64 < "$user.csr" | tr -d '\n')

# Save GitOps-friendly snippet
cat <<EOF > $user.yaml
- userName: $user
  csr: |
    $csr_b64
EOF
troubleshoot "CSR base64 written to $user.yaml"

# Copy certs and kubeconfig to user home
home_kube_dir="/home/$user/.kube"
mkdir -p "$home_kube_dir"

troubleshoot "Copying CA cert"
cp "/etc/kubernetes/pki/ca.crt" "$home_kube_dir/ca.crt" 2>/dev/null || touch "$home_kube_dir/ca.crt"

troubleshoot "Placing client key in $home_kube_dir"
cp "$user.key" "$home_kube_dir/client.key"
touch "$home_kube_dir/client.crt"  # Placeholder — will be replaced once CSR is approved

# Create kubeconfig
troubleshoot "Fetching API server IP from Talos"
server_ip=$(talosctl --talosconfig $talosconfig get info | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ { print $1 }')
troubleshoot "Using server IP: $server_ip"

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

troubleshoot "Kubeconfig written to $home_kube_dir/config"

# Fix permissions
chown -R $user:$user "/home/$user/.kube"
chmod 600 /home/$user/.kube/*

# Set env var for login shells
if ! grep -q "KUBECONFIG=/home/$user/.kube/config" /home/$user/.bashrc; then
  echo "export KUBECONFIG=/home/$user/.kube/config" >> /home/$user/.bashrc
  troubleshoot "KUBECONFIG export added to /home/$user/.bashrc"
fi

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