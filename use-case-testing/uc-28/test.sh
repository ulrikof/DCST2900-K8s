### Functionality for this test does not exist, so there has not been created a real test. A draft how a test can be viewed under:


### Start state

# Check if you have cluster access, this should not be the case

kubectl get node

### Action state

# Login with IDP

### End state

# Verify cluster access

kubectl get node

# Verify appropriate permission

kubectl get all -n <allowed-ns>

kubectl get all -n <not-allowed-ns>

