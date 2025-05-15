# The VPA must be installed in kubernetes
# Do
git clone https://github.com/kubernetes/autoscaler.git

# Then
cd autoscaler

# and execute this script

./vertical-pod-autoscaler/hack/vpa-up.sh

### Start state
# Apply vm pool and hpa

kubectl apply -f vm-pool.yaml
kubectl apply -f vpa.yaml

# Verify

kubectl get virtualmachinepools.pool.kubevirt.io

kubectl get vm

kubectl get dv

kubectl describe vmi | grep -A2 'Requests:' | head -n 3

kubectl get vpa

# Action

virtctl console vpa-test-pool-0
    yes > /dev/null &
    top -b -n 1

# End state

kubectl get vm

kubectl describe vmi | grep -A2 'Requests:' | head -n 3

kubectl describe vpa | grep -A9 compute

kubectl describe vpa | grep Events