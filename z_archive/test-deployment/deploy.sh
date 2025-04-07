# Apply the files to the cluster
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml

# Expose it with random external port
kubectl expose deployment test-nginx --type=NodePort --port=80 --name=test-nginx

# or with bound port 
kubectl apply -f expose.yaml

