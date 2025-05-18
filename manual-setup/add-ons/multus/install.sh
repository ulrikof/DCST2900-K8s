### See: https://www.talos.dev/v1.10/kubernetes-guides/network/multus/


### Setup

# Ensure that the workers contain the patch described in manual-setup/multus/correct-multus-daemonset.yaml

# Apply Multus:
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml

# Correct the daemonset, see: correct-multus-daemonset.yaml

# Apply nad.yaml, correct for your network


### Test that multus works:

# Create ubuntu-vm.yaml, ensure that the ssh-key matches your public key

kubectl apply -f ubuntu-vm.yaml

# Wait until vm is up

kubectl get vm test

kubectl get vmi test

# When VM is up, check if multus has assigned it with an interface:

kubectl describe vmi test

# Expose the VM

virtctl expose vmi test  --name=ubuntu-ssh --port=20222 --target-port=22 --type=NodePort

# Find port

kubectl get svc

# ssh into machine

ssh ubuntu@<any-node-ip> -p <svc-port>

# There should be two interfaces (three if counting loopback), the second one is the multus one, and it should be down by default

ip a

# Enable the multus interface and ask it for a dhcp

sudo ip link set enp2s0 up

sudo dhclient enp2s0

# Check if interface is up with the same IP address that Kubernetes has assigned it from the NAD (it can be checked with kubectl describe vmi test)

ip a


### There also exists a testing virtual cluster with nodes using multus in manual-setup/multus/v-cluster-resources
