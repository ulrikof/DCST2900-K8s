### On the NFS server

sudo apt update
sudo apt install -y nfs-kernel-server

sudo mkdir -p /srv/nfs/k8s
sudo chmod -R 777 /srv/nfs/k8s

sudo nano /etc/exports

# add this

/srv/nfs/k8s *(rw,sync,no_root_squash,no_subtree_check)


sudo exportfs -rav
sudo systemctl restart nfs-kernel-server

### On manager 

# Install NFS driver in cluster:

kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/nfs-subdir-external-provisioner/master/deploy/deployment.yaml



# To test if NFS server is working on manager
# Install NFS client utilites

sudo apt update
sudo apt install -y nfs-common


sudo mount -t nfs 192.168.0.116:/srv/nfs/k8s /mnt/nfs-test

ls /mnt/nfs-test



### Test container setup

# First you need a storage class, see nfs/nfs-storageclass.yaml. Then apply it:

kubectl apply -f nfs-storageclass.yaml

# This defines the storage for Kubernetes

# Then you need a persistant volume, see nfs/pv-nfs.yaml. Then apply it:

kubectl apply -f pv-nfs.yaml

# This creates a volume in the storage defined above.

# Then you need a persistant volume claim, see nfs/pvc-nfs.yaml. Then apply it:

kubectl apply -f pvc-nfs.yaml

# A persistant volume claim is a request for space on the persistant volume.

# Then you can create a pod, see nfs/test-pod.yaml. Then apply it:

kubectl apply -f nfs/test-pod.yaml

# Then you can access the storage from the pod:

kubectl exec -it nfs-test-pod -- sh

ls /mnt/nfs
