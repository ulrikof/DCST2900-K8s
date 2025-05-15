# Apply the vm to the cluster
kubectl apply -f vm.yaml

# Verify DV is up
kubectl get dv

# Verify it is running
kubectl get vmi

# Console into the VM
virtctl console pv-vm

# Create file
touch persistent-file.txt

# Verify
ls

# Delete the VMI
kubectl delete vmi pv-vm

# New VMi should be created automatically
kubectl get vmi

# Console into new VM
virtctl console pv-vm

# Check if file created earlier is present
ls
