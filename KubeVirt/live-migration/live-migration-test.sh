# Live migration is not a standard feature in KubeVirt and needs to be enabled with a configmap:

kubectl apply -f live-migration-configmap.yaml 

# Create VM

kubectl apply -f vm.yaml

# console into the vm when its running

virtctl console live-migration-test

# Create a file in the vm for testing persistancy:

 touch persistant-file.txt

# Create a loop that can be read from outside the machine
 while true; do ( echo "HTTP/1.0 200 Ok"; echo; echo "Migration test" ) | nc -l -p 8080; done

# Expose vm ports:
virtctl expose vmi live-migration-test --name=testvm-ssh --port=22 --type=NodePort
virtctl expose vmi live-migration-test --name=testvm-http --port=8080 --type=NodePort

# Find exposes port:

kubectl get svc testvm-http -o jsonpath='{.spec.ports[0].nodePort}'

# Curl the vm (ip just needs to be one active node, does not matter which):

curl 192.168.0.50:31644

# Loop the curl the see if it is interupted by the migrate
while true; do curl 192.168.0.50:31644; sleep 0.5;  done;

# Initiate the migrate
virtctl migrate live-migration-test

# Check if the pods running the VM have moved to a new node:

kubectl get pods -o wide