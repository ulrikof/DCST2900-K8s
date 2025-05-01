### Setup

## Create NFS client on a machine

# Install NFS server
sudo apt update
sudo apt install -y nfs-kernel-server

# Create the backup directory
sudo mkdir -p /opt/backupstore
sudo chown nobody:nogroup /opt/backupstore
sudo chmod 777 /opt/backupstore

# Configure export
echo "/opt/backupstore *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports

# Restart NFS service
sudo exportfs -rav
sudo systemctl restart nfs-kernel-server

## Setup backup target for longhorn.

# This can be done through the cluster, but the simplest way is to do this is through the longhorn UI

# In the longhorn UI go to settings > backup target > create backup target

# Then add the nfs server created above with this format: nfs://<target-ip>:/opt/backupstore


### Test

# Apply VM
kubectl apply -f vm.yaml

# Enter it and add a file

virtctl console beckup-test

touch persistent-file.txt

# Do a backup

# For this test a singe backup is easiest and this is simplest to do in the longhorn UI.

# In generall, incremental backups of all volumes can easily be set up by doing 
kubectl apply -f reccuring-backup.yaml


# Then veriy backup:
kubectl get pvc
kubectl get snapshots -n longhorn-system
kubectl get backup -n longhorn-system
sudo ls /opt/backupstore/backupstore/volumes/cf/ea/


# Then delete the vm
kubectl delete -f vm.yaml

# Then, in the longhorn UI, restore the backup

# backup > drop down menu of the volume > restore from latest backup. just use default settings

# Then go to the volume and select create pv/pvc from that volume.

# Then verify that the pvc exists:

kubectl get pvc

# Then create a new vm referencing this pvc

kubectl apply -f backup-vm-restored.yaml

# Then console into it and check if the file is there
virtctl console restored-vm

ls

# output should show the file