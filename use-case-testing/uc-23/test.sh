### Start state

# Create a VM in the cluster, the simplest way to do this is to add the ubunut-app.yaml in the apps folder in the git repo

# Also add a busybox which includes a service:

kubectl apply -f busybox.yaml

### Action

## From the ubuntu VM created above

# Try to communicate with pod over IPv4

traceroute north-busybox-1-svc

# Try to communicate with pod over IPv6

traceroute6 north-busybox-1-svc

### End state

# Both should be successfull
