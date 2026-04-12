https://www.minio.org.cn/docs/minio/kubernetes/upstream/index.html

https://docs.min.io/enterprise/aistor-object-store/

https://www.min.io/

https://github.com/minio/minio

```
mkdir -p /data/nfs/minio
chmod 777 /data/nfs/minio
cat >>  /etc/exports << EOF
/data/nfs/minio  *(rw,sync,no_root_squash,no_all_squash)
EOF
exportfs -rv
systemctl restart rpcbind
systemctl restart nfs-server

```



登录MinIO控制台的账号密码默认为 minioadmin | minioadmin



```

```



```
helm install minio minio/minio \
  --namespace minio \
  --set mode=distributed \
  --set replicas=3 \
  --set persistence.size=100Gi \
  --set accessKey=minioadmin \
  --set secretKey=minioadminpassword
```





```
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --namespace minio
  --set nfs.server=172.23.171.172 \
  --set nfs.path=/data/nfs/minio \
  --set storageClass.name=nfs-storage \
  --set storageClass.onDelete=delete \
  --set persistence.size=10Gi
  
helm uninstall nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=172.23.171.172 \
  --set nfs.path=/data/nfs/minio \
  --set storageClass.name=nfs-storage \
  --set storageClass.onDelete=delete 
```



https://www.cnblogs.com/chen2ha/p/18469090



https://github.com/minio/operator

```
mkdir -p /nfs/data/minio/pv1
mkdir -p /nfs/data/minio/pv2
mkdir -p /nfs/data/minio/pv3
mkdir -p /nfs/data/minio/pv4
chmod 777 /nfs/data/minio/pv{1..4} 

```

sc-nfs.yaml

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: minio-nfs-sc
provisioner: kubernetes.io/no-provisioner # 静态供给必须使用这个 provisioner
volumeBindingMode: WaitForFirstConsumer # 等待 Pod 调度后再绑定，避免拓扑问题
reclaimPolicy: Retain # 生产环境建议 Retain，防止误删 PV 导致数据丢失
```

kubectl apply -f sc-nfs.yaml



pv-nfs.yaml

```

```



```
helm search repo minio
helm install   minio --namespace minio --create-namespace --set accessKey=minio,secretKey=minio123 --set mode=distributed --set replicas=4 --set service.type=NodePort --set persistence.size=10Gi --set service.nodePort=30900 --set persistence.storageClass=longhorn --set resources.requests.memory=1Gi   weiruan/minio




```



```
helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner   --set nfs.server=172.23.171.172   --set nfs.path=/data/nfs/minio   --set storageClass.name=nfs-storage   --set storageClass.onDelete=delete

kubectl get pod nfs-subdir-external-provisioner-78f7797bb4-x9hxw -n kube-system -o yaml

helm repo add minio1 https://charts.min.io/
helm repo update
helm pull minio1/minio --untar
helm show values minio1/minio > values.yaml
kubectl create ns minio
helm install my-minio minio1/minio -n minio -f values.yaml

[root@kube-master ~]# kubectl get pods -n minio
NAME                      READY   STATUS    RESTARTS      AGE
my-minio-0                0/1     Pending   0             2m24s
my-minio-1                0/1     Pending   0             2m24s
my-minio-10               0/1     Pending   0             2m24s
my-minio-11               0/1     Pending   0             2m24s
my-minio-12               0/1     Pending   0             2m24s
my-minio-13               0/1     Pending   0             2m24s
my-minio-14               0/1     Pending   0             2m24s
my-minio-15               0/1     Pending   0             2m24s
my-minio-2                0/1     Pending   0             2m24s
my-minio-3                0/1     Pending   0             2m24s
my-minio-4                0/1     Pending   0             2m24s
my-minio-5                0/1     Pending   0             2m24s
my-minio-6                0/1     Pending   0             2m24s
my-minio-7                0/1     Pending   0             2m24s
my-minio-8                0/1     Pending   0             2m24s
my-minio-9                0/1     Pending   0             2m24s
my-minio-post-job-xsdvw   0/1     Error     1 (78s ago)   2m24s

[root@kube-master ~]# kubectl get svc -n minio
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
my-minio           ClusterIP   10.98.98.7     <none>        9000/TCP   4m30s
my-minio-console   ClusterIP   10.98.73.187   <none>        9001/TCP   4m30s
my-minio-svc       ClusterIP   None           <none>        9000/TCP   4m30s


NAME: my-minio
LAST DEPLOYED: Sun Apr 12 06:55:32 2026
NAMESPACE: minio
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
MinIO can be accessed via port 9000 on the following DNS name from within your cluster:
my-minio.minio.cluster.local

To access MinIO from localhost, run the below commands:

  1. export POD_NAME=$(kubectl get pods --namespace minio -l "release=my-minio" -o jsonpath="{.items[0].metadata.name}")

  2. kubectl port-forward $POD_NAME 9000 --namespace minio

Read more about port forwarding here: http://kubernetes.io/docs/user-guide/kubectl/kubectl_port-forward/

You can now access MinIO server on http://localhost:9000. Follow the below steps to connect to MinIO server with mc client:

  1. Download the MinIO mc client - https://min.io/docs/minio/linux/reference/minio-mc.html#quickstart

  2. export MC_HOST_my-minio-local=http://$(kubectl get secret --namespace minio my-minio -o jsonpath="{.data.rootUser}" | base64 --decode):$(kubectl get secret --namespace minio my-minio -o jsonpath="{.data.rootPassword}" | base64 --decode)@localhost:9000

  3. mc ls my-minio-local




```

AK	zmmmthKpYHwHrl5UQIua		em1tbXRoS3BZSHdIcmw1VVFJdWEK

SK	xIL5KuVLuBQdfyYWcNuXS4dttN31pTOLJA2I14qi		eElMNUt1Vkx1QlFkZnlZV2NOdVhTNGR0dE4zMXBUT0xKQTJJMTRxaQo=

admin/admin123





```
Warning  FailedScheduling  2m45s  default-scheduler  0/2 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.

```

