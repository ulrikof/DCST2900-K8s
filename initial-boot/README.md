# Initial Boot Guide

This README explains how to set up a Kubernetes cluster compatible with the cluster design. It utilizes PXE boot with Talos OS for all servers, which are then turned into nodes in a Kubernetes cluster.

## Prerequisites

See the system requirements in the main README file.

Additionally, the control plane in the cluster should be fronted by a load balancer. While not strictly required (a single control plane node can serve as the Kubernetes API frontend), this setup lacks fault tolerance. An example HAProxy load balancer configuration can be found under `initial-boot/services/haproxy`, which includes installation steps and a sample HAProxy configuration file. In this guide, the IP address of the load balancer is referred to as `<lb-ip>`. If no load balancer is used, substitute `<lb-ip>` with the IP of a control plane node.

Furthermore, a PXE server is required. The proposed solution uses `netboot`, which provides a simple way to serve PXE boot images. Instructions for setting up a PXE server that serves the `netboot` image can be found in `initial-boot/services/PXE-server`. Note that `netboot` requires console access to the servers, as selecting the correct image involves interacting with a boot menu. Additionally, the easiest way to inform servers where to fetch their PXE image is through a DHCP server. A basic DHCP server configuration, along with setup instructions, is available in `initial-boot/services/DHCP-server`.



The servers used as cluster nodes must be configured to boot via PXE. Set their boot order to: 1. hard disk, 2. PXE. As long as the hard disk is empty, the first boot attempt will fail and fall back to PXE. After Talos is installed on disk, future boots will proceed directly from disk. An example of how to do this via iDRAC can be found in `iDRAC-config.sh`.

All commands should be run from the `initial-boot` folder, as some reference local files in that directory.

## 1. Install Tools

Install both `kubectl` and `talosctl` using the following commands:

```sh
# Install kubectl
sudo snap install kubectl --classic

# Install talosctl
curl -sL https://talos.dev/install | sh
```

## 2. Create Talos Configuration Files

Talos is configured using machine configuration files. Default configurations are generated, then modified using patch files to suit the cluster design. These patch files specify the Talos image and make necessary adjustments for included add-ons.

The following command generates three files:

- `worker.yaml`: configuration for worker nodes  
- `controlplane.yaml`: configuration for control plane nodes  
- `talosconfig`: local config file used by `talosctl` to communicate with Talos nodes

Before running the command, you must update the `all-patch.yaml` file to include the correct load balancer IP:

```yaml
machine:
  certSANs:
    - <lb-ip>
```

Now generate the configuration files (replace `<lb-ip>` with the actual IP address):

```sh
talosctl gen config K8s https://<lb-ip>:6443 --config-patch @all-patch.yaml --config-patch-worker @worker-patch.yaml
```

Next, configure the `talosconfig` file by pointing it to one of the control plane node IPs:

```sh
talosctl --talosconfig talosconfig config endpoint <control-plane-1-ip>
talosctl --talosconfig talosconfig config node <control-plane-1-ip>
```

Then, export the path of the `talosconfig` file such that talosctl can find it:

```sh
export TALOSCONFIG="$(pwd)/talosconfig"
```

## 3. Send Machine Config to Nodes

Make sure all servers have booted into Talos in maintenance mode and have valid IP addresses.

Apply the control plane configuration:

```sh
talosctl apply-config --insecure --nodes <control-plane-1-ip> --file controlplane.yaml
talosctl apply-config --insecure --nodes <control-plane-2-ip> --file controlplane.yaml
talosctl apply-config --insecure --nodes <control-plane-3-ip> --file controlplane.yaml
```

Apply the worker configuration:

```sh
talosctl apply-config --insecure --nodes <worker-1-ip> --file worker.yaml
talosctl apply-config --insecure --nodes <worker-2-ip> --file worker.yaml
talosctl apply-config --insecure --nodes <worker-3-ip> --file worker.yaml
# Repeat for additional workers
```

After receiving its machine config, each node will reboot and automatically set itself up.

## 4. Bootstrap and Verify the Cluster

Once nodes have rebooted, bootstrap the cluster from a control plane node:

```sh
talosctl bootstrap
```

Wait a few minutes for the cluster to initialize. Then, fetch the `kubeconfig` file:

```sh
talosctl kubeconfig .
```

Then `kubectl` needs to find the kubeconfig file. This can be done in two ways:

```sh
# Option 1:
export KUBECONFIG=~/talos/kubeconfig

# Option 2:
mkdir -p ~/.kube
mv kubeconfig ~/.kube/config
```

Now, you should have access to the cluster. This can be verified with:

```sh
kubectl get nodes
```

Also, you can check cluster health:

```sh
talosctl health
```

## Resetting Nodes

If needed, a single node can be reset with the following command:

```sh
talosctl reset -n <node_ip>
```

This removes Talos OS from the hard disk. Note that this only resets the node itself, it does **not** remove the corresponding node resource from the Kubernetes cluster. That must be done manually.

To reset the entire cluster, you can reset all nodes at once:

```sh
talosctl reset --graceful=false --reboot=true -n <control-plane-1-ip>,<control-plane-2-ip>,<control-plane-3-ip>,<worker-1-ip>,<worker-2-ip>,...,<worker-x-ip>
```

This command wipes Talos OS from all specified nodes, effectively deleting the entire cluster. The `--graceful=false` flag is required to forcefully reset control plane nodes, while the `--reboot=true` flag reboots the nodes after reset (optional).