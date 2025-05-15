### Starting state
# Apply starting resources
kubectl apply -f ns.yaml
kubectl apply -f pods.yaml

# Verify
kubectl get ns --show-labels | grep team=tenant

kubectl get pod -n tenant-a-1 -o custom-columns=NAME:.metadata.name,IP:.status.podIP
kubectl get pod -n tenant-b-1 -o custom-columns=NAME:.metadata.name,IP:.status.podIP


# Ensure they can ping eachother 
kubectl exec -n tenant-a-1 tenant-a-1-pod-1 -- ping -c 3 <tenant-a-1-pod-2-ip>
kubectl exec -n tenant-a-1 tenant-a-1-pod-1 -- ping -c 3 <tenant-b-1-pod-1-ip>


### Action
# Apply tenant network segregation
kubectl apply -f deny-all.yaml
kubectl apply -f allow-tenant.yaml 

# Veriy
kubectl get networkpolicy.projectcalico.org -n tenant-a-1
kubectl get networkpolicy.projectcalico.org -n tenant-b-1

### End state
# Verify IPs
kubectl get pod -n tenant-a-1 -o custom-columns=NAME:.metadata.name,IP:.status.podIP
kubectl get pod -n tenant-b-1 -o custom-columns=NAME:.metadata.name,IP:.status.podIP

# Ping should still work
kubectl exec -n tenant-a-1 tenant-a-1-pod-1 -- ping -c 3 <tenant-a-1-pod-2-ip>
kubectl exec -n tenant-a-1 tenant-a-1-pod-1 -- ping -c 3 <tenant-b-1-pod-1-ip>





