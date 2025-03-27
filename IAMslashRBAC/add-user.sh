#!/bin/bash

set -euo pipefail

# default values
og_user="ubuntu"
namespace=""
password="pw"
super_admin="false"
kubeconfig_path=""
talosconfig_path=""
user_kubeconfig_path=""
cluster=""
server_ip=""
user=""
user_context=""
user_talosconfig_path=""
org=""

usage() {
  echo "Usage: $0 --user <username> --cluster <cluster-name> [--org <org-name>] [--password <pw>] [--og-user <admin-username>] [--namespace <ns>] [--kubeconfig-path <path>] [--talosconfig-path <path>] [--super-admin]"
  exit 1
}

# parse CLI args
while [[ $# -gt 0 ]]; do
  case $1 in
    --user)
      user="$2"
      shift 2
      ;;
    --password)
      password="$2"
      shift 2
      ;;
    --og-user)
      og_user="$2"
      shift 2
      ;;
    --cluster)
      cluster="$2"
      shift 2
      ;;
    --namespace)
      namespace="$2"
      shift 2
      ;;
    --kubeconfig-path)
      kubeconfig_path="$2"
      shift 2
      ;;
    --talosconfig-path)
      talosconfig_path="$2"
      shift 2
      ;;
    --org)
      org="$2"
      shift 2
      ;;
    --super-admin)
      super_admin="true"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# validate required params
[[ -z "$user" || -z "$cluster" ]] && usage
if [[ "$super_admin" != "true" && -z "$org" ]]; then
  echo "[!] You must provide --org <org-name> or use --super-admin"
  usage
  exit 1
fi

# populate other defaults
kubeconfig_path="${kubeconfig_path:-/home/$og_user/$cluster/kubeconfig}"
talosconfig_path="${talosconfig_path:-/home/$og_user/$cluster/talosconfig}"
user_kubeconfig_path="${kubeconfig_path/$og_user/$user}"
user_talosconfig_path="${talosconfig_path/$og_user/$user}"
user_context="${user}-context"
if [[ "$super_admin" == "true" ]]; then
  namespace="default"
else
  namespace="${namespace:-${org}-default}"
fi
server_ip=$(talosctl --talosconfig $talosconfig_path get info \
  | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ { print $1 }')

# export configs for later use
export KUBECONFIG="$kubeconfig_path"
export TALOSCONFIG="$talosconfig_path"

if id "$user" &>/dev/null; then
  echo "[!] User '$user' already exists, skipping creation."
else
  echo "[+] Creating user '$user'"
  useradd -m "$user"
  echo "$user:$password" | chpasswd
  chage -d 0 "$user"
fi

echo "[+] Generating TLS assets for $user"
mkdir -p /home/$user/.kube/certs && cd /home/$user/.kube/certs
openssl genrsa -out $user.key 2048
group=""
if [[ "$super_admin" == "true" ]]; then
  group="platform-admins"
else
  group="${org}-admins"
fi
openssl req -new -key $user.key -out $user.csr -subj "/CN=$user/O=$group"
cat $user.csr | base64 | tr -d '\n' > csr.b64

cat <<EOF > $user-csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $user-user
spec:
  groups:
  - system:authenticated
  request: $(cat csr.b64)
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF

echo "[+] Submitting and approving CSR for $user"
kubectl apply -f $user-csr.yaml || true
kubectl certificate approve $user-user || true

# Wait for cert to be issued
while [[ $(kubectl get csr $user-user -o jsonpath='{.status.certificate}') == "" ]]; do
  echo "[.] Waiting for certificate to be available..."
  sleep 1
done
kubectl get csr $user-user -o jsonpath='{.status.certificate}' | base64 -d > /home/$user/.kube/certs/$user.crt

echo "[+] Extracting cluster CA from kubeconfig"
kubectl config view --kubeconfig=$kubeconfig_path --raw --flatten \
  -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > /home/$user/.kube/ca.crt

echo "[+] Building kubeconfig for $user"
kubectl config --kubeconfig=$user_kubeconfig_path set-cluster $cluster \
  --server=https://$server_ip:6443 \
  --certificate-authority=/home/$user/.kube/ca.crt \
  --embed-certs=true

kubectl config --kubeconfig=$user_kubeconfig_path set-credentials $user \
  --client-certificate=/home/$user/.kube/certs/$user.crt \
  --client-key=/home/$user/.kube/certs/$user.key \
  --embed-certs=true

kubectl config --kubeconfig=$user_kubeconfig_path set-context $user_context \
  --cluster=$cluster \
  --namespace=$namespace \
  --user=$user

kubectl config --kubeconfig=$user_kubeconfig_path use-context $user_context

if [[ "$super_admin" == "true" ]]; then
  echo "[+] Granting cluster-admin privileges to group 'platform-admins'"
  kubectl create clusterrolebinding platform-admins \
    --clusterrole=cluster-admin \
    --group=platform-admins || echo "[i] ClusterRoleBinding 'platform-admins' already exists"
fi

echo "[+] Fixing permissions and setting KUBECONFIG env"
chown -R $user:$user /home/$user/.kube
chown $user:$user "$user_kubeconfig_path"
grep -qxF "export KUBECONFIG=$user_kubeconfig_path" /home/$user/.bashrc || echo "export KUBECONFIG=$user_kubeconfig_path" >> /home/$user/.bashrc
chown $user:$user /home/$user/.bashrc

#FOR SSH ACCESS: POC ONLY!
mkdir -p /home/$user/.ssh
cp /home/$og_user/.ssh/authorized_keys /home/$user/.ssh/authorized_keys
chown -R $user:$user /home/$user/.ssh
sudo chmod 700 /home/$user/.ssh
sudo chmod 600 /home/$user/.ssh/authorized_keys


echo "[+] Done. User '$user' created and kubeconfig at: $user_kubeconfig_path"