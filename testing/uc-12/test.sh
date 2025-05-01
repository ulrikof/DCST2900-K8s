### Initial state
# An example chart can be found under ./ubuntu-vm

# Action
# Deploy the apps ./ubuntu-vm-a.yaml and ./ubuntu-vm-b.yaml through Argo CD
# Argo CD then automatically creates them

### End state

# Verify:

# The two vm-s exist
kubectl get vm

# They have their own disk and correct storage:
kubectl get dv
kubectl get pvc -o custom-columns=NAME:.metadata.name,CAPACITY:.status.capacity.storage
# Ensure correct external-ips:
kubectl get svc vm-a-ssh vm-b-ssh

# Memory is correct:
kubectl describe vm vm-a | grep Memory
kubectl describe vm vm-b | grep Memory

# CPU cores is correct:
kubectl describe vm vm-a | grep Cores
kubectl describe vm vm-b | grep Cores