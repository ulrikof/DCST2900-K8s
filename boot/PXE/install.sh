### On each server

# 1. Select PXE Boot on the machine (either config the iDRAC or just hit F12 in the console when it the machine starts)

# 2. Wait for PXE, then wait for menu to pop up. (you may have to specify interface and confirm ip config)

# 3. Go to Distributions and then linux network installs and then go down to talos. Then just press begin talos install

# 4. Wait for Talos to boot, eventually you will get to summary screen. Here you should set the host name (inside the F3 menu)

# Note: Talos only runs in RAM until machineconfig is sent to the server, so it is not actually installed when it boots for the first time.

### On manager

# 1. Install packages

# 1.1 instal kubectl

sudo snap install kubectl --classic

kubectl version --client

# 1.2 Install talosctl:

curl -sL https://talos.dev/install | sh


# 2. Generate and set up config files

# 2.1 generate config files (ip needs to be the ip of a control plane node (or lb infront of control plane)):

talosctl gen config K8s https://10.100.38.20:6443 --config-patch @all-patch.yaml --config-patch-worker @worker-patch.yaml

# 2.2 set default endpoint and node in talosconfig file. should be one of the control plane nodes (not LB!) :

talosctl --talosconfig talosconfig config endpoint 10.100.38.101
talosctl --talosconfig talosconfig config node 10.100.38.101

# 2.3 Export talosconfig file (this could be added to bashrc to avoid having to this too often)

export TALOSCONFIG=~/talos/talosconfig

# 2.4 Our version of Talos needs some extra configuration to the machine config files. This is automatically added by the patches in the gen config command above and does not need to be added manually:

# 2.4.1 Extra config needed in both control-plane.yaml and worker.yaml

# These subnets can not overlap with any of the node IP's. If this is the case, change the relevant one to something else.
cluster:
    network:
        # The pod subnet CIDR.
        podSubnets:
            - 10.244.0.0/16
        # The service subnet CIDR.
        serviceSubnets:
            - 10.112.0.0/12

# The install image is the image that will install itself on the disk when a server gets the machineconfig:
machine:
    install:
            disk: /dev/sda # The disk used for installations.
            image: ghcr.io/siderolabs/installer:v1.9.4 # Allows for supplying the image used to perform the installation.
            wipe: false # Indicates if the installation disk should be wiped at installation time.

# This image is the basic Talos version, but if you need any extensions you need a different image. 
# This image can be fetched from the image factory: https://factory.talos.dev
# Choose the correct choices for your setup, for ours it is:
#   - Bare-metal Machine
#   - Latest version
#   - amd64
#   - Extensions:
#       - siderolabs/iscsi-tools (v0.1.6)
#       - siderolabs/util-linux-tools (2.40.4)
#   - skip

# Then go down to Initial Installation and copy the installer image URL. In our case it will look like this:

machine: 
        disk: /dev/sda # The disk used for installations.
        image: factory.talos.dev/installer/613e1592b2da41ae5e265e8789429f22e121aab91cb4deb6bc3c0b6262961245:v1.9.5  # Allows for supplying the image used to perform the installation.
        wipe: false # Indicates if the installation disk should be wiped at installation time.

# 2.4.2 Extra config needed only in worker.yaml. This is needed for longhorn to work.
machine:
    kubelet:
        extraMounts:
            - destination: /var/lib/longhorn
              type: bind
              source: /var/lib/longhorn
              options:
                - bind
                - rshared
                - rw

# 3 Apply config and bootstrap cluster
# 3.1 Send machine config to all nodes. 
# (Only need to do it with the one control plane machine that has the endpoint ip configured earleir now, but can also do all now if wanted)

# Apply config to control plane
talosctl apply-config --insecure --nodes 10.100.38.101 --file controlplane.yaml
talosctl apply-config --insecure --nodes 10.100.38.102 --file controlplane.yaml
talosctl apply-config --insecure --nodes 10.100.38.103 --file controlplane.yaml

# Apply config to workers
talosctl apply-config --insecure --nodes 10.100.38.104 --file worker.yaml
talosctl apply-config --insecure --nodes 10.100.38.105 --file worker.yaml
talosctl apply-config --insecure --nodes 10.100.38.106 --file worker.yaml

# 3.2 Bootsrap cluster
talosctl bootstrap

# 3.3 after a little bit, retrieve kubeconfig
talosctl kubeconfig .

# 3.4 Export kubeconfig so that kubectl can get access to the cluster (should be added to bashrc)

export KUBECONFIG=~/talos/kubeconfig

# 3.5 Verify cluster

# get nodes:
kubectl get nodes

# ensure that extensions are installed:

talosctl get extensions -n 10.100.38.101
talosctl get extensions -n 10.100.38.102 
talosctl get extensions -n 10.100.38.103 


# 4. To remove the config on a talos node, you can reset it with this command:
talosctl reset -n <node_ip_to_be_reset>

# 5. To upgrade a talos node to another image, run this command:

talosctl upgrade --nodes <node_ip_to_be_reset> --image <image_url>