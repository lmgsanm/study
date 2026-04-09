## 1、Deployment的升级

### 更新策略

通过spec.strategy指定Pod更新策略

- **Recreate**（重建）：设置spec.strategy.type=Recreat，表示Deployment在更新Pod时，会先“杀掉”所在正在运行的Pod，然后创建新的Pod
- **RollingUpdate**（滚动更新）：默认策略，表示以滚动的方式来逐个更新Pod

### 滚动更新的2个参数

1. spec.strategy.rollingUpdate.maxUnavailabe：用于指定Deployment在更新过程中不可用状态的Pod数据上限。
2. spec.strategy.rollingUpdate.maxSurge：用于用于指定Deployment更新Pod总数据超过Pod期望副本数据部分的最大值。

### 多重更新（Rollover）的情况

如果Deploment在上一次更新正在进行，此时用户再次发起Deployment的更新操作，那么Deployment会为每一次更新都创建一个ReplicaSet，而每次在新的ReplicaSet创建成功后，会逐个增加Pod副本数据，同时将之前正在扩容的ReplicaSet停止扩容（更新），并将其加入旧版本ReplicaSet列表中，然后开始缩容至0的操作。

### Deployment标签选择器的更新注意事项

1. 添加选择器标签时，必须同步修改Deployment配置的Pod的标签，为Pod添加新的标签，否则Deployment的更新会报验证错误而失败。添加标签选择器是无法向后兼容的。
2. 更新标签选择器，即更新选择器中标签的键或者值，也会产生与添加选择器标签相似的效果
3. 删除标签选择器，即从Deployment的标签选择器中删除一个或者多个标签，该Deployment的ReplicaSet和Pod不会受到任何影响。但，被删除的标签仍会存在于现有的Pod和ReplicaSet上。

### 使用示例

#### nginx-deployment.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: docker.m.daocloud.io/nginx:1.28.3
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
```

#### 运行结果

```
[root@kube-master study]# kubectl create -f nginx-deployment.yaml
[root@kube-master study]# kubectl get pod -l app=nginx --watch
NAME                              READY   STATUS    RESTARTS   AGE
nginx-deployment-7c9bdb8f-dmf94   1/1     Running   0          12m
nginx-deployment-7c9bdb8f-mjv65   1/1     Running   0          12m
nginx-deployment-7c9bdb8f-zp8xb   1/1     Running   0          12m
[root@kube-master study]# kubectl set image deploy/nginx-deployment nginx=docker.m.daocloud.io/nginx:1.29
deployment.apps/nginx-deployment image updated
[root@kube-master ~]# kubectl get pod -l app=nginx --watch
NAME                              READY   STATUS    RESTARTS   AGE
nginx-deployment-7c9bdb8f-dmf94   1/1     Running   0          12m
nginx-deployment-7c9bdb8f-mjv65   1/1     Running   0          12m
nginx-deployment-7c9bdb8f-zp8xb   1/1     Running   0          12m
nginx-deployment-54bb58944f-zfl6t   0/1     Pending   0          0s
nginx-deployment-54bb58944f-zfl6t   0/1     Pending   0          0s
nginx-deployment-54bb58944f-zfl6t   0/1     ContainerCreating   0          0s
nginx-deployment-54bb58944f-zfl6t   0/1     ContainerCreating   0          1s
nginx-deployment-54bb58944f-zfl6t   1/1     Running             0          2s
nginx-deployment-7c9bdb8f-mjv65     1/1     Terminating         0          14m
nginx-deployment-54bb58944f-kws2m   0/1     Pending             0          0s
nginx-deployment-54bb58944f-kws2m   0/1     Pending             0          0s
nginx-deployment-54bb58944f-kws2m   0/1     ContainerCreating   0          0s
nginx-deployment-7c9bdb8f-mjv65     1/1     Terminating         0          14m
nginx-deployment-7c9bdb8f-mjv65     0/1     Terminating         0          14m
nginx-deployment-54bb58944f-kws2m   0/1     ContainerCreating   0          1s
nginx-deployment-7c9bdb8f-mjv65     0/1     Terminating         0          14m
nginx-deployment-7c9bdb8f-mjv65     0/1     Terminating         0          14m
nginx-deployment-54bb58944f-kws2m   1/1     Running             0          2s
nginx-deployment-7c9bdb8f-dmf94     1/1     Terminating         0          14m
nginx-deployment-54bb58944f-drsh2   0/1     Pending             0          0s
nginx-deployment-54bb58944f-drsh2   0/1     Pending             0          0s
nginx-deployment-54bb58944f-drsh2   0/1     ContainerCreating   0          0s
nginx-deployment-7c9bdb8f-dmf94     1/1     Terminating         0          14m
nginx-deployment-7c9bdb8f-dmf94     0/1     Terminating         0          14m
nginx-deployment-54bb58944f-drsh2   0/1     ContainerCreating   0          1s
nginx-deployment-7c9bdb8f-dmf94     0/1     Terminating         0          14m
nginx-deployment-7c9bdb8f-dmf94     0/1     Terminating         0          14m
nginx-deployment-54bb58944f-drsh2   1/1     Running             0          2s
nginx-deployment-7c9bdb8f-zp8xb     1/1     Terminating         0          14m
nginx-deployment-7c9bdb8f-zp8xb     1/1     Terminating         0          14m
nginx-deployment-7c9bdb8f-zp8xb     0/1     Terminating         0          14m
nginx-deployment-7c9bdb8f-zp8xb     0/1     Terminating         0          14m
nginx-deployment-7c9bdb8f-zp8xb     0/1     Terminating         0          14m
^C[root@kube-master ~]# kubectl get pod -l app=nginx
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-54bb58944f-drsh2   1/1     Running   0          10s
nginx-deployment-54bb58944f-kws2m   1/1     Running   0          12s
nginx-deployment-54bb58944f-zfl6t   1/1     Running   0          14s
[root@kube-master ~]# kubectl rollout status deploy/nginx-deployment
deployment "nginx-deployment" successfully rolled out
[root@kube-master ~]# kubectl describe deploy/nginx-deployment
Name:                   nginx-deployment
Namespace:              default
CreationTimestamp:      Sat, 28 Mar 2026 21:04:01 +0800
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 2
Selector:               app=nginx
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=nginx
  Containers:
   nginx:
    Image:        docker.m.daocloud.io/nginx:1.29
    Port:         80/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  nginx-deployment-7c9bdb8f (0/0 replicas created)
NewReplicaSet:   nginx-deployment-54bb58944f (3/3 replicas created)
Events:
  Type    Reason             Age    From                   Message
  ----    ------             ----   ----                   -------
  Normal  ScalingReplicaSet  16m    deployment-controller  Scaled up replica set nginx-deployment-7c9bdb8f to 3
  Normal  ScalingReplicaSet  2m15s  deployment-controller  Scaled up replica set nginx-deployment-54bb58944f to 1
  Normal  ScalingReplicaSet  2m13s  deployment-controller  Scaled down replica set nginx-deployment-7c9bdb8f to 2 from 3
  Normal  ScalingReplicaSet  2m13s  deployment-controller  Scaled up replica set nginx-deployment-54bb58944f to 2 from 1
  Normal  ScalingReplicaSet  2m11s  deployment-controller  Scaled down replica set nginx-deployment-7c9bdb8f to 1 from 2
  Normal  ScalingReplicaSet  2m11s  deployment-controller  Scaled up replica set nginx-deployment-54bb58944f to 3 from 2
  Normal  ScalingReplicaSet  2m9s   deployment-controller  Scaled down replica set nginx-deployment-7c9bdb8f to 0 from 1

[root@kube-master ~]# kubectl get rs
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-54bb58944f   3         3         3       3m38s
nginx-deployment-7c9bdb8f     0         0         0       17m

```

## 2、Deployment的回滚



```
[root@kube-master ~]# kubectl rollout history deploy/nginx-deployment
deployment.apps/nginx-deployment
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

[root@kube-master ~]# kubectl rollout history deploy/nginx-deployment --revision=1
deployment.apps/nginx-deployment with revision #1
Pod Template:
  Labels:       app=nginx
        pod-template-hash=7c9bdb8f
  Containers:
   nginx:
    Image:      docker.m.daocloud.io/nginx:1.28.3
    Port:       80/TCP
    Host Port:  0/TCP
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>

[root@kube-master ~]# kubectl rollout history deploy/nginx-deployment --revision=2
deployment.apps/nginx-deployment with revision #2
Pod Template:
  Labels:       app=nginx
        pod-template-hash=54bb58944f
  Containers:
   nginx:
    Image:      docker.m.daocloud.io/nginx:1.29
    Port:       80/TCP
    Host Port:  0/TCP
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
[root@kube-master ~]# kubectl describe deploy/nginx-deployment | grep Image
    Image:        docker.m.daocloud.io/nginx:1.29
[root@kube-master ~]# kubectl rollout undo deploy/nginx-deployment
deployment.apps/nginx-deployment rolled back
[root@kube-master ~]# kubectl describe deploy/nginx-deployment | grep Image
    Image:        docker.m.daocloud.io/nginx:1.28.3
[root@kube-master ~]# kubectl rollout undo deploy/nginx-deployment --to-revision=2
deployment.apps/nginx-deployment rolled back
[root@kube-master ~]# kubectl describe deploy/nginx-deployment | grep Image
    Image:        docker.m.daocloud.io/nginx:1.29

```

## 3、暂停和恢复Deployment的部署操作



```
[root@kube-master ~]# kubectl rollout history deploy/nginx-deployment                             deployment.apps/nginx-deployment
REVISION  CHANGE-CAUSE
3         <none>
4         <none>
[root@kube-master ~]# kubectl rollout pause deployment/nginx-deployment
deployment.apps/nginx-deployment paused
[root@kube-master ~]# kubectl describe deploy/nginx-deployment | grep Image
    Image:        docker.m.daocloud.io/nginx:1.29
[root@kube-master ~]# kubectl set image deploy/nginx-deployment nginx=docker.m.daocloud.io/nginx:1atest
deployment.apps/nginx-deployment image updated
[root@kube-master ~]# kubectl describe deploy/nginx-deployment | grep Image                           Image:        docker.m.daocloud.io/nginx:1atest
[root@kube-master ~]# kubectl rollout history deploy/nginx-deployment
deployment.apps/nginx-deployment
REVISION  CHANGE-CAUSE
3         <none>
4         <none>
[root@kube-master ~]# kubectl set resources deploy/nginx-deployment -c=nginx --limits=cpu=220m,memory=512Mi --record=true
[root@kube-master ~]# kubectl rollout history deploy/nginx-deployment
deployment.apps/nginx-deployment
REVISION  CHANGE-CAUSE
3         <none>
4         <none>
[root@kube-master ~]# kubectl rollout resume deployment/nginx-deployment                          deployment.apps/nginx-deployment resumed
[root@kube-master ~]# kubectl rollout history deploy/nginx-deployment
deployment.apps/nginx-deployment
REVISION  CHANGE-CAUSE
3         <none>
4         <none>
5         kubectl set resources deploy/nginx-deployment --containers=nginx --limits=cpu=220m,memory=512Mi --record=true
[root@kube-master ~]# kubectl describe deploy/nginx-deployment | grep Image                           Image:      docker.m.daocloud.io/nginx:1atest
[root@kube-master ~]# kubectl get rs
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-54bb58944f   3         3         3       24m
nginx-deployment-7c9bdb8f     0         0         0       38m
nginx-deployment-7d85d855b5   1         1         0       2m53s
[root@kube-master ~]# kubectl describe deploy/nginx-deployment
Name:                   nginx-deployment
Namespace:              default
CreationTimestamp:      Sat, 28 Mar 2026 21:04:01 +0800
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 5
                        kubernetes.io/change-cause: kubectl set resources deploy/nginx-deployment --containers=nginx --limits=cpu=220m,memory=512Mi --record=true
Selector:               app=nginx
Replicas:               3 desired | 1 updated | 4 total | 3 available | 1 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=nginx
  Containers:
   nginx:
    Image:      docker.m.daocloud.io/nginx:1atest
    Port:       80/TCP
    Host Port:  0/TCP
    Limits:
      cpu:        220m
      memory:     512Mi
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    ReplicaSetUpdated
OldReplicaSets:  nginx-deployment-7c9bdb8f (0/0 replicas created), nginx-deployment-54bb58944f (3/3 replicas created)
NewReplicaSet:   nginx-deployment-7d85d855b5 (1/1 replicas created)
Events:
  Type    Reason             Age                  From                   Message
  ----    ------             ----                 ----                   -------
  Normal  ScalingReplicaSet  38m                  deployment-controller  Scaled up replica set nginx-deployment-7c9bdb8f to 3
  Normal  ScalingReplicaSet  24m                  deployment-controller  Scaled up replica set nginx-deployment-54bb58944f to 1
  Normal  ScalingReplicaSet  24m                  deployment-controller  Scaled down replica set nginx-deployment-7c9bdb8f to 1 from 2
  Normal  ScalingReplicaSet  24m                  deployment-controller  Scaled up replica set nginx-deployment-54bb58944f to 3 from 2
  Normal  ScalingReplicaSet  24m                  deployment-controller  Scaled down replica set nginx-deployment-7c9bdb8f to 0 from 1
  Normal  ScalingReplicaSet  11m                  deployment-controller  Scaled up replica set nginx-deployment-7c9bdb8f to 1 from 0
  Normal  ScalingReplicaSet  11m                  deployment-controller  Scaled up replica set nginx-deployment-7c9bdb8f to 2 from 1
  Normal  ScalingReplicaSet  11m                  deployment-controller  Scaled down replica set nginx-deployment-54bb58944f to 2 from 3
  Normal  ScalingReplicaSet  11m                  deployment-controller  Scaled down replica set nginx-deployment-54bb58944f to 1 from 2
  Normal  ScalingReplicaSet  11m                  deployment-controller  Scaled up replica set nginx-deployment-7c9bdb8f to 3 from 2
  Normal  ScalingReplicaSet  11m                  deployment-controller  Scaled down replica set nginx-deployment-54bb58944f to 0 from 1
  Normal  ScalingReplicaSet  10m                  deployment-controller  Scaled up replica set nginx-deployment-54bb58944f to 1 from 0
  Normal  ScalingReplicaSet  10m (x2 over 24m)    deployment-controller  Scaled down replica set nginx-deployment-7c9bdb8f to 2 from 3
  Normal  ScalingReplicaSet  10m (x2 over 24m)    deployment-controller  Scaled up replica set nginx-deployment-54bb58944f to 2 from 1
  Normal  ScalingReplicaSet  3m34s (x4 over 10m)  deployment-controller  (combined from similar events): Scaled up replica set nginx-deployment-7d85d855b5 to 1


```

## 4、其它管理对象的更新策略

### **DaemonSet**的更新策略

1. **OnDelete**：DaemonSet的默认升级策略，即只有手工删除了DaemonSet创建的Pod副本，新的Pod副本才会被创建出来
2. **RollingUpdate**：当使用RollingUpdate作为升级策略对DaemonSet进行更新时，旧版本的Pod将被自动“杀掉”，然后自动创建新版本的DaemonSet。（1）目前Kubernetes还不支持查看和管理DaemonSet的更新历史记录；（2）DaemonSet的回滚（Rollback）并不能如同Deployment一样直接通过kubectl，rollback命令来实现，必须通过再次提交旧版本配置的方式实现

### **StatefulSet**的更新策略

1. **RollingUpdate**：StatefulSet Controller会删除并创建StatefulSet相关的每个Pod对象，其处理顺序与StatefulSet终止Pod的顺序一致，即从序号最大的Pod开始重建，每次更新一个Pod。（如果StatefulSet的Pod Management Policy被设置为OrderedReady，则可能在更新过程中发生一些意外，从而导致StatefulSet陷入奔溃状态，此时需要用户手动修复）
2. **OnDelete**：StatefulSetController并不会自动更新StatefulSet中的Pod实例，而是需要用户手动删除这些Pod并触发StatefulSet Controller创建新的Pod实例来弥补，这其实是一种手动升级模式
3. **Partitioned**（分区升级策略）：在这种模式下，用户指定一个序号，StatefulSet中序号大于等于此序号的Pod实例会全部被升级，小于此序号的Pod实例则保留旧版本不变，即使这些Pod被删除、重建，也仍然保持原来的旧版本。这种分区升级策略通常用于按计划分步骤的系统升级过程中