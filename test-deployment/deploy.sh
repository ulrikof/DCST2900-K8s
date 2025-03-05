# Apply the files to the cluster
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml

# Expose it
kubectl expose deployment test-nginx --type=NodePort --port=80 --name=test-nginx

