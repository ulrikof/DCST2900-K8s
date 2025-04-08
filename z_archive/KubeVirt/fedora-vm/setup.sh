PUBKEY=`cat ~/.ssh/id_rsa.pub`
sed -i "s%ssh-rsa.*%$PUBKEY%" fedora-vm.yaml


k apply -f fedora-vm.yaml

# Expose vm 
virtctl expose vmi vm-fedora-40 --name=vm-ssh --port=20222 --target-port=22 --type=NodePort

# Find port
k get svc

vm-ssh        NodePort    10.127.226.82   <none>        20222:30851/TCP   18s


ssh fedora@10.100.38.101 -p 30851
