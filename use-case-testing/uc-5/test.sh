### Starting state

# Apply starting resources
kubectl apply -f ns.yaml
kubectl apply -f pods.yaml

# Verify
kubectl get ns --show-labels | grep team=tenant-a

kubectl get pod -n tenant-a-1 -o custom-columns=NAME:.metadata.name,IP:.status.podIP
kubectl get pod -n tenant-a-2 -o custom-columns=NAME:.metadata.name,IP:.status.podIP


# Ensure they can ping eachother 
kubectl exec -n tenant-a-1 tenant-a-1-pod -- ping -c 3 <tenant-a-2-pod-ip>

### Action

# Apply tenant network segregation
kubectl apply -f deny-all.yaml
kubectl apply -f allow-tenant-a.yaml 

# Veriy
kubectl get networkpolicy.projectcalico.org -n tenant-a-1
kubectl get networkpolicy.projectcalico.org -n tenant-a-2

### End state
# Ping should still work
kubectl exec -n tenant-a-1 tenant-a-1-pod -- ping -c 3 <tenant-a-2-pod-ip>





