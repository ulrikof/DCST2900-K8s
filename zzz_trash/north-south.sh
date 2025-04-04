dir="/home/ubuntu"
$dir/create-org.sh --org north
$dir/create-org.sh --org south


(kubectl -n north-default delete pod test-pod-north-1 &> /dev/null) &
(kubectl -n north-default delete pod test-pod-north-2 &> /dev/null) & 
(kubectl -n south-default delete pod test-pod-south-1 &> /dev/null) & 
(kubectl -n south-default delete pod test-pod-south-2 &> /dev/null) & 

kubectl -n north-default run test-pod-north-1 --image=busybox --command -- sh -c "while true; do nc -lk -p 80; done"
kubectl -n north-default run test-pod-north-2 --image=busybox --command -- sh -c "while true; do nc -lk -p 80; done"
kubectl -n south-default run test-pod-south-1 --image=busybox --command -- sh -c "while true; do nc -lk -p 80; done"
kubectl -n south-default run test-pod-south-2 --image=busybox --command -- sh -c "while true; do nc -lk -p 80; done"

kubectl -n north-default delete svc test-svc-north-1
kubectl -n north-default delete svc test-svc-north-2
kubectl -n south-default delete svc test-svc-south-1
kubectl -n south-default delete svc test-svc-south-2

kubectl -n north-default expose pod test-pod-north-1 --port=80 --target-port=80 --name=test-svc-north-1
kubectl -n north-default expose pod test-pod-north-2 --port=80 --target-port=80 --name=test-svc-north-2
kubectl -n south-default expose pod test-pod-south-1 --port=80 --target-port=80 --name=test-svc-south-1
kubectl -n south-default expose pod test-pod-south-2 --port=80 --target-port=80 --name=test-svc-south-2

# (kubectl -n default delete pod test-pod-default-1 &> /dev/null) &
# (kubectl -n default delete pod test-pod-default-2 &> /dev/null) &
# kubectl -n default delete svc test-svc-default-1
# kubectl -n default delete svc test-svc-default-2

# kubectl -n default run test-pod-default-1 --image=busybox --command -- sh -c "while true; do nc -lk -p 80; done"
# kubectl -n default run test-pod-default-2 --image=busybox --command -- sh -c "while true; do nc -lk -p 80; done"
# kubectl -n default expose pod test-pod-default-1 --port=80 --target-port=80 --name=test-svc-default-1
# kubectl -n default expose pod test-pod-default-2 --port=80 --target-port=80 --name=test-svc-default-2

# kubectl calico delete networkpolicy default.allow-north-and-non-tenant -n north-default --allow-version-mismatch
# kubectl calico delete networkpolicy default.allow-south-and-non-tenant -n south-default --allow-version-mismatch

# kubectl calico apply -f deny-north-calico.yaml --allow-version-mismatch
# kubectl calico apply -f deny-south-calico.yaml --allow-version-mismatch

# kubectl calico apply -f allow-org-north.yaml --allow-version-mismatch
# kubectl calico apply -f deny-tenant-true-north.yaml --allow-version-mismatch

# kubectl calico get networkpolicies -A --allow-version-mismatch

# kubectl apply -f https://docs.projectcalico.org/manifests/canal.yaml
# kubectl delete -f https://docs.projectcalico.org/manifests/canal.yaml