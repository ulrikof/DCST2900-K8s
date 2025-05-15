# Ensure only one worker node is available

# Apply first VM
kubectl apply -f vm-a.yaml

# Verify it is running. If it is not running, wait until it is
kubectl get vm


# Verify vm-a got affinity rule
grep -A 9 "affinity:" vm-b.yaml

# Apply second VM
kubectl apply -f vm-b.yaml

# It should be unschedulable, check with
kubectl get vm

# Verify reason with
kubectl describe vm vm-b | grep -E "Message:|Printable Status:"