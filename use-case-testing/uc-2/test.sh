### Start state

# Apply pod
kubectl apply -f pod.yaml

# inspect number of pods

kubectl get pods

### Action

# Apply hpa to automatically scale the pod:

kubectl apply -f hpa.yaml

### End state

# Verify that number of pods has been scaled up

kubectl get pods
