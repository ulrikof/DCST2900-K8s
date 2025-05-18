This test relies on two apps, see ./apps.

The test-deployment-app only purpose is to see if a pod is scheduled onto tainted nodes, and can therefore be swapped out of needed.

# 1. Label and taint nodes 
```sh
kubectl label node talos-worker-1 dedicated=talos
kubectl label node talos-worker-2 dedicated=talos
kubectl label node talos-worker-3 dedicated=talos

kubectl taint node talos-worker-1 dedicated=talos:NoSchedule
kubectl taint node talos-worker-2 dedicated=talos:NoSchedule
kubectl taint node talos-worker-3 dedicated=talos:NoSchedule
```
# 2. Add apps to argo

# 3. Verify
Check if the talos machines run on only the correct nodes (talos-worker-1/2/3):
```sh
kubectl get vmi -n k8s-in-k8s 
```

Check if the pods are running on all other nodes:
```sh
kubectl get pod -n test-deployment -o wide
```