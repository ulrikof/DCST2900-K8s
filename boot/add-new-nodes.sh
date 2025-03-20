#!/bin/bash

# Extract IP addresses from DHCP leases. Any unwanted ip-s in this range can be removed with grep -v
LEASE_IPS=$(grep '10.100.38' /var/lib/dhcp/dhcpd.leases | awk '{print $2}' | sort | uniq | grep -v '10.100.38.100')

# Extract IP addresses from Kubernetes nodes
KUBE_IPS=$(kubectl get nodes -o wide | grep '10.100.38' | awk '{print $6}' | sort | uniq)

# Find IPs present in leases but not in Kubernetes
NEW_NODES=$(comm -23 <(echo "$LEASE_IPS") <(echo "$KUBE_IPS"))

for ip in $NEW_NODES; do
    echo "Adding new node: $ip"
    talosctl apply-config --insecure -n "$ip" --file ~/talos/worker.yaml
done