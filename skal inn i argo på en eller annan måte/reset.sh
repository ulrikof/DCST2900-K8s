#!/bin/bash

set -euo pipefail

usage() {
  echo "Usage: $0 --pattern <server-name-pattern>"
  exit 1
}

pattern=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --pattern)
      pattern="$2"
      shift 2
      ;;
    *)
      echo "Unknown arg: $1"
      usage
      ;;
  esac
done

[[ -z "$pattern" ]] && usage


dir="/home/ubuntu"
$dir/delete-vms.sh --pattern $pattern
$dir/provision-cluster.sh --count 2 --desc $pattern

# sleep 60
# kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/refs/heads/master/manifests/tigera-operator.yaml
# sleep 60
# kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/refs/heads/master/manifests/custom-resources.yaml
# sleep 60
# $dir/north-south.sh