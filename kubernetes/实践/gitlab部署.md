# 参考材料

https://docs.gitlab.com/operator/installation/

https://gitlab.com/gitlab-org/cloud-native/gitlab-operator

https://docs.gitlab.com/

https://docs.gitlab.com/user/clusters/agent/

https://developer.aliyun.com/article/856853

https://docs.gitlab.com/archives/

https://www.qikqiak.com/k8strain2/devops/gitlab/

# 部署NFS

```
yum install -y nfs-utils rpcbind
mkdir -p /data/nfs/gitlab/{conf,data,logs}
chmod 777 /data/nfs/gitlab

cat >  /etc/exports << EOF
/data/nfs/gitlab/conf  *(rw,sync,no_root_squash,no_all_squash)
/data/nfs/gitlab/data  *(rw,sync,no_root_squash,no_all_squash)
/data/nfs/gitlab/logs  *(rw,sync,no_root_squash,no_all_squash)
EOF
exportfs -rv
systemctl enable --now rpcbind
systemctl enable --now nfs-server

exportfs -rv
systemctl restart rpcbind
systemctl restart nfs-server
```



# 部署 NFS-Subdir-External-Provisioner(已删除)

## nfs-storageclass.yaml

```
apiVersion: v1
kind: Namespace
metadata:
  name: nfs-provisioner
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner
  namespace: nfs-provisioner
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: nfs-provisioner
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  namespace: nfs-provisioner
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  namespace: nfs-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: nfs-provisioner
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  labels:
    app: nfs-client-provisioner
  namespace: nfs-provisioner
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: registry.k8s.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: k8s-sigs.io/nfs-subdir-external-provisioner
            - name: NFS_SERVER
              value: 172.23.171.172  # 修改为你的 NFS 服务器 IP
            - name: NFS_PATH
              value: /data/nfs/gitlab # 修改为你的 NFS 共享路径
      volumes:
        - name: nfs-client-root
          nfs:
            server: 172.23.171.172
            path: /data/nfs/gitlab
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-nfs-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true" # 设为默认存储类
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner
parameters:
  archiveOnDelete: "false"

```

## 运行结果

```
[root@kube-master gitlab]# kubectl create -f nfs-storageclass.yaml
namespace/nfs-provisioner created
serviceaccount/nfs-client-provisioner created
clusterrole.rbac.authorization.k8s.io/nfs-client-provisioner-runner created
clusterrolebinding.rbac.authorization.k8s.io/run-nfs-client-provisioner created
role.rbac.authorization.k8s.io/leader-locking-nfs-client-provisioner created
rolebinding.rbac.authorization.k8s.io/leader-locking-nfs-client-provisioner created
deployment.apps/nfs-client-provisioner created
storageclass.storage.k8s.io/managed-nfs-storage created
[root@kube-master gitlab]# kubectl get pod -n nfs-provisioner
NAME                                      READY   STATUS    RESTARTS   AGE
nfs-client-provisioner-6d78df6b94-qqlqg   1/1     Running   0          29s
[root@kube-master gitlab]# kubectl get deploy -n nfs-provisioner
NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
nfs-client-provisioner   1/1     1            1           63s
[root@kube-master gitlab]# kubectl get clusterrolebinding | grep nfs
run-nfs-client-provisioner                               ClusterRole/nfs-client-provisioner-runner                                          2m23s
[root@kube-master gitlab]# kubectl get clusterrole | grep nfs
nfs-client-provisioner-runner                                          2026-04-11T07:51:04Z
[root@kube-master gitlab]# kubectl get sc
NAME                            PROVISIONER                                   RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
managed-nfs-storage (default)   k8s-sigs.io/nfs-subdir-external-provisioner   Delete          Immediate           false                  3m18s

```



# 测试provisioner



## 创建PVC

test-pvc.yaml

```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-pvc
spec:
  storageClassName: nfs-storage #---需要与上面创建的storageclass的名称一致
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Mi
```



运行结果

```
[root@kube-master helm]# kubectl get pvc
NAME       STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
test-pvc   Pending                                      nfs-storage    <unset>                 6m36s
[root@kube-master helm]# kubectl get pvc -A
NAMESPACE   NAME       STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
default     test-pvc   Pending                                      nfs-storage    <unset>                 6m41s

```

# helm安装



```
wget https://get.helm.sh/helm-v3.20.2-linux-amd64.tar.gz
tar xzf helm-v3.20.2-linux-amd64.tar.gz
cp linux-amd64/helm /usr/bin/

```

# 使用helm部署gitlab(未成功)

gitlab-values.yaml

```
# 全局配置
global:
  hosts:
    domain: example.com # 修改为你的域名或 IP
    https: false        # 如果没有 SSL 证书，先设为 false
  ingress:
    configureCertmanager: false
  # 指定使用 NFS 存储类
  pvc:
    storageClass: "managed-nfs-storage"

# GitLab 核心组件
gitlab:
  webservice:
    replicas: 1
  sidekiq:
    replicas: 1
  
  # Gitaly 是 Git 存储的核心，必须配置持久化
  gitaly:
    persistence:
      enabled: true
      size: 50Gi # 根据需求调整

#  Registry 镜像仓库
registry:
  enabled: true
  persistence:
    enabled: true
    size: 10Gi

# PostgreSQL 数据库
postgresql:
  persistence:
    enabled: true
    size: 10Gi

# Redis 缓存
redis:
  persistence:
    enabled: true
    size: 5Gi

# Prometheus 监控
prometheus:
  install: false # 资源紧张可关闭

# 资源限制 (根据你的集群配置调整，否则 Pod 会 Pending)
# 注意：GitLab 默认资源请求较高，开发测试环境可以适当调低
gitlab-runner:
  runners:
    config: |
      [[runners]]
        [runners.kubernetes]
          image = "ubuntu:16.04"
```



```
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm search repo -l gitlab/gitlab-runner -l
helm pull gitlab/gitlab-runner --version 9.10.0 --untar
# 创建命名空间
kubectl create namespace gitlab

# 安装 GitLab
helm install gitlab gitlab/gitlab -n gitlab -f gitlab-values.yaml --timeout 600s
[root@kube-master ~]# helm uninstall gitlab -n gitlab
These resources were kept due to the resource policy:
[CustomResourceDefinition] challenges.acme.cert-manager.io
[CustomResourceDefinition] orders.acme.cert-manager.io
[CustomResourceDefinition] certificaterequests.cert-manager.io
[CustomResourceDefinition] certificates.cert-manager.io
[CustomResourceDefinition] clusterissuers.cert-manager.io
[CustomResourceDefinition] issuers.cert-manager.io
[PersistentVolumeClaim] gitlab-minio

release "gitlab" uninstalled

[root@kube-master gitlab]# helm list -A
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
gitlab  gitlab          1               2026-04-11 16:42:53.623665059 +0800 CST deployed        gitlab-9.10.3   v18.10.3

[root@kube-master gitlab]# helm pull gitlab/gitlab --version 9.10.3 --untar

[root@kube-master gitlab]# kubectl get pod -n gitlab
NAME                                               READY   STATUS      RESTARTS        AGE
gitlab-certmanager-56f499845-c5rcm                 1/1     Running     0               12m
gitlab-certmanager-cainjector-6d6c8c8cdb-mdwtj     1/1     Running     0               12m
gitlab-certmanager-webhook-75469dd45c-rbjv8        1/1     Running     0               12m
gitlab-gitaly-0                                    1/1     Running     0               12m
gitlab-gitlab-exporter-5596c64946-2qp4n            1/1     Running     0               12m
gitlab-gitlab-runner-5b87d4f778-66hs2              1/1     Running     4 (3m16s ago)   12m
gitlab-gitlab-shell-5cbb9f9498-ktvwj               1/1     Running     0               12m
gitlab-gitlab-shell-5cbb9f9498-rjs8v               1/1     Running     0               12m
gitlab-kas-69fbfddf49-9cmp7                        1/1     Running     0               12m
gitlab-kas-69fbfddf49-r5wmv                        1/1     Running     3 (11m ago)     12m
gitlab-migrations-d098ada-rmvv2                    0/1     Completed   0               12m
gitlab-minio-6577f858fb-m2ljf                      1/1     Running     0               12m
gitlab-minio-create-buckets-223d5aa-kqbtc          0/1     Completed   0               12m
gitlab-nginx-ingress-controller-6d6fff8bdc-7jj5m   1/1     Running     0               12m
gitlab-nginx-ingress-controller-6d6fff8bdc-sv7xl   1/1     Running     0               12m
gitlab-postgresql-0                                2/2     Running     0               12m
gitlab-redis-master-0                              2/2     Running     0               12m
gitlab-registry-67f6789cc9-26624                   1/1     Running     0               12m
gitlab-registry-67f6789cc9-jp9jg                   1/1     Running     0               12m
gitlab-sidekiq-all-in-1-v2-c9c647d6c-gjq5v         1/1     Running     0               3m18s
gitlab-sidekiq-all-in-1-v2-c9c647d6c-zf5q5         1/1     Running     2 (5m58s ago)   12m
gitlab-toolbox-7f84cf9466-hks46                    1/1     Running     0               12m
gitlab-webservice-default-c8bbfb8bd-s6w8m          2/2     Running     1 (6m15s ago)   12m
gitlab-webservice-default-c8bbfb8bd-x48vx          2/2     Running     1 (6m14s ago)   12m

[root@kube-master gitlab]# kubectl get svc -n gitlab
NAME                                      TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                   AGE
gitlab-certmanager                        ClusterIP      10.108.7.211     <none>        9402/TCP                                  13m
gitlab-certmanager-cainjector             ClusterIP      10.103.94.79     <none>        9402/TCP                                  13m
gitlab-certmanager-webhook                ClusterIP      10.96.131.91     <none>        443/TCP,9402/TCP                          13m
gitlab-gitaly                             ClusterIP      None             <none>        8075/TCP,9236/TCP                         13m
gitlab-gitlab-exporter                    ClusterIP      10.103.150.4     <none>        9168/TCP                                  13m
gitlab-gitlab-shell                       ClusterIP      10.99.68.210     <none>        22/TCP                                    13m
gitlab-kas                                ClusterIP      10.99.131.177    <none>        8150/TCP,8153/TCP,8154/TCP,8151/TCP       13m
gitlab-minio-svc                          ClusterIP      10.96.151.125    <none>        9000/TCP                                  13m
gitlab-nginx-ingress-controller           LoadBalancer   10.106.240.18    <pending>     80:32457/TCP,443:31251/TCP,22:31103/TCP   13m
gitlab-nginx-ingress-controller-metrics   ClusterIP      10.109.66.246    <none>        10254/TCP                                 13m
gitlab-postgresql                         ClusterIP      10.99.11.249     <none>        5432/TCP                                  13m
gitlab-postgresql-hl                      ClusterIP      None             <none>        5432/TCP                                  13m
gitlab-postgresql-metrics                 ClusterIP      10.105.46.190    <none>        9187/TCP                                  13m
gitlab-redis-headless                     ClusterIP      None             <none>        6379/TCP                                  13m
gitlab-redis-master                       ClusterIP      10.98.211.29     <none>        6379/TCP                                  13m
gitlab-redis-metrics                      ClusterIP      10.103.199.74    <none>        9121/TCP                                  13m
gitlab-registry                           ClusterIP      10.107.150.105   <none>        5000/TCP                                  13m
gitlab-webservice-default                 ClusterIP      10.100.98.201    <none>        8080/TCP,8181/TCP,8083/TCP   

[root@kube-master gitlab]# kubectl get pvc -n gitlab
NAME                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS          VOLUMEATTRIBUTESCLASS   AGE
data-gitlab-postgresql-0           Bound    pvc-818c3ec8-254f-450b-9497-5e0ef481f6d5   8Gi        RWO            managed-nfs-storage   <unset>                 15m
gitlab-minio                       Bound    pvc-92d12f5b-e6a6-4ac1-853b-f82a52a230b2   10Gi       RWO            managed-nfs-storage   <unset>                 15m
redis-data-gitlab-redis-master-0   Bound    pvc-573d9f26-3b01-4916-b092-f68ae54bcd98   8Gi        RWO            managed-nfs-storage   <unset>                 15m
repo-data-gitlab-gitaly-0          Bound    pvc-dcea4be4-6dd1-4217-bb73-fd94678c954e   20Gi       RWO            managed-nfs-storage   <unset>                 15m


```



# 部署gitlab

## 创建存储

创建三个 PV 和三个对应的 PVC，分别对应配置、数据和日志

gitlab-storage.yaml

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitlab-conf-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  nfs:
    server: 172.23.171.172
    path: /data/nfs/gitlab/conf

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitlab-data-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  nfs:
    server: 172.23.171.172
    path: /data/nfs/gitlab/data
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitlab-logs-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  nfs:
    server: 172.23.171.172
    path: /data/nfs/gitlab/logs

---
apiVersion: v1
kind: Namespace
metadata:
  name: gitlab
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitlab-conf-pvc
  namespace: gitlab
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  volumeName: gitlab-conf-pv

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitlab-data-pvc
  namespace: gitlab
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Gi
  volumeName: gitlab-data-pv
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitlab-logs-pvc
  namespace: gitlab
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  volumeName: gitlab-logs-pv
```



```
[root@kube-master gitlab]# kubectl apply -f gitlab-storage.yaml
[root@kube-master gitlab]# kubectl get pv -n gitlab ; kubectl get pvc -n gitlab
NAME             CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                    STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
gitlab-conf-pv   1Gi        RWX            Retain           Bound    gitlab/gitlab-conf-pvc                  <unset>                          8m18s
gitlab-data-pv   10Gi       RWX            Retain           Bound    gitlab/gitlab-data-pvc                  <unset>                          8m18s
gitlab-logs-pv   5Gi        RWX            Retain           Bound    gitlab/gitlab-logs-pvc                  <unset>                          53s
NAME              STATUS   VOLUME           CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
gitlab-conf-pvc   Bound    gitlab-conf-pv   1Gi        RWX                           <unset>                 8m18s
gitlab-data-pvc   Bound    gitlab-data-pv   20Gi       RWX                           <unset>                 8m18s
gitlab-logs-pvc   Bound    gitlab-logs-pv   5Gi        RWX                           <unset>                 8m18s

```



```
rm -fr /data/nfs/gitlab
mkdir -p /data/nfs/gitlab/{redis,data,postsql}
chmod 777 /data/nfs/gitlab

cat >  /etc/exports << EOF
/data/nfs/gitlab/redis  *(rw,sync,no_root_squash,no_all_squash)
/data/nfs/gitlab/data  *(rw,sync,no_root_squash,no_all_squash)
/data/nfs/gitlab/postsql  *(rw,sync,no_root_squash,no_all_squash)
EOF
exportfs -rv
systemctl restart rpcbind
systemctl restart nfs-server

 kubectl create -f gitlab-storage.yaml
kubectl get pv -n gitlab ; kubectl get pvc -n gitlab

```



# helm+minio部署

AK	zmmmthKpYHwHrl5UQIua

SK	xIL5KuVLuBQdfyYWcNuXS4dttN31pTOLJA2I14qi

admin/admin123



```
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm search repo gitlab
kubectl create namespace gitlab
helm show values gitlab/gitlab > values.yaml
helm install gitlab -n gitlab gitlab/gitlab -f values.yaml
kubectl get pod,svc,ingress,cm -n gitlab


helm upgrade gitlab -n gitlab gitlab/gitlab -f values.yaml

```



```
[root@kube-master chart]# kubectl get pod -n gitlab
NAME                                               READY   STATUS                  RESTARTS      AGE
cm-acme-http-solver-k7gjv                          1/1     Running                 0             2m28s
gitlab-certmanager-56f499845-4htt4                 1/1     Running                 0             3m49s
gitlab-certmanager-cainjector-6d6c8c8cdb-ch6r8     1/1     Running                 0             3m49s
gitlab-certmanager-webhook-75469dd45c-bbdkd        1/1     Running                 0             3m49s
gitlab-gitaly-0                                    0/1     Pending                 0             3m49s
gitlab-gitlab-exporter-6f7d4bfb8f-ggsk2            1/1     Running                 0             3m49s
gitlab-gitlab-runner-684947f656-g577k              0/1     Running                 1 (80s ago)   3m49s
gitlab-gitlab-shell-865f5d9f89-spzn7               1/1     Running                 0             3m49s
gitlab-gitlab-shell-865f5d9f89-z8qvl               1/1     Running                 0             3m34s
gitlab-issuer-ad87256-fv7n8                        0/1     Completed               0             3m49s
gitlab-kas-667757d8b6-qzckc                        0/1     CrashLoopBackOff        5 (31s ago)   3m34s
gitlab-kas-667757d8b6-t45r8                        0/1     CrashLoopBackOff        5 (42s ago)   3m49s
gitlab-migrations-7bb9af1-d5cdz                    0/1     CrashLoopBackOff        2 (25s ago)   3m49s
gitlab-minio-6577f858fb-pmcf9                      0/1     Pending                 0             3m48s
gitlab-minio-create-buckets-b57f1b1-vs48m          1/1     Running                 0             3m49s
gitlab-nginx-ingress-controller-6d6fff8bdc-b7gjx   1/1     Running                 0             3m48s
gitlab-nginx-ingress-controller-6d6fff8bdc-xn8kq   1/1     Running                 0             3m48s
gitlab-postgresql-0                                0/2     Pending                 0             3m49s
gitlab-prometheus-server-55c5d69db7-4828m          0/2     Pending                 0             3m48s
gitlab-redis-master-0                              0/2     Pending                 0             3m49s
gitlab-registry-646ddf97d-m8zz5                    0/1     Running                 5 (88s ago)   3m34s
gitlab-registry-646ddf97d-t2d42                    0/1     Running                 5 (92s ago)   3m48s
gitlab-sidekiq-all-in-1-v2-74f4d97c46-r5kkj        0/1     Init:CrashLoopBackOff   2 (21s ago)   3m49s
gitlab-toolbox-7b74859b7f-pxmjt                    1/1     Running                 0             3m49s
gitlab-webservice-default-d56546bc7-cfwwt          0/2     Init:Error              2 (83s ago)   3m34s
gitlab-webservice-default-d56546bc7-hsh4g          0/2     Init:CrashLoopBackOff   2 (23s ago)   3m49s

```



```
NAME                                              TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                   AGE
service/cm-acme-http-solver-84sf4                 NodePort       10.107.21.200    <none>        8089:30751/TCP                            2m17s
service/gitlab-certmanager                        ClusterIP      10.97.247.103    <none>        9402/TCP                                  3m39s
service/gitlab-certmanager-cainjector             ClusterIP      10.98.230.82     <none>        9402/TCP                                  3m39s
service/gitlab-certmanager-webhook                ClusterIP      10.96.124.135    <none>        443/TCP,9402/TCP                          3m39s
service/gitlab-gitaly                             ClusterIP      None             <none>        8075/TCP,9236/TCP                         3m39s
service/gitlab-gitlab-exporter                    ClusterIP      10.110.212.89    <none>        9168/TCP                                  3m39s
service/gitlab-gitlab-shell                       ClusterIP      10.108.8.6       <none>        22/TCP                                    3m39s
service/gitlab-kas                                ClusterIP      10.98.175.82     <none>        8150/TCP,8153/TCP,8154/TCP,8151/TCP       3m39s
service/gitlab-minio-svc                          ClusterIP      10.103.207.240   <none>        9000/TCP                                  3m39s
service/gitlab-nginx-ingress-controller           LoadBalancer   10.110.30.237    <pending>     80:30709/TCP,443:30766/TCP,22:31582/TCP   3m39s
service/gitlab-nginx-ingress-controller-metrics   ClusterIP      10.99.247.145    <none>        10254/TCP                                 3m39s
service/gitlab-postgresql                         ClusterIP      10.104.137.116   <none>        5432/TCP                                  3m38s
service/gitlab-postgresql-hl                      ClusterIP      None             <none>        5432/TCP                                  3m39s
service/gitlab-postgresql-metrics                 ClusterIP      10.111.36.178    <none>        9187/TCP                                  3m39s
service/gitlab-prometheus-server                  ClusterIP      10.102.196.53    <none>        80/TCP                                    3m38s
service/gitlab-redis-headless                     ClusterIP      None             <none>        6379/TCP                                  3m38s
service/gitlab-redis-master                       ClusterIP      10.96.7.51       <none>        6379/TCP                                  3m38s
service/gitlab-redis-metrics                      ClusterIP      10.97.213.247    <none>        9121/TCP                                  3m38s
service/gitlab-registry                           ClusterIP      10.104.91.229    <none>        5000/TCP                                  3m38s
service/gitlab-webservice-default                 ClusterIP      10.99.17.39      <none>        8080/TCP,8181/TCP,8083/TCP                3m39s

```



```
mkdir /data/gitlab
chmod 777 /data/gitlab
cat >>  /etc/exports << EOF
/data/gitlab  *(rw,sync,no_root_squash,no_all_squash)
EOF
exportfs -rv
systemctl restart rpcbind
systemctl restart nfs-server
```



```
helm install gitlab-nfs-provisioner -n gitlab nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=172.23.171.172 \
  --set nfs.path=/data/gitlab \
  --set storageClass.name=gitlab-sc \
  --set storageClass.onDelete=delete 
  
```



# 报错

## 1

```
Database 'gitlab_production' already exists
psql:/home/git/gitlab/db/structure.sql:9: ERROR:  permission denied to create extension "btree_gist"
HINT:  Must be superuser to create this extension.
rake aborted!
failed to execute:
psql --set ON_ERROR_STOP=1 --quiet --no-psqlrc --output /dev/null --file /home/git/gitlab/db/structure.sql --single-transaction gitlab_production

```



```
[root@kube-master gitlab]# kubectl get pods -n gitlab | grep postgre
postgresql-98d565658-qjtt7   1/1     Running            0               59m

[root@kube-master gitlab]# kubectl exec -it postgresql-98d565658-qjtt7 -c postgresql -n gitlab -- psql -U postgres  -d gitlab_production
psql (12.3 (Ubuntu 12.3-1.pgdg18.04+1))
Type "help" for help.

gitlab_production=# ALTER USER gitlab WITH SUPERUSER;
ALTER ROLE
gitlab_production=#

```



## 2



```
Database 'gitlab_production' already exists
psql:/home/git/gitlab/db/structure.sql:11: NOTICE:  extension "pg_trgm" already exists, skipping
psql:/home/git/gitlab/db/structure.sql:5340: ERROR:  function gen_random_uuid() does not exist
LINE 2:     id uuid DEFAULT gen_random_uuid() NOT NULL,
                            ^
HINT:  No function matches the given name and argument types. You might need to add explicit type casts.
rake aborted!
failed to execute:
psql --set ON_ERROR_STOP=1 --quiet --no-psqlrc --output /dev/null --file /home/git/gitlab/db/structure.sql --single-transaction gitlab_production

Please check the output above for any errors and make sure that `psql` is installed in your PATH and has proper permissions.

```

https://packages.gitlab.com/gitlab/gitlab-ce/el/9/

```
[root@kube-master gitlab]# kubectl exec -it postgresql-98d565658-qjtt7 -c postgresql -n gitlab -- psql -U postgres  -d gitlab_production
psql (12.3 (Ubuntu 12.3-1.pgdg18.04+1))
Type "help" for help.

gitlab_production=# CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION
gitlab_production=#

```



## 3

```
2026-04-11 12:26:41,748 INFO success: puma entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
psql:/home/git/gitlab/db/structure.sql:41148: ERROR:  syntax error at or near "NULLS"
LINE 1: ...e_id, event, user_id) INCLUDE (total_occurrences) NULLS NOT ...

```

```
GitLab 版本要求：较新的 GitLab 版本（如 16.x 或 17.x）为了支持更严格的唯一性约束，开始使用 PostgreSQL 15 的新语法。
数据库版本不匹配：你的 K8s 集群中部署的 PostgreSQL 镜像版本可能较旧（例如使用了默认的 Postgres 12 或 13），导致无法解析新的 SQL 语法。
```



```
Database 'gitlab_production' already exists
psql:/home/git/gitlab/db/structure.sql:11: NOTICE:  extension "pg_trgm" already exists, skipping
psql:/home/git/gitlab/db/structure.sql:24: ERROR:  permission denied for schema public
rake aborted!
failed to execute:
psql --set ON_ERROR_STOP=1 --quiet --no-psqlrc --output /dev/null --file /home/git/gitlab/db/structure.sql --single-transaction gitlab_production

Please check the output above for any errors and make sure that `psql` is installed in your PATH and has proper permissions.


```

登录密码：admin/xxdow@2026

```
kubectl exec -it gitlab-97fbcb6cb-xjlbp -n gitlab -c gitlab -- gitlab-rake "gitlab:password:reset[root]"

```



# 20260413



```
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm repo update
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs   --namespace kube-system   --set driver.name=nfs.csi.k8s.io   --set controller.replicas=1   --set node.livenessProbe.healthPort=39653
kubectl --namespace=kube-system get pods --selector="app.kubernetes.io/instance=csi-driver-nfs"
```



```
[root@kube-master helm]# cat nfs-storage-class.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-csi
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"  # 不设为默认
provisioner: nfs.csi.k8s.io
parameters:
  server: 172.23.171.172  # 替换为你的主节点NFS IP
  share: /data/gitlab    # 替换为你的NFS共享路径
  subDir: "${pvc.metadata.namespace}-${pvc.metadata.name}"  # 自动创建子目录
reclaimPolicy: Delete
volumeBindingMode: Immediate
mountOptions:
  - vers=4.2
  - nolock,tcp
  - noatime

```



```
helm install gitlab gitlab/gitlab \
  --namespace gitlab \
  --version 7.10.0 \
  -f gitlab-values.yaml \
  --set certmanager-issuer.email=lmgsanm@163.com \
  --set global.hosts.domain=example.com \
  --set global.hosts.externalIP=47.253.13.181
```



```
[root@kube-master ~]# kubectl get svc -n gitlab
NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                   AGE
gitlab-certmanager                        ClusterIP   10.105.156.138   <none>        9402/TCP                                  15m
gitlab-certmanager-cainjector             ClusterIP   10.106.158.22    <none>        9402/TCP                                  15m
gitlab-certmanager-webhook                ClusterIP   10.101.171.147   <none>        443/TCP,9402/TCP                          15m
gitlab-gitaly                             ClusterIP   None             <none>        8075/TCP,9236/TCP                         15m
gitlab-gitlab-exporter                    ClusterIP   10.109.9.29      <none>        9168/TCP                                  15m
gitlab-gitlab-shell                       ClusterIP   10.103.150.123   <none>        22/TCP                                    15m
gitlab-kas                                ClusterIP   10.107.101.249   <none>        8150/TCP,8153/TCP,8154/TCP,8151/TCP       15m
gitlab-minio-svc                          ClusterIP   10.99.164.85     <none>        9000/TCP                                  15m
gitlab-nginx-ingress-controller           NodePort    10.110.40.13     <none>        80:30179/TCP,443:31294/TCP,22:32078/TCP   15m
gitlab-nginx-ingress-controller-metrics   ClusterIP   10.109.89.86     <none>        10254/TCP                                 15m
gitlab-postgresql                         ClusterIP   10.106.181.158   <none>        5432/TCP                                  15m
gitlab-postgresql-hl                      ClusterIP   None             <none>        5432/TCP                                  15m
gitlab-postgresql-metrics                 ClusterIP   10.99.68.11      <none>        9187/TCP                                  15m
gitlab-redis-headless                     ClusterIP   None             <none>        6379/TCP                                  15m
gitlab-redis-master                       ClusterIP   10.102.65.136    <none>        6379/TCP                                  15m
gitlab-redis-metrics                      ClusterIP   10.98.92.224     <none>        9121/TCP                                  15m
gitlab-registry                           ClusterIP   10.97.184.70     <none>        5000/TCP                                  15m
gitlab-webservice-default                 ClusterIP   10.108.166.153   <none>        8080/TCP,8181/TCP,8083/TCP 
```



```
[root@kube-master ~]# kubectl get ingress -n gitlab
NAME                        CLASS          HOSTS                  ADDRESS        PORTS     AGE
gitlab-kas                  gitlab-nginx   kas.example.com        10.110.40.13   80, 443   20m
gitlab-minio                gitlab-nginx   minio.example.com      10.110.40.13   80, 443   20m
gitlab-registry             gitlab-nginx   registry.example.com   10.110.40.13   80, 443   20m
gitlab-webservice-default   gitlab-nginx   gitlab.example.com     10.110.40.13   80, 443   20m

```



```
frontend http
    bind :80
    default_backend           http
frontend https
    bind :443
    default_backend           https
#---------------------------------------------------------------------
# round robin balancing between the various backends
#---------------------------------------------------------------------
backend http
    balance     roundrobin
    server  kube-master 172.23.171.172:30179 check
    server  kube-node 172.23.171.173:30179 check
backend https
    balance     roundrobin
    server  kube-master 172.23.171.172:31294 check
    server  kube-node 172.23.171.173:31294 check


```



 80:30179/TCP,443:31294/TCP

```
helm upgrade gitlab gitlab/gitlab -f values.yaml -n gitlab
```

```
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

```

```
helm upgrade gitlab gitlab/gitlab -f values.yaml -n gitlab \
  --set global.hosts.domain=example.com \
  --set global.hosts.https=false \
  --set nginx-ingress.tls.enabled=false
```

```
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout gitlab.key -out gitlab.crt \
  -subj "/CN=gitlab.example.com" \
  -addext "subjectAltName=DNS:gitlab.example.com"
  

```



```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitlab
  namespace: gitlab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gitlab
  template:
    metadata:
      labels:
        app: gitlab
    spec:
      containers:
      - name: gitlab
        image: gitlab/gitlab-ce:9.10.3-ce.0
        ports:
        - containerPort: 443
        - containerPort: 80
        - containerPort: 22
        volumeMounts:
        - name: gitlab-data
          mountPath: /var/opt/gitlab
        - name: gitlab-config
          mountPath: /etc/gitlab
        - name: gitlab-logs
          mountPath: /var/log/gitlab
        # 挂载 TLS 证书
        - name: tls-cert
          mountPath: /etc/gitlab/ssl
          readOnly: true
        resources:
          limits:
            cpu: 2
            memory: 4Gi
          requests:
            cpu: 1
            memory: 2Gi
      volumes:
      - name: gitlab-data
        persistentVolumeClaim:
          claimName: gitlab-data
      - name: gitlab-config
        persistentVolumeClaim:
          claimName: gitlab-config
      - name: gitlab-logs
        persistentVolumeClaim:
          claimName: gitlab-logs
      - name: tls-cert
        secret:
          secretName: gitlab-tls
---
# Service 使用 NodePort（无 LB）
apiVersion: v1
kind: Service
metadata:
  name: gitlab
  namespace: gitlab
spec:
  type: NodePort
  ports:
  - name: https
    port: 443
    nodePort: 30443
  - name: http
    port: 80
    nodePort: 30080
  - name: ssh
    port: 22
    nodePort: 30022
  selector:
    app: gitlab
---
# 简易 PVC（测试用，生产用 StorageClass）
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitlab-data
  namespace: gitlab
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 20Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitlab-config
  namespace: gitlab
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitlab-logs
  namespace: gitlab
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 5Gi
```



## 使用Let’s Encrypt 免费证书（公网，需 cert-manager）

```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
namespace/cert-manager created
Warning: resource customresourcedefinitions/certificaterequests.cert-manager.io is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
customresourcedefinition.apiextensions.k8s.io/certificaterequests.cert-manager.io configured
Warning: resource customresourcedefinitions/certificates.cert-manager.io is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
customresourcedefinition.apiextensions.k8s.io/certificates.cert-manager.io configured
Warning: resource customresourcedefinitions/challenges.acme.cert-manager.io is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
customresourcedefinition.apiextensions.k8s.io/challenges.acme.cert-manager.io configured
Warning: resource customresourcedefinitions/clusterissuers.cert-manager.io is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
customresourcedefinition.apiextensions.k8s.io/clusterissuers.cert-manager.io configured
Warning: resource customresourcedefinitions/issuers.cert-manager.io is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
customresourcedefinition.apiextensions.k8s.io/issuers.cert-manager.io configured
Warning: resource customresourcedefinitions/orders.acme.cert-manager.io is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
customresourcedefinition.apiextensions.k8s.io/orders.acme.cert-manager.io configured
serviceaccount/cert-manager-cainjector created
serviceaccount/cert-manager created
serviceaccount/cert-manager-webhook created
configmap/cert-manager created
configmap/cert-manager-webhook created
clusterrole.rbac.authorization.k8s.io/cert-manager-cainjector created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-issuers created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificates created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-orders created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-challenges created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim created
clusterrole.rbac.authorization.k8s.io/cert-manager-cluster-view created
clusterrole.rbac.authorization.k8s.io/cert-manager-view created
clusterrole.rbac.authorization.k8s.io/cert-manager-edit created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-approve:cert-manager-io created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificatesigningrequests created
clusterrole.rbac.authorization.k8s.io/cert-manager-webhook:subjectaccessreviews created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-cainjector created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-issuers created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificates created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-orders created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-challenges created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-approve:cert-manager-io created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificatesigningrequests created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-webhook:subjectaccessreviews created
role.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection created
role.rbac.authorization.k8s.io/cert-manager:leaderelection created
role.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving created
rolebinding.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection created
rolebinding.rbac.authorization.k8s.io/cert-manager:leaderelection created
rolebinding.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving created
service/cert-manager created
service/cert-manager-webhook created
deployment.apps/cert-manager-cainjector created
deployment.apps/cert-manager created
deployment.apps/cert-manager-webhook created
mutatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook created
validatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook created
[root@kube-master cert]# kubectl wait --for=condition=available deployment --timeout=600s -n cert-manager cert-manager
deployment.apps/cert-manager condition met

```



```
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set installCRDs=true
 
```



**创建 ClusterIssuer** (申请证书的 Issuer):
创建文件 `letsencrypt-issuer.yaml`，填入有效的 email:

```
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```



**验证证书签发状态**：

```
[root@kube-master helm]# kubectl get certificaterequests -n gitlab
No resources found in gitlab namespace.
[root@kube-master helm]# kubectl get secrets -n gitlab | grep tls
gitlab-kas-tls                        kubernetes.io/tls    2      3h31m
gitlab-tls                            kubernetes.io/tls    2      31m

```

### 四、验证 HTTPS 访问

1. 等待 5–10 分钟（证书签发与 Ingress 生效）。

2. 访问各域名：

   - `https://gitlab.example.com`
   - `https://registry.example.com`

   

3. 浏览器地址栏显示**安全锁**，证书信息为 **Let's Encrypt** 即成功。

4. **Ingress 未自动配置 TLS**

   - 确认 `global.ingress.configureCertmanager=true`。
   - 确认 Ingress Annotations 包含 `cert-manager.io/cluster-issuer: letsencrypt-prod`。

```
#gitlab-certmanager-56f499845-krql8
I0413 15:33:27.382171       1 warnings.go:110] "Warning: spec.privateKey.rotationPolicy: In cert-manager >= v1.18.0, the default value changed from `Never` to `Always`." logger="cert-manager.controller.ingress-shim" resource_name="gitlab-kas" resource_namespace="gitlab" resource_kind="" resource_version=""


I0413 16:11:27.821795       1 controller.go:152] "re-queuing item due to optimistic locking on resource" logger="cert-manager.controller" error="Operation cannot be fulfilled on issuers.cert-manager.io \"gitlab-gw-issuer\": the object has been modified; please apply your changes to the latest version and try again"

###gitlab-certmanager-cainjector-6d6c8c8cdb-hjbs8
E0413 15:44:29.650975       1 sources.go:183] "unable to fetch associated secret" err="secrets \"cert-manager-webhook-ca\" not found" logger="cert-manager" kind="mutatingwebhookconfiguration" kind="mutatingwebhookconfiguration" name="cert-manager-webhook" secret="cert-manager/cert-manager-webhook-ca"
I0413 15:44:29.651134       1 reconciler.go:117] "could not find any ca data in data source for target" logger="cert-manager" kind="mutatingwebhookconfiguration" kind="mutatingwebhookconfiguration" name="cert-manager-webhook"
E0413 15:44:29.662047       1 sources.go:183] "unable to fetch associated secret" err="secrets \"cert-manager-webhook-ca\" not found" logger="cert-manager" kind="validatingwebhookconfiguration" kind="validatingwebhookconfiguration" name="cert-manager-webhook" secret="cert-manager/cert-manager-webhook-ca"
I0413 15:44:29.662068       1 reconciler.go:117] "could not find any ca data in data source for target" logger="cert-manager" kind="validatingwebhookconfiguration" kind="validatingwebhookconfiguration" name="cert-manager-webhook"

###gitlab-certmanager-webhook-75469dd45c-ghmjv
I0413 15:32:04.140265       1 dynamic_source.go:289] "Updated cert-manager TLS certificate" logger="cert-manager" DNSNames=["gitlab-certmanager-webhook","gitlab-certmanager-webhook.gitlab","gitlab-certmanager-webhook.gitlab.svc"]
I0413 15:32:14.939454       1 ???:1] "http: TLS handshake error from 192.168.221.192:46880: remote error: tls: bad certificate"
I0413 15:32:19.946454       1 ???:1] "http: TLS handshake error from 192.168.221.192:15334: remote error: tls: bad certificate"
I0413 15:32:24.938697       1 ???:1] "http: TLS handshake error from 192.168.221.192:17860: remote error: tls: bad certificate"
I0413 15:32:29.941810       1 ???:1] "http: TLS handshake error from 192.168.221.192:14729: remote error: tls: bad certificate"


```

[root@kube-master nginx]# kubectl logs -n gitlab -l app=certmanager

```
kubectl get certificates,certificaterequests,issuers -n gitlab

[root@kube-master nginx]# kubectl get certificates -n gitlab
NAME             READY   SECRET           AGE
gitlab-kas-tls   True    gitlab-kas-tls   46m
[root@kube-master nginx]# kubectl get certificaterequests -n gitlab
No resources found in gitlab namespace.
[root@kube-master nginx]# kubectl get issuers -n gitlab
NAME               READY   AGE
gitlab-gw-issuer   True    8m33s
gitlab-issuer      True    3h46m
[root@kube-master nginx]#


```

```
helm upgrade gitlab gitlab/gitlab -f values.yaml -n gitlab  \
  --set nginx-ingress.controller.service.type=NodePort \
  --set nginx-ingress.controller.service.nodePorts.https=30443 \
  --set nginx-ingress.controller.service.nodePorts.http=30080
```



```
helm upgrade gitlab gitlab/gitlab -f values.yaml -n gitlab  \
  \
  --set global.hosts.https=true \
  --set global.ingress.tls.enabled=true \
  --set global.ingress.configureCertmanager=true \
  \
  --set certmanager-issuer.email=lmgsanm@163.com \
  --set certmanager-issuer.server=https://acme-v02.api.letsencrypt.org/directory \
  \
  --set nginx-ingress.controller.service.type=NodePort \
  --set nginx-ingress.controller.service.nodePorts.http=30080 \
  --set nginx-ingress.controller.service.nodePorts.https=30443 \
  \
  --set global.ingress.annotations."kubernetes.io/ingress.class"=gitlab-nginx \
  --set global.ingress.annotations."cert-manager.io/cluster-issuer"=letsencrypt-prod
```

```
helm upgrade gitlab gitlab/gitlab -f values.yaml -n gitlab  \
  \
  --set global.hosts.https=true \
  --set global.ingress.tls.enabled=true \
  --set global.ingress.configureCertmanager=true \
  \
  --set certmanager-issuer.email=lmgsanm@163.com \
  --set certmanager-issuer.server=https://acme-v02.api.letsencrypt.org/directory \
  \
  --set nginx-ingress.controller.service.type=NodePort \
  --set nginx-ingress.controller.service.nodePorts.http=30080 \
  --set nginx-ingress.controller.service.nodePorts.https=30443 \
  \
  --set global.ingress.annotations."kubernetes.io/ingress.class"=gitlab-nginx \
  --set global.ingress.annotations."cert-manager.io/cluster-issuer"=ClusterIssuer
```



```
helm upgrade gitlab gitlab/gitlab -f values.yaml -n gitlab  \
  --set global.hosts.https=true \
  --set global.ingress.tls.enabled=true \
  --set global.ingress.configureCertmanager=true \
  --set nginx-ingress.controller.service.type=NodePort \
  --set nginx-ingress.controller.service.nodePorts.http=30080 \
  --set nginx-ingress.controller.service.nodePorts.https=30443 
```



```
[root@kube-master ~]# kubectl get pod -n gitlab
NAME                                               READY   STATUS      RESTARTS         AGE
gitlab-certmanager-56f499845-krql8                 1/1     Running     0                90m
gitlab-certmanager-cainjector-6d6c8c8cdb-hjbs8     1/1     Running     0                90m
gitlab-certmanager-webhook-75469dd45c-ghmjv        1/1     Running     0                90m
gitlab-gitaly-0                                    1/1     Running     0                90m
gitlab-gitlab-exporter-6f7d4bfb8f-p5tgx            1/1     Running     0                90m
gitlab-gitlab-runner-6f7f8b79dc-tpzcf              1/1     Running     20 (7m18s ago)   90m
gitlab-gitlab-shell-865f5d9f89-mxhdd               1/1     Running     0                89m
gitlab-gitlab-shell-865f5d9f89-tdvhb               1/1     Running     0                90m
gitlab-issuer-0254a48-b2trx                        0/1     Completed   0                2m
gitlab-issuer-bfcbe6a-7rrjr                        0/1     Completed   0                3m14s
gitlab-issuer-c624a0e-449ll                        0/1     Completed   0                7m30s
gitlab-issuer-e0716a2-g5l5g                        0/1     Completed   0                4m34s
gitlab-issuer-e74b94c-dv2sn                        0/1     Completed   0                9m41s
gitlab-kas-bb5c79c8-cm22b                          1/1     Running     2 (89m ago)      89m
gitlab-kas-bb5c79c8-j8ks7                          1/1     Running     3 (89m ago)      90m
gitlab-migrations-2504fc3-dv5gj                    0/1     Completed   0                7m30s
gitlab-migrations-514e2ee-cwzws                    0/1     Completed   0                2m
gitlab-migrations-531425c-p6ppq                    0/1     Completed   0                3m14s
gitlab-migrations-b7265d9-n9v9p                    0/1     Completed   0                4m34s
gitlab-migrations-e033039-m4hzh                    0/1     Completed   0                9m41s
gitlab-minio-6577f858fb-pmj8d                      1/1     Running     0                90m
gitlab-minio-create-buckets-2994294-khz9r          0/1     Completed   0                4m34s
gitlab-minio-create-buckets-4bce29f-8tgs8          0/1     Completed   0                2m
gitlab-minio-create-buckets-9726c45-nzxlc          0/1     Completed   0                9m41s
gitlab-minio-create-buckets-ac990d5-hf87r          0/1     Completed   0                3m14s
gitlab-minio-create-buckets-b507124-d6wkw          0/1     Completed   0                7m30s
gitlab-nginx-ingress-controller-6d6fff8bdc-2q8x2   1/1     Running     0                89m
gitlab-nginx-ingress-controller-6d6fff8bdc-2t6l2   1/1     Running     0                89m
gitlab-postgresql-0                                2/2     Running     0                90m
gitlab-redis-master-0                              2/2     Running     0                90m
gitlab-registry-7bc8cfd849-4888w                   1/1     Running     0                89m
gitlab-registry-7bc8cfd849-gpvkh                   1/1     Running     0                89m
gitlab-sidekiq-all-in-1-v2-585c947b48-swvlh        1/1     Running     0                2m
gitlab-toolbox-5d984ccc8-xq6xp                     1/1     Running     0                89s
gitlab-webservice-default-5478794659-zm8pv         2/2     Running     0                8m16s
gitlab-webservice-default-66b4877864-6d5xj         2/2     Running     0                2m
gitlab-webservice-default-66b4877864-9cm75         1/2     Running     0                51s

```

## MetalLB 

```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.3/config/manifests/metallb-native.yaml
[root@kube-master ~]# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.3/config/manifests/metallb-native.yaml
namespace/metallb-system created
customresourcedefinition.apiextensions.k8s.io/bfdprofiles.metallb.io created
customresourcedefinition.apiextensions.k8s.io/bgpadvertisements.metallb.io created
customresourcedefinition.apiextensions.k8s.io/bgppeers.metallb.io created
customresourcedefinition.apiextensions.k8s.io/communities.metallb.io created
customresourcedefinition.apiextensions.k8s.io/configurationstates.metallb.io created
customresourcedefinition.apiextensions.k8s.io/ipaddresspools.metallb.io created
customresourcedefinition.apiextensions.k8s.io/l2advertisements.metallb.io created
customresourcedefinition.apiextensions.k8s.io/servicebgpstatuses.metallb.io created
customresourcedefinition.apiextensions.k8s.io/servicel2statuses.metallb.io created
serviceaccount/controller created
serviceaccount/speaker created
role.rbac.authorization.k8s.io/controller created
role.rbac.authorization.k8s.io/pod-lister created
clusterrole.rbac.authorization.k8s.io/metallb-system:controller created
clusterrole.rbac.authorization.k8s.io/metallb-system:speaker created
rolebinding.rbac.authorization.k8s.io/controller created
rolebinding.rbac.authorization.k8s.io/pod-lister created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:controller created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:speaker created
configmap/metallb-excludel2 created
secret/metallb-webhook-cert created
service/metallb-webhook-service created
deployment.apps/controller created
daemonset.apps/speaker created

[root@kube-master ~]# kubectl get pods -n metallb-system
NAME                          READY   STATUS    RESTARTS   AGE
controller-6cb594c767-bktks   1/1     Running   0          33s
speaker-h4rcm                 1/1     Running   0          33s
speaker-x47r7                 1/1     Running   0          33s

```

