#!/bin/bash

NAMESPACE="$1"

if [[ -z "$NAMESPACE" ]]; then
  echo "Usage: $0 <namespace>"
  exit 1
fi

CONFIG_URL="http://talos-config.${NAMESPACE}.svc.cluster.local/"
ENCODED_URL=$(python3 -c "import urllib.parse; print(urllib.parse.quote('talos.config=' + '$CONFIG_URL'))")

BASE_URL="https://factory.talos.dev/?arch=amd64&cmdline=${ENCODED_URL}"
ARGS="&cmdline-set=true&extensions=-&extensions=siderolabs%2Fiscsi-tools&extensions=siderolabs%2Futil-linux-tools&platform=metal&target=metal&version=1.9.5"

CONTROLPLANE_IMAGE=$(curl -s "${BASE_URL}controlplane.yaml${ARGS}" | grep -o 'https://[^"]*\.qcow2' | head -n1)
WORKER_IMAGE=$(curl -s "${BASE_URL}worker.yaml${ARGS}" | grep -o 'https://[^"]*\.qcow2' | head -n1)

echo "Control Plane Image: $CONTROLPLANE_IMAGE"
echo "Worker Image:        $WORKER_IMAGE"