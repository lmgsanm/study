## **应用场景**

- 等待其他关联组件正确运行（例如数据库或某个后台服务）
- 基于环境变量或配置模板生成配置文件
- 从远程数据库获取本地所需配置，或者将自身注册到某个中央数据库中
- 载相关依赖包，或者对系统进行一些预配置操

InitContainer与应用容器在本质上是一样的，但它们是仅运行一次就结束的任务，并且必须在成功运行完成后，系统才能继续执行下一个容器。

根据Pod的重启策略（RestartPolicy）,当InitContainer运行失败且设置了RestartPolicy=Nerver时，Pod将会启动失败，而设置RestartPolicy=Always时，Pod将会被系统自动重启。

## init container和应用容器的区别

1. init container的运行方式和应用容器不同，它必须**先于应用容器执行完成**，当设置了多个init container时，将按顺序逐个运行，并且只有前一个init container运行成功后才能运行后一个init container。在所有 init container都成功运行后，Kubernetes才会初始化Pod的各种信息，并开始创建和运行应用容器。
2. 在init container的定义中也可以设置资源限制、Volume的使用和安全策略等等，但是资源限制的设置和应用容器略有不同。
3. init container不能设置readinessProbe探针，因为必须在它们成功运行才能继续运行在Pod中定义的普通容器

## init container资源策略

- 如果多个init container都定义了资源请求/资源限制时，则取最大的值作为所有init container的资源请求值/资源限制值
- Pod的有效资源请求值/资源限制值取以下二者中的较大值：
  1. 所有应用容器的资源请求值/资源限制值之和
  2. init container的有效资源请求值/资源限制值
- 调度算法将基于Pod的有效请求值/资源限制值进行计算，也就是说init container可以为初始化操作预留系统资源，即使后续应用容器无须使用这些资源
- Pod的有效QoS等级适用于init container和应用容器
- 资源配额和限制将根据Pod的有效请求值/资源限制值计算生效
- Pod级别的cgroup将基于Pod的有效请求/资源限制，与调度机制一致。

## Pod重启场景

- init container的镜像被更新时，init container将会重新运行，导致Pod重启。只更新应用容器的镜像只会使用应用容器被重启
- Pod的infrastructure容器更新时，Pod将会重启
- 若Pod中的所有应用容器都终止了，并且RestartPolicy=Always，则Pod会重启



## 使用示例1

### nginx-init-containers.yaml

```
apiVersion: v1 
kind: Pod
metadata:
  name: nginx-init-containers
  labels:
    app: "nginx"
    announce: "init-containers"
spec:
  initContainers:
  - name: init-install
    image: docker.m.daocloud.io/busybox:latest
    imagePullPolicy: IfNotPresent
    command: 
    - wget
    - "-O"
    - "/work-dir/index.html"
    - "https://kubernetes.io"
    volumeMounts:
    - name: workdir
      mountPath: /work-dir
  containers:
  - name: nginx
    image: docker.m.daocloud.io/nginx:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
    volumeMounts:
    - name: workdir
      mountPath: /usr/share/nginx/html
  dnsPolicy: Default
  volumes:
  - name: workdir
    emptyDir: {}
```

### 运行结果

```
[root@kube-master study]# kubectl create -f nginx-init-containers.yaml
pod/nginx-init-containers created
[root@kube-master study]# kubectl get pod -l app=nginx
NAME                    READY   STATUS    RESTARTS   AGE
nginx-init-containers   1/1     Running   0          70s
[root@kube-master study]# kubectl describe pod nginx-init-containers
Name:             nginx-init-containers
Namespace:        default
Priority:         0
Service Account:  default
Node:             kube-node03/192.168.1.14
Start Time:       Sat, 28 Mar 2026 18:48:40 +0800
Labels:           announce=init-containers
                  app=nginx
Annotations:      cni.projectcalico.org/containerID: 6059018442e623947c942d9d5292c98adf48e181091999bb6bcaeb4662d906ac
                  cni.projectcalico.org/podIP: 172.17.74.83/32
                  cni.projectcalico.org/podIPs: 172.17.74.83/32
Status:           Running
IP:               172.17.74.83
IPs:
  IP:  172.17.74.83
Init Containers:
  init-install:
    Container ID:  docker://93fe523e9bf407f24e2c94fe9eab04ffae21461f1c05f577f209a5eb22c0e0e0
    Image:         docker.m.daocloud.io/busybox:latest
    Image ID:      docker-pullable://docker.m.daocloud.io/busybox@sha256:1487d0af5f52b4ba31c7e465126ee2123fe3f2305d638e7827681e7cf6c83d5e
    Port:          <none>
    Host Port:     <none>
    Command:
      wget
      -O
      /work-dir/index.html
      https://kubernetes.io
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Sat, 28 Mar 2026 18:48:41 +0800
      Finished:     Sat, 28 Mar 2026 18:48:42 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-q69zf (ro)
      /work-dir from workdir (rw)
Containers:
  nginx:
    Container ID:   docker://2796682bda348941a4f4cd435134a82ce287f2bb1be4d78d719966556035ebda
    Image:          docker.m.daocloud.io/nginx:latest
    Image ID:       docker-pullable://docker.m.daocloud.io/nginx@sha256:7150b3a39203cb5bee612ff4a9d18774f8c7caf6399d6e8985e97e28eb751c18
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Sat, 28 Mar 2026 18:48:43 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /usr/share/nginx/html from workdir (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-q69zf (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
Volumes:
  workdir:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:
    SizeLimit:  <unset>
  kube-api-access-q69zf:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  3m32s  default-scheduler  Successfully assigned default/nginx-init-containers to kube-node03
  Normal  Pulled     3m32s  kubelet            Container image "docker.m.daocloud.io/busybox:latest" already present on machine
  Normal  Created    3m32s  kubelet            Created container: init-install
  Normal  Started    3m32s  kubelet            Started container init-install
  Normal  Pulled     3m30s  kubelet            Container image "docker.m.daocloud.io/nginx:latest" already present on machine
  Normal  Created    3m30s  kubelet            Created container: nginx
  Normal  Started    3m30s  kubelet            Started container nginx

[root@kube-master study]# kubectl logs nginx-init-containers -c init-install
Connecting to kubernetes.io (3.33.186.135:443)
wget: note: TLS certificate validation not implemented
saving to '/work-dir/index.html'
index.html           100% |********************************| 38308  0:00:00 ETA
'/work-dir/index.html' saved

[root@kube-master study]# kubectl exec -it nginx-init-containers  -c nginx -- sh
# cd /usr/share/nginx/html
# ls
index.html

[root@kube-master study]# kubectl logs nginx-init-containers -c nginx
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2026/03/28 10:48:43 [notice] 1#1: using the "epoll" event method
2026/03/28 10:48:43 [notice] 1#1: nginx/1.29.7
2026/03/28 10:48:43 [notice] 1#1: built by gcc 14.2.0 (Debian 14.2.0-19)
2026/03/28 10:48:43 [notice] 1#1: OS: Linux 5.10.222-1.el7.x86_64
2026/03/28 10:48:43 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2026/03/28 10:48:43 [notice] 1#1: start worker processes
2026/03/28 10:48:43 [notice] 1#1: start worker process 29
2026/03/28 10:48:43 [notice] 1#1: start worker process 30


```

## 使用示例2

### init-container-example.yaml

```
apiVersion: v1
kind: Pod
metadata: 
  name: init-container-example
  labels:
    app: "init-container-example"

spec:
  initContainers: 
  - name: init-myservice
    image: docker.m.daocloud.io/busybox:latest
    imagePullPolicy: IfNotPresent
    command: ['sh', '-c', 'echo 初始化第一步']
  - name: init-myservice2
    image: docker.m.daocloud.io/busybox:latest  
    imagePullPolicy: IfNotPresent
    command: ['sh', '-c', 'echo 初始化第二步；'] 
  - name: init-myservice3
    image: docker.m.daocloud.io/busybox:latest  
    imagePullPolicy: IfNotPresent
    command: ['sh', '-c', 'echo 初始化第三步；']
  containers:
  - name: nginx
    image: docker.m.daocloud.io/nginx:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
```

### 运行结果

```
[root@kube-master study]# kubectl create -f init-container-example.yaml
pod/init-container-example created
[root@kube-master study]# kubectl describe pod init-container-example
Name:             init-container-example
Namespace:        default
Priority:         0
Service Account:  default
Node:             kube-node02/192.168.1.13
Start Time:       Sat, 28 Mar 2026 19:24:45 +0800
Labels:           app=init-container-example
Annotations:      cni.projectcalico.org/containerID: f81cb7313de3547d1712a7839c1a345be1d62be6356b5afd43c234a64c206b06
                  cni.projectcalico.org/podIP: 172.23.127.96/32
                  cni.projectcalico.org/podIPs: 172.23.127.96/32
Status:           Running
IP:               172.23.127.96
IPs:
  IP:  172.23.127.96
Init Containers:
  init-myservice:
    Container ID:  docker://5b179d2f6014fc91770fb050b9e0be5a8c5d346ce102d358ded4456d3059e8b8
    Image:         docker.m.daocloud.io/busybox:latest
    Image ID:      docker-pullable://docker.m.daocloud.io/busybox@sha256:1487d0af5f52b4ba31c7e465126ee2123fe3f2305d638e7827681e7cf6c83d5e
    Port:          <none>
    Host Port:     <none>
    Command:
      sh
      -c
      echo 初始化第一步；sleep 30
      sleep 30
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Sat, 28 Mar 2026 19:24:47 +0800
      Finished:     Sat, 28 Mar 2026 19:24:47 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-d458h (ro)
  init-myservice2:
    Container ID:  docker://5b5b6f6ed568e166b9b01a7fa8efd5b9413b0bf524f429b172357f8d5797e9dd
    Image:         docker.m.daocloud.io/busybox:latest
    Image ID:      docker-pullable://docker.m.daocloud.io/busybox@sha256:1487d0af5f52b4ba31c7e465126ee2123fe3f2305d638e7827681e7cf6c83d5e
    Port:          <none>
    Host Port:     <none>
    Command:
      sh
      -c
      echo 初始化第二步；sleep 30
      sleep 30
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Sat, 28 Mar 2026 19:24:47 +0800
      Finished:     Sat, 28 Mar 2026 19:24:47 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-d458h (ro)
  init-myservice3:
    Container ID:  docker://b7fb6e163d7815c461fb63099d6801cc0357bc6dc8c176625402854247dd06a9
    Image:         docker.m.daocloud.io/busybox:latest
    Image ID:      docker-pullable://docker.m.daocloud.io/busybox@sha256:1487d0af5f52b4ba31c7e465126ee2123fe3f2305d638e7827681e7cf6c83d5e
    Port:          <none>
    Host Port:     <none>
    Command:
      sh
      -c
      echo 初始化第三步；sleep 30
      sleep 30
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Sat, 28 Mar 2026 19:24:48 +0800
      Finished:     Sat, 28 Mar 2026 19:24:48 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-d458h (ro)
Containers:
  nginx:
    Container ID:   docker://56e0879bfdc667857884283bfba9ba36b2bf3043a58b1cbe6f94462263323836
    Image:          docker.m.daocloud.io/nginx:latest
    Image ID:       docker-pullable://docker.m.daocloud.io/nginx@sha256:7150b3a39203cb5bee612ff4a9d18774f8c7caf6399d6e8985e97e28eb751c18
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Sat, 28 Mar 2026 19:24:49 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-d458h (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
Volumes:
  kube-api-access-d458h:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  106s  default-scheduler  Successfully assigned default/init-container-example to kube-node02
  Normal  Pulled     106s  kubelet            Container image "docker.m.daocloud.io/busybox:latest" already present on machine
  Normal  Created    106s  kubelet            Created container: init-myservice
  Normal  Started    105s  kubelet            Started container init-myservice
  Normal  Pulled     105s  kubelet            Container image "docker.m.daocloud.io/busybox:latest" already present on machine
  Normal  Created    105s  kubelet            Created container: init-myservice2
  Normal  Started    105s  kubelet            Started container init-myservice2
  Normal  Pulled     104s  kubelet            Container image "docker.m.daocloud.io/busybox:latest" already present on machine
  Normal  Created    104s  kubelet            Created container: init-myservice3
  Normal  Started    104s  kubelet            Started container init-myservice3
  Normal  Pulled     103s  kubelet            Container image "docker.m.daocloud.io/nginx:latest" already present on machine
  Normal  Created    103s  kubelet            Created container: nginx
  Normal  Started    103s  kubelet            Started container nginx

```

