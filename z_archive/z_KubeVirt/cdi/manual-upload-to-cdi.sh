# Retrieve cirros image
wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

# Expose cdi-uploader:
kubectl apply -f cdi-uploadproxy-nodeport.yaml

# Upload image to dv
virtctl image-upload dv cirros-vm-disk-dv  \
  --volume-mode=filesystem \
  --size=1000Mi \
  --image-path=/home/dcst2900-user/KubeVirt/cdi/cirros-0.4.0-x86_64-disk.img \
  --uploadproxy-url=https://10.100.38.101:31001 \
  --insecure

# Create vm that uses that dv
kubectl apply -f cirros-vm.yaml 