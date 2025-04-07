# Apply dv
kubectl apply -f cirros-dv-url.yaml

# verify
kubectl get dv

# Create vm
kubectl apply -f cirros-vm-dv-url.yaml