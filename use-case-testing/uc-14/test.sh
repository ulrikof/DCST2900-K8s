### Start state

# No steps needed

### Action

# Apply webapp.yaml to the apps folder in the Git repository 

### End state

# After app has synced, verify that resource is there

kubeclt get all -n webapp

# Find external IP of service

kubectl get svc -n webapp

# Site should be reachable from the external ip

curl <lb-ip>