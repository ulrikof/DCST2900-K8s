### See: https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart

### Install

# Install Tigera operator and CRDs
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.0/manifests/tigera-operator.yaml

# Install Calico
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.0/manifests/custom-resources.yaml

### Setup
# Calico comes with an UI that can be used to inspect and monitor cluster traffic.

# It can be reached by port-forwarding it:

kubectl port-forward -n calico-system service/whisker 8081:8081 &

# Then access it on this URL:

localhost:8081

### An example of how Calico can be used to enforce network segmentation can be seen under manual-setup/Calico/example
