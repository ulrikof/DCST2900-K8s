# DCST2900 Bachelor Thesis - Design and Implementation of Kubernetes as a Modern IaaS Platform

## Introduction

This bachelor thesis revolves around designing and implementing Kubernetes as a modern IaaS platform. The solution utilizes tools like KubeVirt, Longhorn, Multus, MetalLB, Argo CD, and Crossplane to build an extensive, GitOps-driven IaaS platform that serves as a common management interface for an entire infrastructure stack.

The design includes support for virtual machines, GitOps-based resource management, Azure resource integration, multi-tenancy, and virtual clusters. These virtual clusters follow the same design as the main cluster but are deployed inside virtual machines within the platform.

The complete design can be set up directly from this Git repository.

## System Requirements

The design is intended to run on bare-metal servers. These servers need to be connected to a LAN that includes a DHCP server. An simple example of how to set up a DHCP server can be found in `initial-boot/services/DHCP-server`. There should also be a reasonable number of available IP addresses that the DHCP server can assign. Additionally, a separate set of unused static IP addresses is required for the Kubernetes load balancers used by the design.

Each server used as a node must fulfill the hardware requirements for Talos OS, which are listed below:

### Minimum Requirements

| Role          | Memory | Cores | System Disk  |
|---------------|--------|-------|--------------|
| Control Plane | 2 GiB  | 2     | 10 GiB       |
| Worker        | 1 GiB  | 1     | 10 GiB       |

### Recommended Requirements

| Role          | Memory | Cores | System Disk  |
|---------------|--------|-------|--------------|
| Control Plane | 4 GiB  | 4     | 100 GiB      |
| Worker        | 2 GiB  | 2     | 100 GiB      |

## Initial Setup

To configure the servers and initialize the Kubernetes cluster, [follow the instructions in the README in the initial-boot folder](initial-boot/README.md).

Once the initial setup is complete, you should have access to a functional and empty Kubernetes cluster. All servers booted with Talos OS should appear as nodes. To verify this, run `kubectl get nodes`.

## Deployment of Cluster Design

To deploy the actual cluster design, there are two available options: automatic installation via Argo CD, or manual deployment. The automatic method is significantly simpler and more efficient, and should be preferred unless there is a specific reason to deploy manually. It should be noted that Crossplane, the tool used for Azure integration has not been implemented as part of the Argo CD solution. It must therefore be installed manually. 

### Automatic Deployment

The design is intended to be deployed using Argo CD. This only requires manually installing Argo CD and then deploying an app-of-apps configuration that references this Git repository. [See the README in the ArgoCD folder for detailed steps](ArgoCD/README.md).

### Manual Deployment

Although the design is intended to be deployed using Argo CD, it can also be installed manually. This can help provide a clearer understanding of the individual add-ons and how they work together.

To do this, refer to the `manual-setup` folder. Each subfolder corresponds to one of the add-ons used in the design. Inside each subfolder, there is an `install.sh` file that explains how to install and configure the add-on, including all required commands.

Note that although these are `.sh` files, they are not intended to be executed as standalone scripts, but rather serve as a guided walkthrough.

## Use Case Testing

As part of the thesis, the design has been tested against a set of use cases to evaluate its functionality and behavior in relation to the design requirements.
All test files and instructions are located in the `use-case-testing` folder, which contains one subfolder per test.
Each subfolder typically includes the necessary manifests and a `test.sh` file describing how to run the test.