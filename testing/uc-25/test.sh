# This test is done in a cluster

# Apply deployment
kubectl apply -f http-deployment.yaml

# Verify physical cluster
kubectl config current-context

# Verify deployment, pods and svc before start of test
kubectl get deployment

kubectl get pod

kubectl get svc

kubectl logs http-logger-<pod-id>
kubectl logs http-logger-<pod-id>

# Go into a cluster resource, either a VM or a pod which has access to the Kubernetes cluster network

# Curl the svc four times from this cluster resource
for i in {1..4}; do curl -o /dev/null <cluster-svc-ip>; done

# Check the logs, should be equall amount of requests in each.

kubectl logs http-logger-<pod-id>
kubectl logs http-logger-<pod-id>