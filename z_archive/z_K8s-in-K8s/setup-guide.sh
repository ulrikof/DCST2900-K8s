kubectl apply -f talos-config.yaml

kubectl get pod -n test -o wide

POD_IP=$(kubectl get pod talos-config-server -n test -o jsonpath='{.status.podIP}')
# Patch image with 
./patch-image.sh --ip $POD_IP --worker-file ./worker.yaml --controlplane-file ./control-plane.yaml

# Create talos machines
kubectl apply -f control-plane.yaml -f worker.yaml

# inspect logs:
kubectl logs -f talos-config-server -n test -c talos-bootstrap
kubectl logs -f talos-config-server -n test -c talos-http-server

# clean up
k delete -f talos-config.yaml -f control-plane.yaml -f worker.yaml 