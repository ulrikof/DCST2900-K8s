### Start state

# First apply the app in a way such that Argo CD can read it

# Then link the app to the folder ./old

# Then let Argo CD deploy it, it can be verified with
kubectl -n metallb-system get deploy controller -o=jsonpath='{.spec.template.spec.containers[0].image}'; echo

# Output should be 
quay.io/metallb/controller:v0.14.8

### Action

# Then change the app to link to the folder ./new

### End state

# Then let Argo CD deploy it, it can be verified with
kubectl -n metallb-system get deploy controller -o=jsonpath='{.spec.template.spec.containers[0].image}'; echo

# Output should be 
quay.io/metallb/controller:v0.14.8