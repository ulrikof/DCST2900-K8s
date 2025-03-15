wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

kubectl apply -f cdi-uploadproxy-nodeport.yaml

virtctl image-upload pvc cirros-vm-disk  \
  --size=1000Mi \
  --image-path=/home/ubuntu/KubeVirt/cdi/cirros-0.4.0-x86_64-disk.img \
  --uploadproxy-url=https://192.168.0.50:31001 \
  --insecure

kubectl apply -f cirros-vm.yaml