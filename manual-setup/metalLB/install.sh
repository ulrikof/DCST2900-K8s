# Install manifest

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

# Apply lb config

kubectl apply -f config.yaml