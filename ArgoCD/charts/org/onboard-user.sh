#!/bin/bash
set -euo pipefail

# 🛠️ Debug logger
troubleshoot() { echo "[🛠️  $1]"; }

user=""
role=""
namespace=""
kubeconfig=""
org=""



usage() {
  echo "Usage: $0 --user <username> --namespace <namespace> --role <admin|viewer> --kubeconfig <path> --org <org name>"
  exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) user="$2"; shift 2 ;;
    --namespace) namespace="$2"; shift 2 ;;
    --role) role="$2"; shift 2 ;;
    --kubeconfig) kubeconfig="$2"; shift 2 ;;
    --org) org="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

[[ -z "$user" || -z "$namespace" || -z "$role" || -z "$kubeconfig" || -z "$org" ]] && usage

REPO_PATH="$HOME/git/DCST2900-K8s/ArgoCD/apps/orgs/$org"
VALUES_FILE="$REPO_PATH/values.yaml"
APP_NAME="$org-org" #THIS IS ONLY IF FOLLOWING CONVENTION

#### Step 1: Run create-user.sh
troubleshoot "Running create-user.sh..."
./create-user.sh --user "$user" --namespace "$namespace" --role "$role" --kubeconfig "$kubeconfig"

#### Step 2: Inject CSR into values.yaml
yaml_snippet="generated-users/$user/$user.yaml"

if [[ ! -f "$yaml_snippet" ]]; then
  echo "[!] Expected CSR snippet at $yaml_snippet not found"
  exit 1
fi

troubleshoot "Injecting CSR into $VALUES_FILE under org.users.${role}Users..."


# Ensure structure exists and append new user
# Step 1: Make sure it's at least a list
tmpfile=$(mktemp)
troubleshoot "1"
yq e ".org.users.${role}Users = (.org.users.${role}Users // [])" "$VALUES_FILE" > "$tmpfile"
troubleshoot "2"
mv "$tmpfile" "$VALUES_FILE"

# Step 2: Append the CSR block
tmpfile=$(mktemp)
troubleshoot "3"
yq e ".org.users.${role}Users += load(\"$yaml_snippet\")" "$VALUES_FILE" > "$tmpfile"
troubleshoot "4"
mv "$tmpfile" "$VALUES_FILE"

troubleshoot "✅ Successfully injected CSR using safe file replacement"

#### Step 3: Commit and push
cd "$REPO_PATH"
if ! git config user.name &>/dev/null; then
  git config user.name "dcst2900-user"
fi

if ! git config user.email &>/dev/null; then
  git config user.email "dcst2900-user@whatever.local"
fi

# Commit changes
git add values.yaml
git commit -m "Add user $user to $role in $namespace"

# Push via SSH (uses ~/.ssh/id_rsa or id_ed25519 by default)
troubleshoot "Pushing changes to Git via SSH..."
git push origin main

#### Step 4: Sync ArgoCD app
troubleshoot "Triggering ArgoCD sync for $APP_NAME..."
argocd app sync "$APP_NAME"
argocd app sync app-of-apps


#### Step 5: Wait for ArgoCD sync
troubleshoot "Waiting for ArgoCD app '$APP_NAME' to be synced..."
kubectl wait application "$APP_NAME" \
  --for=jsonpath='{.status.sync.status}'=Synced \
  --timeout=60s -n argocd || {
    echo "[!] ArgoCD app did not sync in time. Exiting."
    exit 1
}

#### Step 6: Wait for CSR to appear
csr_name="${user}-csr"
troubleshoot "Waiting for CSR '$csr_name' to be created..."
until kubectl get csr "$csr_name" &>/dev/null; do
  sleep 1
done
troubleshoot "CSR $csr_name is now in the cluster"

#### Step 7: Approve CSR
./approve-user.sh --user "$user" --kubeconfig "$kubeconfig"

#### Done
echo ""
echo "✅ User '$user' fully onboarded and access granted!"