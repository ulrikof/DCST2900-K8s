#!/bin/bash

set -e

# Parse arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --ip)
      TALOS_IP="$2"
      shift; shift
      ;;
    --worker-file)
      WORKER_FILE="$2"
      shift; shift
      ;;
    --controlplane-file)
      CONTROLPLANE_FILE="$2"
      shift; shift
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$TALOS_IP" ]]; then
  echo "NOT IP DNS RESOLUTION TALK TO ULRIK Usage: ./patch-image.sh --ip <talos-config-ip> [--worker-file <path>] [--controlplane-file <path>]"
  exit 1
fi

# Construct the image URLs
asdf=".$TALOS_IP.svc.cluster.local"
BASE_URL="https://factory.talos.dev/?arch=amd64&cmdline=talos.config%3Dhttp%3A%2F%2F${asdf}%2F"


# BASE_URL="https://factory.talos.dev/?arch=amd64&cmdline=talos.config%3Dhttp%3A%2F%2F${TALOS_IP}%2F"
ARGS="&cmdline-set=true&extensions=-&extensions=siderolabs%2Fiscsi-tools&extensions=siderolabs%2Futil-linux-tools&platform=metal&target=metal&version=1.9.5"

CONTROLPLANE_IMAGE=$(curl -s "${BASE_URL}controlplane.yaml${ARGS}" | grep -o 'https://[^"]*\.qcow2' | head -n1)
WORKER_IMAGE=$(curl -s "${BASE_URL}worker.yaml${ARGS}" | grep -o 'https://[^"]*\.qcow2' | head -n1)

echo "✅ Control Plane Image: $CONTROLPLANE_IMAGE"
echo "✅ Worker Image:        $WORKER_IMAGE"

# Only patch if files were provided
if [[ -n "$CONTROLPLANE_FILE" ]]; then
  echo "Patching $CONTROLPLANE_FILE..."
  sed -i "s|^\([[:space:]]*url:\).*|\1 $CONTROLPLANE_IMAGE|" "$CONTROLPLANE_FILE"
fi

if [[ -n "$WORKER_FILE" ]]; then
  echo "Patching $WORKER_FILE..."
  sed -i "s|^\([[:space:]]*url:\).*|\1 $WORKER_IMAGE|" "$WORKER_FILE"
fi

echo "✅ Done!"