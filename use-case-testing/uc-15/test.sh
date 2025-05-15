### Start state

# Apply webapp.yaml to the apps folder in the Git repository 

# After app has synced, verify that resource is there

kubeclt get all -n webapp

# Find external IP of service

kubectl get svc -n webapp

# Site should be reachable from the external ip

curl <lb-ip>

### Action

# First action is to change the HTML in use-case-testing/uc-15/webapp-chart/html/index.html to something else.

# Then update the appVersion in the chart in use-case-testing/uc-15/webapp-chart/Chart.yaml

### End state

# After app has synced, verify application has updated its content to the new html added in action

curl <lb-ip>