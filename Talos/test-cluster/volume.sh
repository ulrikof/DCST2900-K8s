kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.2/examples/storageclass.yaml

kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.2/examples/pod_with_pvc.yaml


kubectl get pods


kubectl exec -it volume-test -- /bin/sh
echo "Persistent Test" > /data/testfile
cat /data/testfile
exit


kubectl delete pod volume-test

kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.2/examples/pod_with_pvc.yaml

# (you will get error but that is not problem now)

kubectl exec -it volume-test -- /bin/sh

cat /data/testfile

# And you shoul see