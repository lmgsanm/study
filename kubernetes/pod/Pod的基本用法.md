

## 1、Pod定义

kubernetes系统中对长时间运行的容器的要求是：其主程序需要一直在前台运行，如果我们创建的Docker镜像的启动命令是后台执行程序，，则在Kubelet创建包含这个容器的Pod之后运行完该后台命令，即认为Pod执行结束，将立刻销毁该Pod。

```
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
  namespace: example
  labels:
    - name: example
  annotations:
    - name: example
  spec:
    containers:
    - name: example-container
      images: registry.aliyuncs.com/nginx:latest
      imagePullPolicy: IfNotPresent
      commands: ["nginx", "-g", "daemon off;"]
      args: []
      workingDir: /usr/share/nginx/html
      volumeMounts:
      - name: example-volume
        mountPath: /usr/share/nginx/html
        readOnly: true
        ports:
        - name: nginx
          containerPort: 80
          hostPort: 80
          protocol: TCP
        env:
        - name: ENV_VAR_NAME
          value: ENV_VAR_VALUE
        resourceLimits:
          cpu: "500m"
          memory: "128Mi"
        resourcequeries:
          cpu: "250m"
          memory: "64Mi"
        livenessProbe:
          httpGet: strings
          exec: strings
          tcpSocket: strings
        readlinessProbe:
          httpGet: strings
          exec: strings
          tcpSocket: strings
        initialDelaySeconds: 10
        periodSeconds: 10
        timeoutSeconds: 1
        successThreshold: 1
        failureThreshold: 3
      securityContext:
        runAsUser: 1000
        runAsGroup: 3000
        fsGroup: 2000
    restartPolicy: Always
    nodeSelector:
      disktype: ssd
    imagePullPolicy: IfNotPresent
    volumes: 
    - name: example-1
      configMap:
        name: example-configmap
        projected: false
      items:
        - key: strings
          path: strings
    - name: example-2
      secret:
        secretName: example-secret
      items:
        - key: secret-key
          path: secret-key
    - name: example-3
      emptyDir: {}
      hostPath: 
        path: /data/example
        type: Directory
    - name: example-4

```



## 2、Pod对容器的封装和应用

### 场景一：只启动一个容器

frontend.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  labels:
    app: frontend
spec:
  containers:
  - name: frontend
    image: docker.m.daocloud.io/nginx:latest
    ports:
    - containerPort: 80
    env: 
    - name: GET_HOSTS_FROM
      value: env
```

### 场景二：启动多个耦合容器

frontend-redis-pod.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: frontend-redis
  labels:
    app: frontend-redis
spec:
  containers:
  - name: frontend
    image: docker.m.daocloud.io/nginx:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
    env: 
    - name: GET_HOSTS_FROM
      value: env
  - name: redis
    image: docker.m.daocloud.io/redis:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 6379
  - name: busybox
    image: docker.m.daocloud.io/busybox:latest
    imagePullPolicy: IfNotPresent
    command: ["sleep", "36000"]
```



```
kubectl exec -it frontend-redis -c busybox -- sh
telnet localhost 6379
telnet localhost 80
wget http://localhost/index.html
```

![image-20260325105107346](D:\lmgsanm\03-个人总结\kubernetes\pod\image-20260325105107346.png)

![](D:\lmgsanm\03-个人总结\kubernetes\pod\image-20260325104938700.png)



![image-20260325104957893](D:\lmgsanm\03-个人总结\kubernetes\pod\image-20260325104957893.png)

![image-20260325105017361](D:\lmgsanm\03-个人总结\kubernetes\pod\image-20260325105017361.png)



## 3、静态Pod

​	静态Pod是由kubelet进行管理的仅存在于特定的Node上的Pod。

​	不能通过API Server进行管理 ，无法也ReplicationController、Deployment或者DaemonSet进行关联，并且kubelet无法对它们进行健康检查。

### 配置文件方式创建

1. ​	设置kubelet的启动参数“--pod-manifest-path”（或staticPodPath），指定kubelet需要监控的配置文件所在目录，kubelet会定期扫描该目录，并根据该目录下的yaml或json文件进行创建

   kubelet配置文件为：/var/lib/kubelet/config.yaml

   ![image-20260325110058758](D:\lmgsanm\03-个人总结\kubernetes\pod\image-20260325110058758.png)

   ![image-20260325110308700](D:\lmgsanm\03-个人总结\kubernetes\pod\image-20260325110308700.png)

   ​	使用kubadm部署的集群，master节点上的管理镜像，即为静态Pod部署

   

2. 在node02上的/etc/kubernetes/manifests目录下放入web-static.yaml文件

   ```
   apiVersion: v1
   kind: Pod
   metadata:
     name: web-static
     labels:
       app: web-static
   spec:
     containers:
     - name: frontend
       image: docker.m.daocloud.io/nginx:latest
       ports:
       - containerPort: 80
       env: 
       - name: GET_HOSTS_FROM
         value: env
   ```

   ![image-20260325110839315](D:\lmgsanm\03-个人总结\kubernetes\pod\image-20260325110839315.png)

3. 如需删除静态Pod,需将yaml的文件从/etc/kubernetes/manifests删除

### HTTP方式创建

​	通过设置kubelet的启动参数“--manifest-url”，kubelet将会定期从该URL地址下载Pod的定义文件，并以yaml或json的格式进行解析，然后创建Pod。

## 4、Pod容器共享Volume

​		同一个Pod中的多个容器能够共享Pod级别的存储卷Volume。

​	Volume可以定义为各种类型，多个容器各自进行挂载操作，将一个Volume挂载为容器内部需要的目录。

```
apiVersion: v1
kind: Pod
metadata:
  name: volume-pod
spec:
  containers:
  - name: tomcat
    image: docker.m.daocloud.io/tomcat:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 8080
    volumeMounts:
    - name: app-log
      mountPath: /usr/local/tomcat/logs
  - name: busybox
    image: docker.m.daocloud.io/busybox:latest
    imagePullPolicy: IfNotPresent
    command: ["sh","-c", "tail -f /logs/catalina*.log"]
    volumeMounts:
    - name: app-log
      mountPath: /logs
    volumes:
    - name: app-log
      emptyDir: {}

```

![image-20260325112811243](D:\lmgsanm\03-个人总结\kubernetes\pod\image-20260325112811243.png)

## 5、Pod的配置管理

### 5.1	ConfigMap

​	典型用法：

1. ​	生成容器内的环境变量
2. 设置容器启动命令的启动参数（需设置为环境变量）
3. 以Volume的形式挂载为容器内部的文件或目录

​	ConfigMap以一个或多个key: value的形式保存在Kubernetes系统中供应用使用，既可以用于表示一个变量的值（如apploglever=info），也可以表示一个完整配置文件的内容



​	可使用“kubectl create configmap”创建或YAML文件创建



### 5.2	创建ConfigMap资源对象

#### 	使用YAML文件创建

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: cm-appvars
data: 
  appleverinfo: info 
  appdatadir: /var/data 
```

​	

```
kubectl create -f cm-appvars.yaml
kubectl get configmap
kubectl describe configmap cm-appvars
kubectl get configmap cm-appvars -o yaml
```

![image-20260325114138092](D:\lmgsanm\03-个人总结\kubernetes\pod\image-20260325114138092.png)

![image-20260325114206594](D:\lmgsanm\03-个人总结\kubernetes\pod\image-20260325114206594.png)

![image-20260325114231043](D:\lmgsanm\03-个人总结\kubernetes\pod\image-20260325114231043.png)

#### 使用kubctl创建

​	使用"kubectl create configmap"创建，可以使用参数--from-file或--frome-literal指定内容 

1. ​	使用--from-file参数从文件中创建，可以指定key的名称，也可以在一个命令行中创建包含多个key的ConfigMap

  ```
  kubectl create configmap name --from-file=[key=]source  ---from-file=[key=]source
  ```

  

2. 通过使用--from-file参数在目录下进行创建，该目录下的每个配置文件名都补充设置为key，文件内容被设置为value,语法如下：

  ```
  kubectl create configmap name --from-file=config-files-dir
  ```

3. 使用-from-literal时会从广西中进行创建，直接将指定的key=value创建为ConfigMap的内容，语法如下：

  ```
  kubectl create configmap name --from-literal=key1=value1 --from-literal=key2=value2
  ```


#### 5.3	在Pod中使用ConfigMap

##### 通过环境变量方式使用



```
apiVersion: v1
kind: ConfigMap
metadata:
  name: cm-appvars
data: 
  appleverinfo: info 
  appdatadir: /var/data 
```



```
apiVersion: v1
kind: Pod
metadata:
  name: cm-test-pod-env
spec:
  containers:
  - name: cm-test
    image: docker.m.daocloud.io/busybox:latest
    imagePullPolicy: IfNotPresent
    command: ["sleep", "36000"]
    env: 
    - name: APPLOG
      valueFrom:
        configMapKeyRef:
          name: cm-appvars
          key: appleverinfo
    - name: APPDATADIR
      valueFrom:
        configMapKeyRef:
          name: cm-appvars
          key: appdatadir
  restartPolicy: Never
```

```
[root@kube-master study]# kubectl describe cm cm-appvars
Name:         cm-appvars
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
appleverinfo:
----
info
appdatadir:
----
/var/data

BinaryData
====

[root@kube-master study]# kubectl exec -it cm-test-pod-env -- sh
/ # echo $APPLOG
info
/ # echo $APPDATADIR
/var/data
/ #

```



使用envFrom引用环境变量

```
apiVersion: v1
kind: Pod
metadata:
  name: cm-test-pod-envfrom
spec:
  containers:
  - name: cm-test-envfrom
    image: docker.m.daocloud.io/busybox:latest
    imagePullPolicy: IfNotPresent
    command: ["sleep", "36000"]
    envFrom:
    - configMapRef:
        name: cm-appvars
  restartPolicy: Never
```

```
[root@kube-master study]# kubectl exec -it cm-test-pod-envfrom -- sh
/ # env
KUBERNETES_PORT=tcp://10.96.0.1:443
KUBERNETES_SERVICE_PORT=443
HOSTNAME=cm-test-pod-envfrom
SHLVL=1
HOME=/root
NGINX_SERVICE_PORT_80_TCP=tcp://10.102.25.143:80
NGINX_PORT_80_TCP=tcp://10.96.160.194:80
TERM=xterm
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
NGINX_SERVICE_SERVICE_HOST=10.102.25.143
NGINX_SERVICE_HOST=10.96.160.194
KUBERNETES_PORT_443_TCP_PORT=443
KUBERNETES_PORT_443_TCP_PROTO=tcp
appdatadir=/var/data
NGINX_SERVICE_SERVICE_PORT=80
NGINX_SERVICE_PORT=tcp://10.102.25.143:80
NGINX_PORT=tcp://10.96.160.194:80
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
KUBERNETES_SERVICE_HOST=10.96.0.1
PWD=/
NGINX_PORT_80_TCP_ADDR=10.96.160.194
NGINX_SERVICE_PORT_80_TCP_ADDR=10.102.25.143
appleverinfo=info
NGINX_SERVICE_PORT_80_TCP_PORT=80
NGINX_PORT_80_TCP_PORT=80
NGINX_PORT_80_TCP_PROTO=tcp
NGINX_SERVICE_PORT_80_TCP_PROTO=tcp

```



##### 通过volumeMount使用ConfigMap

cm-appconfigfile.yaml

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: cm-appconfigfile
data:
  key-server.xml: |-
    server.xml,server.xmlserver.xmlserver.xmlxxxxxxxxx
  key-logconfig.conf: |-
    log4j.properties,log4j.properties,log4j.properties,log4j.properties
```

cm-testapp.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: cm-testapp
spec:
  containers:
  - name: cm-testapp-tomcat
    image: docker.m.daocloud.io/tomcat:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 8080
    volumeMounts:
    - name: serverxml
      mountPath: /configfiles 

  volumes:
  - name: serverxml
    configMap:
      name: cm-appconfigfile
      items:
      - key: key-server.xml 
        path: server.xml
      - key: key-logconfig.conf
        path: logconfig.conf
  
```



```
kubectl create -f cm-appconfigfile.yaml
kubectl create -f cm-testapp.yaml
[root@kube-master study]# kubectl get pod | grep cm-testapp
cm-testapp                          1/1     Running   0                   30s
[root@kube-master study]# kubectl get cm | grep cm-appconfigfile
cm-appconfigfile   2      6m20s
[root@kube-master study]# kubectl describe cm cm-appconfigfile
Name:         cm-appconfigfile
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
key-logconfig.conf:
----
log4j.properties,log4j.properties,log4j.properties,log4j.properties
key-server.xml:
----
server.xml,server.xmlserver.xmlserver.xmlxxxxxxxxx

BinaryData
====

Events:  <none>


[root@kube-master study]# kubectl exec -it cm-testapp -- sh
# cd /configfiles
# ls
logconfig.conf  server.xml
# cat logconfig.conf
log4j.properties,log4j.properties,log4j.properties,log4j.properties#
# cat server.xml
server.xml,server.xmlserver.xmlserver.xmlxxxxxxxxx#
#

```



​	引用ConfigMap时不指定item时，则使用volumeMount方式在容器内的目录下为每个item都生成一个文件名为key的文件

cm-testapp.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: cm-testapp
spec:
  containers:
  - name: cm-testapp-tomcat
    image: docker.m.daocloud.io/tomcat:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 8080
    volumeMounts:
    - name: serverxml
      mountPath: /configfiles 

  volumes:
  - name: serverxml
    configMap:
      name: cm-appconfigfile
      
  
```



```
[root@kube-master study]# kubectl exec -it cm-testapp -- sh
# cd
# ls /configfiles
key-logconfig.conf  key-server.xml
# cat /configfiles/key-logconfig.conf
log4j.properties,log4j.properties,log4j.properties,log4j.properties#
# cat /configfiles/key-server.xml
server.xml,server.xmlserver.xmlserver.xmlxxxxxxxxx#
#
#

```



### 5.4	使用ConfigMap的限制条件

- ConfigMap必须在Pod之前创建，Pod才能引用
- 如果Pod使用envFrom基本ConfigMap定义环境变量，则无效的环境名称（如名称以数字开头）将被忽略，并在事件中被记录为InvalidVariableNames
- ConfigMap受命名空间限制，只有处于相同命名空间中的Pod才能引用
- ConfigMap无法用于静态Pod



## 6、在容器内获取Pod信息（Downward API）

​	Pod的逻辑概念在容器之上，Kubernete在成功创建Pod之后，会为Pod和容器设置一些额外的信息，如Pod级别的Pod名称、Pod IP、Nod IP、Label、Annotation、容器级别的资源限制等。

​	在很多应用场景中，这些信息对容器内的就来说都很有用，例如使用Pod名称作为 日志记录中的一个字段用于标识日志来源。

​	为了在容器内获取Pod级别的这个信息，Kubernete提供了Downward API机制来将Pod和容器的某些元数据信息注入到容器环境，代容器应用方便地使用。

​		Downward APi通过以下两方式将Pod与容器的元数据信息注入容器内部

1. 环境变量：将Pod或Container信息设置为容器内的环境变量
2. Volume挂载：将Pod或Container信息以文件的形式挂载到容器内部

### 6.1	环境变量方式

#### 将Pod信息设置为容器内的环境变量

dapi-envar-pod.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: dapi-envar-pod
spec:
  containers:
  - name: dapi-envar-container
    image: docker.m.daocloud.io/busybox:latest
    imagePullPolicy: IfNotPresent
    command: ["sh","-c"]
    args:
    - while true; do echo '\n';
      printenv MY_NODE_NAME MY_POD_NAME MY_POD_NAMESPACE;
      printenv  MY_POD_IP MY_POD_SERVICE_ACCOUNT ;
      sleep 10;
      done
    env:
    - name: MY_NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
    - name: MY_POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: MY_POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: MY_POD_IP
      valueFrom: 
        fieldRef:
          fieldPath: status.podIP
    - name: MY_POD_SERVICE_ACCOUNT
      valueFrom:  
        fieldRef:
          fieldPath: spec.serviceAccountName
  restartPolicy: Never
```

注：环境变量不直接设置value，而设置valueFrom对Pod的元数据进行引用

执行结果：

```
kubectl apply -f dapi-envar-pod.yaml
[root@kube-master study]# kubectl logs dapi-envar-pod
\n
kube-node03
dapi-envar-pod
default
172.17.74.70
default

[root@kube-master study]# kubectl exec -it dapi-envar-pod -- sh
/ # printenv | grep MY
MY_POD_SERVICE_ACCOUNT=default
MY_POD_NAMESPACE=default
MY_POD_IP=172.17.74.70
MY_NODE_NAME=kube-node03
MY_POD_NAME=dapi-envar-pod
/ #

```



#### 将Container信息设置为容器内的环境变量

dapi-envar-container.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: dapi-envar-container
spec:
  containers:
  - name: dapi-envar-container
    image: docker.m.daocloud.io/busybox:latest
    imagePullPolicy: IfNotPresent
    command: ["sh","-c"]
    args:
    - while true; do echo -en '\n';
      printenv MY_CPU_REQUEST MY_CPU_LIMIT MY_MEMORY_REQUEST MY_MEMORY_LIMIT;
      sleep 10;
      done
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
    env: 
    - name: MY_CPU_REQUEST
      valueFrom:
        resourceFieldRef:
          containerName: dapi-envar-container
          resource: requests.cpu
    - name: MY_CPU_LIMIT
      valueFrom:
        resourceFieldRef:
          containerName: dapi-envar-container
          resource: limits.cpu
    - name: MY_MEMORY_REQUEST
      valueFrom:
        resourceFieldRef:
          containerName: dapi-envar-container
          resource: requests.memory
    - name: MY_MEMORY_LIMIT
      valueFrom:
        resourceFieldRef:
          containerName: dapi-envar-container
          resource: limits.memory
  restartPolicy: Never
```

执行结果

```
[root@kube-master study]# kubectl get pod dapi-envar-container
NAME                   READY   STATUS    RESTARTS   AGE
dapi-envar-container   1/1     Running   0          28s
[root@kube-master study]# kubectl logs dapi-envar-container

1
1
134217728
268435456

```



### 6.2	Volume挂载方式



### 6.3	Downward API支持设置的Pod和Container信息

## 7、Pod的生命周期和重启策略

#### 	Pod的状态

1. Pending：API Server已经创建该Pod，但是在Pod内还有一个或多个容器的镜像没有创建，包括正在下载镜像的过程
2. Running：Pod内所有容器均已创建，且至少有一个容器处于运行状态、正在启动状态或正在重启状态
3. Succeeded：Pod内所有容器均成功执行后退出，且不会再重启
4. Failed：Pod内所有容器均已退出，但至少有一个容器为退出失败状态
5. Unknown：由于某种原因无法获取该Pod的状态，可能由于网络通信不畅导致

#### Pod重启策略（RestartPolicy）

1. Always：当容器失效时，由kubelet自动重启该容器，默认为Always
2. Onfailure：当容器终止运行且退出码不为0时，由kubelet自动重启该容器
3. Never：不论容器运行状态如何，kubelet都不会重启该容器

​	kubelete重启失效的容器的时间间隔以sync-frequency乘以2n来计算，如何1、2、4、8倍等，最长延时5min，并且在成功重启后的10min后重置该时间

#### 控制器对Pod的重启策略要求

- RC和DaemonSet：必须设置为Always，需保证该容器持续运行
- Job：OnFailure或Never，确保容器执行完成后不到重启
- kubelet：在Pod失效时自动重启它，不论将RestartPolicy设置为什么值，也不会对Pod进行健康检查

## 8、Pod健康检查和服务可用性检查

### 三类检查探针

1. **LivenessProbe**：判断容器是否存活（Running状态），如果LivenessProbe探针探测到容器不健康，则kubelete将“杀掉”该容器。如果一个容器不包含LivenessProbe探针，kubelet认为该容器的LivenessProbe探针返回的值永远是Success
2. **ReadinessProbe**：判断容器服务是否可用（Ready状态），达到Ready状态的Pod才可以接收请求。对于被Service管理的Pod，Service与Pod Endpoint的关联系统也将基于Pod是否Ready进行设置。如果在运行过程中Ready的状态变为False，则系统自动将其它从Service的后面Endpoint列表中隔离出去，后续再恢复到Ready状态的Pod加回到Endpoint静静。ReadinessProbe是定期触发执行的，存在于Pod的整个生命周期中。
3. **StartupProbe**：某些应用会遇到启动比较慢的情况，此时ReadinessProbe不适用。如启动的StartupProbe的情况下配置了的LivenessProbe和ReadinessProbe探针将失效。

### 探针的三种实现方式

1. **ExecAction**：在容器内部运行一个命令，如果该命令的返回码为0，则表明容器健康
2. **TCPSocketAction**：通过容器的IP地址和端口号执行TCP检查，如果能够建立TCP连接，则表明容器健康
3. **LivenessProbe**：通过容器的IP地址、端口号及路径调用HTTP Get方法，如果响应的状态大于等于200且小于400，则认为容器健康

## 9、Pod的调度

​	常用的调度器：

1. RC
2. Deployment
3. DaemonSet
4. Job
5. StatefuSet

### 9.1	Deployment或RC：全自动调度

nginx-deployment.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
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
        image: docker.m.daocloud.io/nginx:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
```

执行结果

```
[root@kube-master study]# kubectl create -f nginx-deployment.yaml
deployment.apps/nginx-deployment created
[root@kube-master study]# kubectl get pod -o wide | grep nginx
nginx-deployment-6bf46c9b9d-2bwz4   1/1     Running   0               8s      172.23.127.86   kube-node02   <none>           <none>
nginx-deployment-6bf46c9b9d-jp9ll   1/1     Running   0               5s      172.30.0.143    kube-node01   <none>           <none>
nginx-deployment-6bf46c9b9d-sq8fd   1/1     Running   0               7s      172.17.74.73    kube-node03   <none>           <none>

[root@kube-master study]# kubectl get rs
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-6bf46c9b9d   3         3         3       4m26s


```

### 9.2	NodeSelector：定向调度

#### Node上打标签

命令格式

```
kubectl label nodes <node-name> <label-key>=<label-value>	
```

示例：给kube-node01打上zone=north的标签

```
[root@kube-master study]# kubectl get nodes
NAME          STATUS   ROLES           AGE   VERSION
kube-master   Ready    control-plane   12h   v1.29.15
kube-node01   Ready    <none>          12h   v1.29.15
kube-node02   Ready    <none>          12h   v1.29.15
kube-node03   Ready    <none>          12h   v1.29.15
[root@kube-master study]# kubectl label nodes kube-node01 zone=north
node/kube-node01 labeled
[root@kube-master study]# kubectl get node kube-node01 --show-labels
NAME          STATUS   ROLES    AGE   VERSION    LABELS
kube-node01   Ready    <none>   12h   v1.29.15   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=kube-node01,kubernetes.io/os=linux,zone=north

```



#### NodeSelector设置

redis-controller.yaml

```
apiVersion: v1
kind: ReplicationController
metadata:
  name: redis
  labels:
    app: redis
spec:
  replicas: 2
  selector:
    name: redis
  template:
    metadata:
      labels:
        name: redis
    spec:
      containers:
      - name: redis
        image: docker.m.daocloud.io/redis:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 6379
      nodeSelector:
        zone: north
```



#### 验证调度结果

```
[root@kube-master study]# kubectl create -f redis-controller.yaml
replicationcontroller/redis created
[root@kube-master study]# kubectl get pod -o wide | grep redis
redis-l7zb4                         1/1     Running   0               2m3s    172.30.0.144    kube-node01   <none>           <none>
redis-p4lhk                         1/1     Running   0               2m3s    172.30.0.145    kube-node01   <none>           <none>

```

### 9.3	NodeAffinity：Node亲和性调度

#### 2种亲和性调度策略

1. **RequiredDuringSchedulingIgnoredDuringExecution**：必须满足指定的规则才可以调度Pod到Node上，相当于硬限制
2. **PreferredDuringSchedulingIgnoredDuringExecution**：强调优先满足指定规则，调度器会尝试调度Pod到Node上，相当于软限制。多个优先级规则还可以设置权重（weight）值，以定义执行的先后顺序。

#### 支持的操作符

1. In
2. NotIn
3. Exists
4. DoesNotExist
5. Gt
6. Lt

#### 示例

nodeaffinity-ex.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: node-affinity
spec:
  containers:
  - name: nginx
    image: docker.m.daocloud.io/nginx:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: zone
            operator: In
            values:
            - north
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1 
        preference:
          matchExpressions:
          - key: disk
            operator: In
            values:
            - ssd
```

运行结果

```
[root@kube-master ~]# kubectl label node kube-node02 disk=ssd
[root@kube-master study]# kubectl create -f nodeaffinity-ex.yaml
[root@kube-master study]# kubectl get pod -o wide| grep affinity
node-affinity   1/1     Running   0          2s    172.30.0.154   kube-node01   <none>           <none>

```



#### 注意事项

- 如果同时定义了nodeSelector和NodeAffinity，那么必须两个条件都得到满足，Pod才能最终运行在指定的Node上
- 如果nodeAffinity指定了多个nodeSelectorTerms，那么其中一个能匹配成功即可
- 如果在nodeSelectorTerms中有多个matchExpressions，则一个节点必须满足所有 的matchExpressions才能运行该Pod

### 9.4	PodAffinity：Pod亲和与互斥调度策略

Pod亲和与互斥的调度具体做法就是通过Pod的定义上增加topologyKey属性，来声明对应的目标拓扑区域内几种相关联的Pod要“在一起或不在一起”

Pod亲和性被定义于Pod.Spec的affinity字段和PodAffinity子字段中

Pod间的互斥性刚被定义于同一层次的podAntiAffinity子字段中

#### 参照目标Pod



```
apiVersion: v1 
kind: Pod
metadata:
  name: pod-flag
  labels:
    security: "S1"
    app: "nginx"
spec:
  containers:
  - name: nginx
    image: docker.m.daocloud.io/nginx:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
```



#### Pod的亲和性调度

```
apiVersion: v1
kind: Pod
metadata:
  name: node-affinity
spec:
  containers:
  - name: nginx
    image: docker.m.daocloud.io/nginx:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution: 
      - labelSelector:
          matchExpressions:
          - key: security
            operator: In
            values:
            - S1
        topologyKey: kubernetes.io/hostname
```



#### Pod的互斥性调度

```
apiVersion: v1
kind: Pod
metadata:
  name: node-ani-affinity
spec:
  containers:
  - name: nginx
    image: docker.m.daocloud.io/nginx:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - nginx
        topologyKey: kubernetes.io/hostname
```

执行结果：

```
[root@kube-master study]# kubectl get pod -o wide
NAME                READY   STATUS    RESTARTS   AGE   IP              NODE          NOMINATED NODE   READINESS GATES
node-affinity       1/1     Running   0          10m   172.23.127.89   kube-node02   <none>           <none>
node-ani-affinity   1/1     Running   0          7s    172.30.0.155    kube-node01   <none>           <none>
pod-flag            1/1     Running   0          21m   172.23.127.88   kube-node02   <none>           <none>

```



#### topologykey使用限制

- 在Pod新和性和requiredDuringScheduling的Pod互斥性的定义中，不允许使用空的topologyKey
- 如果Admission controller包含了LimitPodHardAntiAffinity（ps aux | grep kube-apiserver | grep enable-admission-plugins或cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep enable-admission-plugins），那么针对requiredDuringScheduling的Pod互斥定义就被限制为kubernetes.io/hostname,要使用自定义的topologyKey，就要改写或禁用该控制器

- 在requiredDuringScheduling类型的Pod互斥定义中，空的topologyKey会被解释为kubernetes.io/hostname、failure-domain.beta.kubernetes.io/zone及failure-domain.beta.kubernetes.io/region的组合
- 如果不是上述的情况，就可以采用任意合法的topologyKey

#### PodAffinity规则设置注意事项

- 除了设置Label Selector和topologyKey，用户还可以指定Namespace列表进行限制，同时，使用Label Selector对Namespace进行选择。Namespace的定义和Label Selector及topologyKey同级。省略Namespace的设置，表示使用定义了affinity/anti-affinity的Pod所在的命名空间。如果Namespace被设置为空值（“”），则表示所有的命名空间
- 在所有关联requiredDuringSchedulingIgnoredDuringExecution的matchExpressions全部满足之后，系统才能将Pod调度到某个Node

### 9.5	Taints和Tolerations（污点和容忍）

​	Taint让Node拒绝Pod运行。若仍需将某些Pod调度到这些节点上时，可以通过使用Toleration属性来实现

- ​	使用kubectl设置Taint信息：

```
kubectl taint nodes node key=value:NoSchedule
```

- 使用kubectl清除Taint信息：

```
kubectl taint nodes node key=value:NoSchedule-
```

- 查看所有节点的污点

```
kubectl get nodes -o custom-columns=NODE:.metadata.name,TAINTS:.spec.taints
#或
kubectl describe nodes | grep -A 5 Taints
```



- 只看污点部分

```
kubectl describe nodes | awk '/Taints:/ {print $0}'
```



- 查看单个节点的污点

```
kubectl describe node <节点名>
```



- 用 JSON 精确查看

```
kubectl get node <节点名> -o jsonpath='{.spec.taints}'
```



- 只筛选有污点的节点

```
kubectl get nodes -o json | jq '.items[] | select(.spec.taints != null) | .metadata.name'
```

#### 常见污点含义

- **NoSchedule**：不允许新 Pod 调度上来，但已有 Pod 不驱逐

- **PreferNoSchedule**：尽量不调度

- **NoExecute**：不调度 + 驱逐不符合容忍的 Pod

#### 会自动给Pod添加的几种Toleration

1. key为node.kubernetes.io/not-ready，并配置tolerationSeconds=300

2. key为node.kubernetes.io/unreachable，并配置tolerationSeconds=300

   这种机制保证了在某些节点发生一些临时性问题时，Pod默认能够继续停留在当前节点运行5min等待节点恢复，而不是立即被驱逐，从而避免系统的异常动

#### 自动为Nod添加Taint的几种条件

1. node.kubernetes.io/not-ready：节点未就绪。对应NodeCondition Ready为False的情况
2. node.kubernetes.io/unreachable：节点不可触达。对应NodeCondition Ready为Unknown的情况
3. node.kubernetes.io/out-of-disk：节点磁盘空间已满
4. node.kubernetes.io/network-unavailable：节点网络不可用
5. node.kubernetes.io/unschedulable：节点不可调度
6. node.cloudprovider.kubernetes.io/uninitialized：如果kubelet是由“外部”云服务端启动，则该污点用来标识某个节点当前为不可用状态



### 9.6	Pod Priority Preemption：Pod优先级调度

Pod优先级抢占（Pod Priority Preemption）的调度策略会尝试释放目标节点上低优先级的Pod，以腾出空间（资源）安置高优先级的Pod，定义的维度如下：

- Priority：优先级
- QoS：服务质量
- 系统定义的其它指标

优先级抢占调度策略的核心行为如下：

- Eviction：为kubelet进行的行为，即当一个Node资源不足（under resource pressure）时，该 节点上的kubelet进程会执行驱逐行为。

- Preemption：是Scheduler执行的行为，当一个新的Pod因为资源无法满足而不能被调度时，Scheduler可能选择驱逐总分低优先级的Pod实例来满足调度目标。

  

#### 系统内置优先级

- system-cluster-critical：默认值为2000000000，集群核心组件（kube-dns、calico、apiserver 等）使用
- system-node-critical：默认值为2000001000，节点核心组件（kube-proxy、CNI 等）最高优先级

#### 关键规则

1. **value 越大 = 优先级越高**

2. 优先级高的 Pod：

   - 优先调度

   - 资源不够时**最后被驱逐**

3. 系统 Pod（2000000000+）永远最高，不能被覆盖

4. 不设置优先级 = 默认 **0**

#### 示例

high-priority.yaml

```
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata: 
  name: high-priority
values: 10000
globalDefault: false
description: "This priority class should be used for XYZ service pods only."
```

pod-priority.yaml

```
apiVersion: v1
kind: Pod 
metadata:
  name: pod-priority
  labels:
    app: "nginx"
    env: "test"
spec:
  priorityClassName: high-priority
  containers:
  - name: nginx
    image: docker.m.daocloud.io/nginx:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80

```

运行结果

```
[root@kube-master study]# kubectl create -f high-priority.yaml
priorityclass.scheduling.k8s.io/high-priority created
[root@kube-master study]# kubectl create -f pod-priority.yaml
pod/pod-priority created
[root@kube-master study]# kubectl get PriorityClass
NAME                      VALUE        GLOBAL-DEFAULT   AGE
high-priority             1000000      false            2m41s
system-cluster-critical   2000000000   false            3d19h
system-node-critical      2000001000   false            3d19h
[root@kube-master study]# kubectl get pod -o wide | grep priority
pod-priority        1/1     Running   0          2m15s   172.23.127.90   kube-node02   <none>           <none>
[root@kube-master study]# kubectl describe pod pod-priority | grep Priority
Priority:             1000000
Priority Class Name:  high-priority
```

#### kubelet添加优先级

```
# 高优先级
kubectl create priorityclass high-priority --value=1000000

# 中优先级
kubectl create priorityclass medium-priority --value=500000

# 低优先级
kubectl create priorityclass low-priority --value=100000
```



### 9.7	DaemonSet在每个Node上都调度一个Pod

DeamonSet的Pod调度策略与RC类似，除了使用系统内置的算法在每个Node上进行调度，也可以在Pod的定义中使用NodeSelector或NodeAffinity来指定满足条件的Node范围进行调度

#### 示例

fluentd-ds.yaml

```shell
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-ds
  namespace: kube-system
  labels:
    app: fluentd
spec: 
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      namespace: kube-system
      labels:
        app: fluentd
    spec:
      containers:
      - name: fluentd
        image: docker.m.daocloud.io/fluentd:latest
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            memory: "200Mi"
            cpu: "100m"
          requests:
            memory: "100Mi"
            cpu: "50m"
        volumeMounts:
        - name: varlog  
          mountPath: /var/log
          readOnly: false
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: false
      volumes:
      - name: varlog
        hostPath: 
          path: /var/log
      - name: varlibdockercontainers
        hostPath: 
          path: /var/lib/docker/containers

```

运行结果

```
[root@kube-master study]# kubectl create -f fluentd-ds.yaml
daemonset.apps/fluentd-ds created
[root@kube-master study]# kubectl get pods -n kube-system -o wide | grep fluentd
fluentd-ds-l8crk                          1/1     Running   0               16s     172.23.127.92   kube-node02   <none>           <none>
fluentd-ds-s5jxk                          1/1     Running   0               3m15s   172.30.0.156    kube-node01   <none>           <none>
fluentd-ds-sh9m2                          1/1     Running   0               3m15s   172.17.74.75    kube-node03   <none>           <none>

```



### 9.8	Job：批处理调度

#### 批处理任务的几种模式

1. Job Template Expansion模式：一个Job对象对应一个待处理的Work Item
2. **Queue with Pod Per Work Item**模式：一个任务队列存入Work Item，一个Job对象作为消费者去完成这个Work Item。在这种模式下，Job会启动N个Pod，每个Pod都对应一个Work Item。
3. **Queue with Variable Pod Count**模式：与Queue with Pod Per Work Item模式类似，也是一个任务队列存入Work Item，一个Job对象作为消费者去完成这个Work Item。但也上面模式不同，Job启动的Pod数量是可变的。
4. Single Job with Static Work Assignment模式：一个Job产生多个Pod，但它采用程序静态方式分配任务项，而不是采用队列模式进行动态分配。

#### Job的三种类型

1. Non-parallel Job：一个Job只启动一个Pod，除非Pod异常，才会重启该Pod，一旦该Pod正常结束，Job将结束。
2. Parallel Job with a fixed completion count：并行Job会启动多个Pod，此时需要设定Job的.spec.completions参数为一个正数，当正常结束的Pod数量达至此参数设定的值后，Job结束。此外，Job的.spec.parallelism参数用来控制并行度，即同时启动几个Job来处理Work item
3. Parallel Job with a work queue：任务队列方式的并行Job需要一个独立的Queue，Work item都在一个Queue中存放，不能设置Job的.spec.completions参数，此时Job有以下特性
   - 每个Pod都能独立判断和决定是否还有任务项需要处理。
   - 如果某个Pod正常结束，则Job不会再启动新的Pod。
   - 如果一个Pod成功结束，则此时应该不存在其他Pod还在工作的情况，它们应该都处于即将结束、退出的状态。
   - 如果所有Pod都结束了，且至少有一个Pod成功结束，则整个Job成功结束。

#### Job Template Expansion模式示例

job.yaml

```
apiVersion: batch/v1 
kind: Job
metadata: 
  name: job-item-$ITEM
  labels:
    app: "jobexample"
spec:
  template:
    metadata:
      name: jobexample
      labels:
        app: "jobexample"
    spec:
      containers:
      - name: jobexample
        image: docker.m.daocloud.io/busybox:latest
        imagePullPolicy: IfNotPresent
        command: ["sh", "-c", "echo Hello Kubernetes job-item-$ITEM && sleep 30"]
      restartPolicy: Never
```

执行结果

```
[root@kube-master study]# mkdir job
[root@kube-master study]# for i in apple banana cherry; do  cat job.yaml | sed "s/\$ITEM/$i/" > ./job/job-$i.yaml; done
[root@kube-master study]# kubectl create -f job
job.batch/job-item-apple created
job.batch/job-item-banana created
job.batch/job-item-cherry created
[root@kube-master study]# kubectl get job -l app=jobexample
NAME              COMPLETIONS   DURATION   AGE
job-item-apple    1/1           33s        2m46s
job-item-banana   1/1           33s        2m46s
job-item-cherry   1/1           33s        2m46s


```





### 9.9	Cronjob：定时任务

Job的定时表达式，它基本上照搬了Linux Cron的表达式，

#### 格式

```
Minutes Hours DayofMonth Month DayofWeek
```

- Minutes：可出现“，”“-”“*”“/”这4个字符，有效范围为0～59的整数。
- Hours：可出现“，”“-”“*”“/”这4个字符，有效范围为0～23的整数
- DayofMonth：可出现“，”“-”“*”“/”“？”“L”“W”“C”这8个字符，有效范围为1～31的整数
- Month：可出现“，”“-”“*”“/”这4个字符，有效范围为1～12的整数或JAN～DEC。
- DayofWeek：可出现“，”“-”“*”“/”“？”“L”“C”“#”这8个字符，有效范围为1～7的整数或SUN～SAT。1表示星期天，2表示星期一，以此类推。

#### “*”与“/”的含义

- **：表示匹配该域的任意值，假如在Minutes域使用“*”，则表示每分钟都会触发事件

- /：表示从起始时间开始触发，然后每隔固定时间触发一次，例如在Minutes域设置为5/20，则意味着第1次触发在第5min时，接下来每20min触发一次，将在第25min、第45min等时刻分别触发。

#### 示例

cronjob.yaml

```
apiVersion: batch/v1
kind: CronJob
metadata: 
  name: cronjob-example
  labels:
    app: "cronjobexample"
spec:
  schedule: "*/1 * * * *" 
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: docker.m.daocloud.io/busybox:latest
            imagePullPolicy: IfNotPresent
            args: 
            - /bin/sh
            - -c 
            - date; echo Hello from the Kubernetes CronJob!
          restartPolicy: OnFailure
```

运行结果：

```
[root@kube-master study]# kubectl create -f cronjob.yaml
cronjob.batch/cronjob-example created
[root@kube-master study]# kubectl get cronjob -l app=cronjobexample
NAME              SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob-example   */1 * * * *   False     0        11s             98s
[root@kube-master study]# kubectl get jobs
NAME                       COMPLETIONS   DURATION   AGE
cronjob-example-29578132   1/1           3s         2m13s
cronjob-example-29578133   1/1           3s         73s
cronjob-example-29578134   1/1           3s         13s

[root@kube-master study]# kubectl delete cronjob cronjob-example
cronjob.batch "cronjob-example" deleted

```



### 9.11	Pod容灾调度

#### 实现方式

使用Even Pod Spreading特性实现，用于通过topologyKey属性识别Zone，并通过设置新的参数topologySpreadConstraints来将Pod均匀调度到不同的Zone。

#### skew参数的计算公式

skew[topo]=count[topo]-min（count[topo]），即每个拓扑区域的skew值都为该区域包括的目标Pod数量与整个拓扑区域最少Pod数量的差，而maxSkew就是最大的skew值。假如有3个拓扑区域，分别为ZoneA、ZoneB及ZoneC，有3个目标Pod需要调度到这些拓扑区域，那么前两个毫无疑问会被调度到ZoneA和ZoneB



