# Ensure a cluster is running with multiple worker nodes
kubectl get node

# Verify vm-a got affinity rule
grep -A 9 "affinity:" vm-a.yaml

# Create the VM
kubectl apply -f vm-a.yaml

# It should be unschedulable, check with
kubectl get vm

# Verify reason with
kubectl describe vm vm-a | grep -E "Message:|Printable Status:"

# Apply vm-b
kubectl apply -f vm-b.yaml

# Both VMs should now be running
kubectl get vm

# And on the same node
kubectl get vmi 