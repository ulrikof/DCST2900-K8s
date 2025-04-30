# Live migration needs to be enabled, this can be done with
kubectl apply -f live-migration-configmap.yaml

# Add the VM to the cluster
kubectl apply -f vm.yaml

# Check which node the VM is running
kubectl get vmi

### Enter the VM
virtctl console live-migration-test

# Run the following command
while true; do ( echo "HTTP/1.0 200 Ok"; echo; echo "Migration test" ) | nc -l -p 8080; done

### Exit the VM

# Expose the VM 
virtctl expose vmi live-migration-test --name=migration --port=8080 --type=NodePort

# Find the port which the VM is exposed on
kubectl get svc migration

# Get a node IP, does not matter which
kubectl get node -o wide

# Send continous requests to the webserver on the VM
while true; do curl <node-ip>:<svc-port>; sleep 0.1;  done;

### In another terminal

#Initiate the migrate command
virtctl migrate live-migration-test

# Check for interruptions in the continous requests

# Check if VMI has moved
kubectl get vmi

# OR:
kubectl get pod