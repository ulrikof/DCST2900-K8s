#!/bin/bash

set -euo pipefail

usage() {
  echo "Usage: $0 --count <number-of-nodes> --desc <description>"
  exit 1
}

count=""
desc=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --count)
      count="$2"
      shift 2
      ;;
    --desc)
      desc="$2"
      shift 2
      ;;
    *)
      echo "Unknown arg: $1"
      usage
      ;;
  esac
done

# Enforce required flags
[[ -z "$count" || -z "$desc" ]] && usage

flavor="e2383865-a614-4dfe-97c6-b5d6e3369c7c" #gx1.2c2r
# flavor="2295f296-474a-4249-9774-ea442b145700" #gx1.1c2r
network="f5493ccb-1084-4d75-9b1c-2a483bbeae17" #"Kubernetes"
image="9944a3d8-3dc1-4266-bc14-1a8aa6e035ae" #TalosOS-Extended
name="$desc-talos"
cluster_name="$desc-cluster"
port="6443"
controlplane_count=3
controlplane_name=""

openstack server create \
    --flavor $flavor \
    --network $network \
    --image $image \
    --min $count \
    --max $count \
    $name

if [ "$count" -eq 1 ]; then
    controlplane_name="$name"
else
    controlplane_name="$name-1"
fi

timeout=300 # seconds
interval=10
elapsed=0
controlplane_ip=""

while true; do
    controlplane_ip=$(openstack server list \
        | grep "$controlplane_name" \
        | awk -F'|' '{print $5}' \
        | sed -E 's/.*=([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    if [[ "$controlplane_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        break
    fi
    if [ "$elapsed" -ge "$timeout" ]; then
        echo "Timeout waiting for IP address of $controlplane_name" >&2
        exit 1
    fi
    echo "... waiting for ip on $controlplane_name"
    sleep "$interval"
    elapsed=$((elapsed + interval))
done

echo "... gen config"

talosctl gen config $cluster_name https://$controlplane_ip:$port
mkdir -p ./$cluster_name/
mv -v talosconfig "./$cluster_name/" 2>/dev/null
mv -v controlplane.yaml "./$cluster_name/" 2>/dev/null
mv -v worker.yaml "./$cluster_name/" 2>/dev/null

talosconfig="$(pwd)/$cluster_name/talosconfig"
talosctl --talosconfig $talosconfig config endpoint $controlplane_ip
talosctl --talosconfig $talosconfig config node $controlplane_ip
echo "... Making $controlplane_ip THE control plane"

timeout=60
interval=2
elapsed=0

echo "Waiting for $controlplane_ip:50000 to become available..."

while ! nc -z "$controlplane_ip" "50000" 2>/dev/null; do
    sleep "$interval"
    elapsed=$((elapsed + interval))
  
    if [ "$elapsed" -ge "$timeout" ]; then
        echo "Timeout waiting for $controlplane_ip:50000"
        exit 1
    fi
done
talosctl --talosconfig $talosconfig apply-config --insecure --nodes $controlplane_ip --file ./$cluster_name/controlplane.yaml


ips=$(openstack server list \
    | grep "$name" \
    | awk -F'|' '{print $5}' \
    | sed -E 's/.*=([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+).*/\1/')

count=1
for ip in $ips; do
    if [ "$ip" == "$controlplane_ip" ]; then
        echo "Skipping control plane IP: $ip"
        continue
    fi
    if [[ "$count" -lt "$controlplane_count" ]]; then
        echo "... Making $ip a control plane"
        timeout=60
        interval=2
        elapsed=0
        echo "Waiting for $ip:50000 to become available..."
        while ! nc -z "$ip" "50000" 2>/dev/null; do
            sleep "$interval"
            elapsed=$((elapsed + interval))
            if [ "$elapsed" -ge "$timeout" ]; then
                echo "Timeout waiting for $ip:50000"
                exit 1
            fi
        done
        talosctl --talosconfig $talosconfig apply-config --insecure --nodes $ip --file ./$cluster_name/controlplane.yaml
        count=$((count + 1))
    else
        echo "... Making $ip a worker"
        timeout=60
        interval=2
        elapsed=0
        echo "Waiting for $ip:50000 to become available..."
        while ! nc -z "$ip" "50000" 2>/dev/null; do
            sleep "$interval"
            elapsed=$((elapsed + interval))
            if [ "$elapsed" -ge "$timeout" ]; then
                echo "Timeout waiting for $ip:50000t"
                exit 1
            fi
        done
        talosctl --talosconfig $talosconfig apply-config --insecure --nodes $ip --file ./$cluster_name/worker.yaml
    fi
done

read -p "Do you want to make this the main cluster (update .bashrc)? [y/N]: " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
  echo "Exporting TALOSCONFIG and KUBECONFIG to ~/.bashrc"

  talos_export="export TALOSCONFIG=\"$talosconfig\""
  kube_export="export KUBECONFIG=\"./$cluster_name/kubeconfig\""

  # Prevent duplicate entries
  grep -qxF "$talos_export" ~/.bashrc || echo "$talos_export" >> ~/.bashrc
  grep -qxF "$kube_export" ~/.bashrc || echo "$kube_export" >> ~/.bashrc

  echo "✅ ~/.bashrc updated. Run 'source ~/.bashrc' or restart your shell to apply."
else
  echo "Skipping .bashrc update."
fi

talosctl --talosconfig $talosconfig bootstrap --nodes $controlplane_ip
talosctl --talosconfig $talosconfig kubeconfig ./$cluster_name/ --nodes $controlplane_ip

# kubectl apply -f https://docs.projectcalico.org/manifests/canal.yaml
