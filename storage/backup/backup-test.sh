# Create backup-vm.yaml

kubectl apply -f backup-vm.yaml

# Console in and create a file

virtctl console backup-vm

    touch backup-test

    ls  


# First specify the backup endpoint. It is a setting and can be changed by deploying a manifest:

kubectl apply -f backup-config.yaml

# Then create the recuring backup job

kubectl apply -f recuring-backup.yaml

# Then wait until the backup has been created, this can either be checked by:

kubectl get snapshots -n longhorn-system | grep backup

# And then looking for the correct volume, or just checking the longhorn UI.

# Then delete the vm 

kubectl delete -f backup-vm.yaml

# The volume will then get detatched. This could either be deleted by using the longhorn UI or manually with kubectl (its in the longhorn namespace)

# Then use the longhorn ui to restore the volume, and then use the ui to generate a pv/pvc from it.

# then this pvc can be connected to a new vm:

kubectl apply -f backup-vm-restored.yaml

# Then console in and check if the file we created earlier is present:

virtctl console restored-vm

    ls