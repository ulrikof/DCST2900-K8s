# Followed this guide: https://kubevirt.io/labs/kubernetes/lab1

### 1. Download a VM manifest (This uses a container disk, which means storage is not persistant)

wget https://kubevirt.io/labs/manifests/vm.yaml

### 2. Apply it to the cluster

kubectl apply -f https://kubevirt.io/labs/manifests/vm.yaml

### 3. Manage the machine

# 3.1 See the VMs 
kubectl get vms

# 3.2 Start the VM
virtctl start testvm

# 3.3 Check if it has been started
kubectl get vms

# 3.4 Get the VM instance. The VM instance only exists when the VM is running, and is deleted when it is of
kubectl get vmis

# 3.5 access the vm
virtctl console testvm

# Escape sequence should be: ctrl+]

# 3.6 Stop the VM
virtctl stop testvm