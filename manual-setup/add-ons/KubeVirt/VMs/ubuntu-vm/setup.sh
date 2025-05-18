

k apply -f ubuntu-vm.yaml

# Expose vm 
virtctl expose vmi vm-ubuntu-22 --name=ubuntu-ssh --port=20222 --target-port=22 --type=NodePort

# Find port
k get svc

vm-ssh        NodePort    10.127.226.82   <none>        20222:30851/TCP   18s


ssh ubuntu@10.100.38.101 -p 32023
