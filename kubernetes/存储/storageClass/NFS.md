

```
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner -n kube-system \
    --set image.repository=dyrnq/nfs-subdir-external-provisioner \
    --set nfs.server=172.23.171.172 \
    --set nfs.path=/data/nfstest

mkdir -p /data/nfstest
chmod 777 /data/nfstest
cat >>  /etc/exports << EOF
/data/nfstest  *(rw,sync,no_root_squash,no_all_squash)
EOF

exportfs -rv
systemctl restart rpcbind
systemctl restart nfs-server

```



```
[root@kube-master gitlab]# helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner -n kube-system \
    --set image.repository=dyrnq/nfs-subdir-external-provisioner \
    --set nfs.server=172.23.171.172 \
    --set nfs.path=/data/nfstest
NAME: nfs-subdir-external-provisioner
LAST DEPLOYED: Sun Apr 12 06:17:18 2026
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
[root@kube-master gitlab]#
[root@kube-master gitlab]#
[root@kube-master gitlab]#
[root@kube-master gitlab]# kubectl get sc
NAME           PROVISIONER                                     RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
minio-nfs-sc   kubernetes.io/no-provisioner                    Retain          WaitForFirstConsumer   false                  6h22m
nfs-client     cluster.local/nfs-subdir-external-provisioner   Delete          Immediate              true                   14s
[root@kube-master gitlab]# helm list -A
NAME                            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                                         APP VERSION
nfs-subdir-external-provisioner kube-system     1               2026-04-12 06:17:18.268132236 +0800 CST deployed        nfs-subdir-external-provisioner-4.0.18        4.0.2

```



storageclass-nfs.yaml

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage-test
provisioner: cluster.local/nfs-subdir-external-provisioner
parameters:
  # 设置为"false"时删除PVC不会保留数据，"true"则保留数据
  archiveOnDelete: "false"
mountOptions:
  # 指定NFS版本,这个需要根据NFS Server版本号设置
  - nfsvers=4
---
# 创建PVC
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: nfs-storage-pvc-1
  namespace: dev1
spec:
  storageClassName: nfs-storage-test    #需要与上面创建的storageclass的名称一致
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Mi
```

storageclass-nfs-pod.yaml

```
kind: Pod
apiVersion: v1
metadata:
  name: nfs-storage-pod-1
  namespace: dev1
spec:
  containers:
    - name: nfs-storage-pod-1
      image: busybox
      command:
        - "/bin/sh"
      args:
        - "-c"
        - "touch /mnt/teststorage && echo 111 > /mnt/teststorage && exit 0 || exit 1"  ## 创建一个名称为"SUCCESS"的文件
      volumeMounts:
        - name: nfs-pvc
          mountPath: "/mnt"
  restartPolicy: "Never"
  volumes:
    - name: nfs-pvc
      persistentVolumeClaim:
        claimName: nfs-storage-pvc-1
```

