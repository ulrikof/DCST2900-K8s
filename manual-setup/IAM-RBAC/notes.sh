# GOOGLE AUTH NOTES/WORKFLOW

# locally:
manager_ip="10.212.174.248"
ssh ubuntu@$manager_ip

# in manager
cp_ip="192.168.0.124"
ssh ubuntu@$cp_ip

# locally:
# sudo snap install go --classic
brew install go
go install github.com/google/oauth2l@latest
shell_rc=".zshrc"
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/$shell_rc
source ~/$shell_rc

client_id="217260963394-bvhfbc2ticlo4i0s9t0h0vvja0r13spk.apps.googleusercontent.com"
client_secret="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"


path_to_client_id="client_secret.json"
oauth2l fetch --json $path_to_client_id --scope="openid email profile"



# Run everything locally??







sudo su
og_user="ubuntu"
user="jonas"
password="pw"
kubeconfig_path="/home/$og_user/kubeconfig"
talosconfig_path="/home/$og_user/talosconfig"
cluster="K8s"
server_ip="192.168.0.108"
user_kubeconfig_path="${kubeconfig_path/$og_user/$user}"
user_talosconfig_path="${talosconfig_path/$og_user/$user}"
namespace="default"
export KUBECONFIG=$kubeconfig_path
export TALOSCONFIG=$talosconfig_path
useradd -m "$user"
echo "$user:$password" | chpasswd
# force pw change first login
chage -d 0 "$user"
#pw = pw
mkdir -p /home/$user/.kube/certs && cd /home/$user/.kube/certs
# gen key and CSR (certificate signing request)
openssl genrsa -out $user.key 2048
openssl req -new -key $user.key -out $user.csr -subj "/CN=$user/O=tenant-team"
# encode base64 (talos needs it)
cat $user.csr | base64 | tr -d '\n' > csr.b64
# write to yaml for kubernetes
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

kubectl apply -f $user-csr.yaml
kubectl certificate approve $user-user
# loop for waiting
while [[ $(kubectl get csr $user-user -o jsonpath='{.status.certificate}') == "" ]]; do
  echo "Waiting for certificate to be available..."
  sleep 1
done
kubectl get csr $user-user -o jsonpath='{.status.certificate}' | base64 -d > /home/$user/.kube/certs/$user.crt
# resolves to 1 if user is created and added. Use for logic?
kubectl get csr $user-user -o yaml | grep "status:" | grep "True" | wc -l
# resolves to 3 if all certs are generated
ls -l /home/$user/.kube/certs/ | grep "$user\." | wc -l

kubectl config view --raw --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > /home/$user/.kube/ca.crt
# should resolve to 1
ls -la /home/$user/.kube | grep ca.crt | wc -l

# Create the kubeconfig for user
kubectl config --kubeconfig=$user_kubeconfig_path set-cluster $cluster \
  --server=https://$server_ip:6443 \
  --certificate-authority=/home/$user/.kube/ca.crt \
  --embed-certs=true

kubectl config --kubeconfig=$user_kubeconfig_path set-credentials $user \
  --client-certificate=/home/$user/.kube/certs/$user.crt \
  --client-key=/home/$user/.kube/certs/$user.key \
  --embed-certs=true

kubectl config --kubeconfig=$user_kubeconfig_path set-context $user-context \
  --cluster=$cluster \
  --namespace=$namespace \
  --user=$user

kubectl config --kubeconfig=$user_kubeconfig_path use-context $user-context

chown -R $user:$user /home/$user/.kube
# since config isnt necessarily in .kube
chown -R $user:$user "$user_kubeconfig_path"
echo "export KUBECONFIG=$user_kubeconfig_path" >> /home/$user/.bashrc
chown $user:$user /home/$user/.bashrc

user="aksel"
kubectl create clusterrolebinding $user-cluster-admin \
  --clusterrole=cluster-admin \
  --user=$user





kubectl run test-pod --image=busybox --command -- sleep 3600