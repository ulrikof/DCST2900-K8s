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
    --namespace)
      NAMESPACE="$2"
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

# Ensure either IP or Namespace is provided
if [[ -z "$TALOS_IP" && -z "$NAMESPACE" ]]; then
  echo "Usage: ./patch-image.sh [--ip <talos-config-ip> | --namespace <ns>] [--worker-file <path>] [--controlplane-file <path>]"
  exit 1
fi

# Construct the base URL
if [[ -n "$TALOS_IP" ]]; then
  CONFIG_URL="http://$TALOS_IP/"
elif [[ -n "$NAMESPACE" ]]; then
  CONFIG_URL="http://talos-config.${NAMESPACE}.svc.cluster.local/"
fi

# Build full BASE_URL
ENCODED_CONFIG_URL=$(python3 -c "import urllib.parse; print(urllib.parse.quote('talos.config=' + '$CONFIG_URL'))")
BASE_URL="https://factory.talos.dev/?arch=amd64&cmdline=${ENCODED_CONFIG_URL}"

# Add static args
ARGS="&cmdline-set=true&extensions=-&extensions=siderolabs%2Fiscsi-tools&extensions=siderolabs%2Futil-linux-tools&platform=metal&target=metal&version=1.9.5"

# Fetch image URLs
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