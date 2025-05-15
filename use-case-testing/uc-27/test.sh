# This test is done in a virtual cluster

# Apply deployment
kubectl apply -f http-deployment.yaml

# Verify virtual cluster
kubectl config current-context

# Verify deployment, pods and svc before start of test
kubectl get deployment

kubectl get pod

kubectl get svc

kubectl logs http-logger-<pod-id>
kubectl logs http-logger-<pod-id>

# Curl the svc four times
for i in {1..4}; do curl -o /dev/null <external-svc-ip>; done

# Check the logs, should be equall amount of requests in each.

kubectl logs http-logger-<pod-id>
kubectl logs http-logger-<pod-id>