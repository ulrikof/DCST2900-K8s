### Start state

# Create north-org and south-org. See ArgoCD/apps/orgs.

# For each org, add users to the virtual cluster through the user scripts.


### Action

# On physical management machine

# Log in as a user in north-org

# Try to access resources in north-org

kubectl get pods -n north-org

# Try to access resources in south-org

kubectl get pods -n north-org

### End state

# The user should have access to resources in north-org, as this is their org

# User should not have access to resources in south-org, as this it not their org 