### Example guide on how network segmentation can be implemented, an more elaborate example of how this works is displayed in use-case-testing/uc-6.

# First, create two namaspaces:

kubectl apply -f namespaces.yaml

# Then, fill each namespace with two pods

kubectl apply -f pods.yaml

# As there are no policies by defualt, each pod should be able to ping eachother, for instance:

kubectl exec -n tenant-a pod-a1 -- ping -c 3 <tenant-b-pod-ip>

# Then, add a policy that denies all intra namespace communitcation to each namespace:

kubectl apply -f deny-other-ns.yaml

# Lastly, apply a a policy that allows intra namespace communication between namespaces in the same tenant:

kubectl apply -f allow-intra-tenant.yaml

### Verify

# Now this should not work:

kubectl exec -n tenant-a pod-a1 -- ping -c 3 <tenant-b-pod-ip>

# But this should work

kubectl exec -n tenant-a pod-a1 -- ping -c 3 <tenant-a-pod-a1-ip>

