

# 一、下载minikube

**curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm**

**rpm -ivh minikube-latest.x86_64.rpm**

# 二、minikube安装

## 2.1	使用aliyuncs安装

**minikube start --driver=none --image-repository=registry.aliyuncs.com/google_containers**

```
minikube start --driver=none --image-repository=registry.aliyuncs.com/google_containers
* minikube v1.25.2 on Centos 7.9.2009
* Using the none driver based on user configuration
* Using image repository registry.aliyuncs.com/google_containers
* Starting control plane node minikube in cluster minikube
* Running on localhost (CPUs=4, Memory=7821MB, Disk=40656MB) ...
* OS release is CentOS Linux 7 (Core)
* Preparing Kubernetes v1.23.3 on Docker 20.10.14 ...
  - kubelet.housekeeping-interval=5m
  - Generating certificates and keys ...
  - Booting up control plane ...
  - Configuring RBAC rules ...
* Configuring local host environment ...
*
! The 'none' driver is designed for experts who need to integrate with an existing VM
* Most users should use the newer 'docker' driver instead, which does not require root!
* For more information, see: https://minikube.sigs.k8s.io/docs/reference/drivers/none/
*
! kubectl and minikube configuration will be stored in /root
! To use kubectl or minikube commands as your own user, you may need to relocate them. For example, to overwrite your own settings, run:
*
  - sudo mv /root/.kube /root/.minikube $HOME
  - sudo chown -R $USER $HOME/.kube $HOME/.minikube
*
* This can also be done automatically by setting the env var CHANGE_MINIKUBE_NONE_USER=true
* Verifying Kubernetes components...
  - Using image registry.aliyuncs.com/google_containers/k8s-minikube/storage-provisioner:v5 (global image repository)
* Enabled addons: default-storageclass, storage-provisioner
* kubectl not found. If you need it, try: 'minikube kubectl -- get pods -A'
* Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

```

## 2.2	安装验证

**minikube kubectl -- get pods -A**

```
NAMESPACE     NAME                               READY   STATUS         RESTARTS   AGE
kube-system   coredns-6d8c4cb4d-7mjfx            1/1     Running        0          56s
kube-system   etcd-minikube                      1/1     Running        0          69s
kube-system   kube-apiserver-minikube            1/1     Running        0          69s
kube-system   kube-controller-manager-minikube   1/1     Running        0          69s
kube-system   kube-proxy-8r7h5                   1/1     Running        0          57s
kube-system   kube-scheduler-minikube            1/1     Running        0          71s
kube-system   storage-provisioner                0/1     ErrImagePull   0          68s
```

**minikube status**

```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

## 2.3	storage-provisioner问题

### 2.3.1	查看storage-provisioner信息

**minikube kubectl -- get pod storage-provisioner -n kube-system -oyaml**

```
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"Pod","metadata":{"annotations":{},"labels":{"addonmanager.kubernetes.io/mode":"Reconcile","integration-test":"storage-provisioner"},"name":"storage-provisioner","namespace":"kube-system"},"spec":{"containers":[{"command":["/storage-provisioner"],"image":"registry.aliyuncs.com/google_containers/k8s-minikube/storage-provisioner:v5","imagePullPolicy":"IfNotPresent","name":"storage-provisioner","volumeMounts":[{"mountPath":"/tmp","name":"tmp"}]}],"hostNetwork":true,"serviceAccountName":"storage-provisioner","volumes":[{"hostPath":{"path":"/tmp","type":"Directory"},"name":"tmp"}]}}
  creationTimestamp: "2022-05-04T17:03:19Z"
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
    integration-test: storage-provisioner
  name: storage-provisioner
  namespace: kube-system
  resourceVersion: "568"
  uid: 00784bc9-eb75-4b0f-ab8e-b013a45d452f
spec:
  containers:
  - command:
    - /storage-provisioner
    image: registry.aliyuncs.com/google_containers/k8s-minikube/storage-provisioner:v5
    imagePullPolicy: IfNotPresent
    name: storage-provisioner
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /tmp
      name: tmp
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-wcr6x
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  hostNetwork: true
  nodeName: minikube
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: storage-provisioner
  serviceAccountName: storage-provisioner
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - hostPath:
      path: /tmp
      type: Directory
    name: tmp
  - name: kube-api-access-wcr6x
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2022-05-04T17:03:30Z"
    status: "True"
    type: Initialized
  - lastProbeTime: null
    lastTransitionTime: "2022-05-04T17:03:30Z"
    message: 'containers with unready status: [storage-provisioner]'
    reason: ContainersNotReady
    status: "False"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: "2022-05-04T17:03:30Z"
    message: 'containers with unready status: [storage-provisioner]'
    reason: ContainersNotReady
    status: "False"
    type: ContainersReady
  - lastProbeTime: null
    lastTransitionTime: "2022-05-04T17:03:30Z"
    status: "True"
    type: PodScheduled
  containerStatuses:
  - image: registry.aliyuncs.com/google_containers/k8s-minikube/storage-provisioner:v5
    imageID: ""
    lastState: {}
    name: storage-provisioner
    ready: false
    restartCount: 0
    started: false
    state:
      waiting:
        message: Back-off pulling image "registry.aliyuncs.com/google_containers/k8s-minikube/storage-provisioner:v5"
        reason: ImagePullBackOff
  hostIP: 192.168.1.221
  phase: Pending
  podIP: 192.168.1.221
  podIPs:
  - ip: 192.168.1.221
  qosClass: BestEffort
  startTime: "2022-05-04T17:03:30Z"
```

镜像地址为：registry.aliyuncs.com/google_containers/k8s-minikube/storage-provisioner:v5

### 2.3.2	手动docker pull

**docker pull registry.aliyuncs.com/google_containers/k8s-minikube/storage-provisioner:v5**

```
Error response from daemon: pull access denied for registry.aliyuncs.com/google_containers/k8s-minikube/storage-provisioner, repository does not exist or may require 'docker login': denied: requested access to the resource is denied

```

 **docker pull registry.aliyuncs.com/google_containers/storage-provisioner:v5**

```
v5: Pulling from google_containers/storage-provisioner
157dd68f5e48: Pull complete
Digest: sha256:18eb69d1418e854ad5a19e399310e52808a8321e4c441c1dddad8977a0d7a944
Status: Downloaded newer image for registry.aliyuncs.com/google_containers/storage-provisioner:v5
registry.aliyuncs.com/google_containers/storage-provisioner:v5

```

### 2.3.3	查看镜像

**docker images | grep storage**

```
registry.aliyuncs.com/google_containers/storage-provisioner                   v5        6e38f40d628d   13 months ago   31.5MB
```

### 2.3.4	重新tag镜像

**docker tag registry.aliyuncs.com/google_containers/storage-provisioner:v5 registry.aliyuncs.com/google_containers/k8s-minikube/storage-provisioner:v5**

### 2.3.5	查看storage-provisioner状态

 **minikube kubectl -- get pods -A**

```
NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
kube-system   coredns-6d8c4cb4d-7mjfx            1/1     Running   0          15m
kube-system   etcd-minikube                      1/1     Running   0          15m
kube-system   kube-apiserver-minikube            1/1     Running   0          15m
kube-system   kube-controller-manager-minikube   1/1     Running   0          15m
kube-system   kube-proxy-8r7h5                   1/1     Running   0          15m
kube-system   kube-scheduler-minikube            1/1     Running   0          15m
kube-system   storage-provisioner                1/1     Running   0          15m

```

## 2.4	环境变更配置

**echo 'alias kubectl="minikube kubectl --"' >> /root/.bashrc**

**source /root/.bashrc**

**kubectl get node -A**

```
NAME       STATUS   ROLES                  AGE   VERSION
minikube   Ready    control-plane,master   17m   v1.23.3

```

**kubectl get pods -A -owide**

```
NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE   IP              NODE       NOMINATED NODE   READINESS GATES
kube-system   coredns-6d8c4cb4d-7mjfx            1/1     Running   0          20m   172.17.0.2      minikube   <none>           <none>
kube-system   etcd-minikube                      1/1     Running   0          20m   192.168.1.221   minikube   <none>           <none>
kube-system   kube-apiserver-minikube            1/1     Running   0          20m   192.168.1.221   minikube   <none>           <none>
kube-system   kube-controller-manager-minikube   1/1     Running   0          20m   192.168.1.221   minikube   <none>           <none>
kube-system   kube-proxy-8r7h5                   1/1     Running   0          20m   192.168.1.221   minikube   <none>           <none>
kube-system   kube-scheduler-minikube            1/1     Running   0          20m   192.168.1.221   minikube   <none>           <none>
kube-system   storage-provisioner                1/1     Running   0          20m   192.168.1.221   minikube   <none>           <none>

```

## 2.5	dashboard安装

### 2.5.1	dashboard启动

**minikube dashboard**

### 2.5.2	dashboard启动失败

**kubectl get pods -A**

```
NAMESPACE              NAME                                         READY   STATUS         RESTARTS   AGE
kube-system            coredns-6d8c4cb4d-7mjfx                      1/1     Running        0          25m
kube-system            etcd-minikube                                1/1     Running        0          25m
kube-system            kube-apiserver-minikube                      1/1     Running        0          25m
kube-system            kube-controller-manager-minikube             1/1     Running        0          25m
kube-system            kube-proxy-8r7h5                             1/1     Running        0          25m
kube-system            kube-scheduler-minikube                      1/1     Running        0          25m
kube-system            storage-provisioner                          1/1     Running        0          25m
kubernetes-dashboard   dashboard-metrics-scraper-5496b5d99f-4nsjj   0/1     ErrImagePull   0          64s
kubernetes-dashboard   kubernetes-dashboard-58b48666f8-6pjjp        0/1     ErrImagePull   0          64s

```

### 2.5.1	查看yaml文件

**kubectl get pod dashboard-metrics-scraper-5496b5d99f-4nsjj -n kubernetes-dashboard -oyaml**

```
apiVersion: v1
kind: Pod
metadata:
  annotations:
    seccomp.security.alpha.kubernetes.io/pod: runtime/default
  creationTimestamp: "2022-05-04T17:27:27Z"
  generateName: dashboard-metrics-scraper-5496b5d99f-
  labels:
    k8s-app: dashboard-metrics-scraper
    pod-template-hash: 5496b5d99f
  name: dashboard-metrics-scraper-5496b5d99f-4nsjj
  namespace: kubernetes-dashboard
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: dashboard-metrics-scraper-5496b5d99f
    uid: d42cb419-4d02-4453-b422-a1e6fd327928
  resourceVersion: "1342"
  uid: 20ff5242-33f8-4777-a776-7eea2c0b4155
spec:
  containers:
  - image: registry.aliyuncs.com/google_containers/kubernetesui/metrics-scraper:v1.0.7@sha256:36d5b3f60e1a144cc5ada820910535074bdf5cf73fb70d1ff1681537eef4e172
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 3
      httpGet:
        path: /
        port: 8000
        scheme: HTTP
      initialDelaySeconds: 30
      periodSeconds: 10
      successThreshold: 1
      timeoutSeconds: 30
    name: dashboard-metrics-scraper
    ports:
    - containerPort: 8000
      protocol: TCP
    resources: {}
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsGroup: 2001
      runAsUser: 1001
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /tmp
      name: tmp-volume
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-rb8gx
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: minikube
  nodeSelector:
    beta.kubernetes.io/os: linux
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  serviceAccount: kubernetes-dashboard
  serviceAccountName: kubernetes-dashboard
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - emptyDir: {}
    name: tmp-volume
  - name: kube-api-access-rb8gx
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2022-05-04T17:27:27Z"
    status: "True"
    type: Initialized
  - lastProbeTime: null
    lastTransitionTime: "2022-05-04T17:27:27Z"
    message: 'containers with unready status: [dashboard-metrics-scraper]'
    reason: ContainersNotReady
    status: "False"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: "2022-05-04T17:27:27Z"
    message: 'containers with unready status: [dashboard-metrics-scraper]'
    reason: ContainersNotReady
    status: "False"
    type: ContainersReady
  - lastProbeTime: null
    lastTransitionTime: "2022-05-04T17:27:27Z"
    status: "True"
    type: PodScheduled
  containerStatuses:
  - image: registry.aliyuncs.com/google_containers/kubernetesui/metrics-scraper:v1.0.7@sha256:36d5b3f60e1a144cc5ada820910535074bdf5cf73fb70d1ff1681537eef4e172
    imageID: ""
    lastState: {}
    name: dashboard-metrics-scraper
    ready: false
    restartCount: 0
    started: false
    state:
      waiting:
        message: Back-off pulling image "registry.aliyuncs.com/google_containers/kubernetesui/metrics-scraper:v1.0.7@sha256:36d5b3f60e1a144cc5ada820910535074bdf5cf73fb70d1ff1681537eef4e172"
        reason: ImagePullBackOff
  hostIP: 192.168.1.221
  phase: Pending
  podIP: 172.17.0.4
  podIPs:
  - ip: 172.17.0.4
  qosClass: BestEffort
  startTime: "2022-05-04T17:27:27Z"

```

**kubectl get pod kubernetes-dashboard-58b48666f8-6pjjp -n kubernetes-dashboard -oyaml**

```
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2022-05-04T17:27:27Z"
  generateName: kubernetes-dashboard-58b48666f8-
  labels:
    gcp-auth-skip-secret: "true"
    k8s-app: kubernetes-dashboard
    pod-template-hash: 58b48666f8
  name: kubernetes-dashboard-58b48666f8-6pjjp
  namespace: kubernetes-dashboard
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: kubernetes-dashboard-58b48666f8
    uid: 903bb2cb-68ac-41b2-9dd6-d14f2fabc345
  resourceVersion: "1476"
  uid: a52cbdfa-d5a8-40f4-ae4f-31bfc5240262
spec:
  containers:
  - args:
    - --namespace=kubernetes-dashboard
    - --enable-skip-login
    - --disable-settings-authorizer
    image: registry.aliyuncs.com/google_containers/kubernetesui/dashboard:v2.3.1@sha256:ec27f462cf1946220f5a9ace416a84a57c18f98c777876a8054405d1428cc92e
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 3
      httpGet:
        path: /
        port: 9090
        scheme: HTTP
      initialDelaySeconds: 30
      periodSeconds: 10
      successThreshold: 1
      timeoutSeconds: 30
    name: kubernetes-dashboard
    ports:
    - containerPort: 9090
      protocol: TCP
    resources: {}
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsGroup: 2001
      runAsUser: 1001
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /tmp
      name: tmp-volume
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-phvw9
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: minikube
  nodeSelector:
    beta.kubernetes.io/os: linux
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: kubernetes-dashboard
  serviceAccountName: kubernetes-dashboard
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - emptyDir: {}
    name: tmp-volume
  - name: kube-api-access-phvw9
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2022-05-04T17:27:27Z"
    status: "True"
    type: Initialized
  - lastProbeTime: null
    lastTransitionTime: "2022-05-04T17:27:27Z"
    message: 'containers with unready status: [kubernetes-dashboard]'
    reason: ContainersNotReady
    status: "False"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: "2022-05-04T17:27:27Z"
    message: 'containers with unready status: [kubernetes-dashboard]'
    reason: ContainersNotReady
    status: "False"
    type: ContainersReady
  - lastProbeTime: null
    lastTransitionTime: "2022-05-04T17:27:27Z"
    status: "True"
    type: PodScheduled
  containerStatuses:
  - image: registry.aliyuncs.com/google_containers/kubernetesui/dashboard:v2.3.1@sha256:ec27f462cf1946220f5a9ace416a84a57c18f98c777876a8054405d1428cc92e
    imageID: ""
    lastState: {}
    name: kubernetes-dashboard
    ready: false
    restartCount: 0
    started: false
    state:
      waiting:
        message: Back-off pulling image "registry.aliyuncs.com/google_containers/kubernetesui/dashboard:v2.3.1@sha256:ec27f462cf1946220f5a9ace416a84a57c18f98c777876a8054405d1428cc92e"
        reason: ImagePullBackOff
  hostIP: 192.168.1.221
  phase: Pending
  podIP: 172.17.0.3
  podIPs:
  - ip: 172.17.0.3
  qosClass: BestEffort
  startTime: "2022-05-04T17:27:27Z"

```

### 2.5.3	手动下载images

**docker pull registry.aliyuncs.com/google_containers/metrics-scraper:v1.0.7@sha256:36d5b3f60e1a144cc5ada820910535074bdf5cf73fb70d1ff1681537eef4e172**

```
registry.aliyuncs.com/google_containers/metrics-scraper@sha256:36d5b3f60e1a144cc5ada820910535074bdf5cf73fb70d1ff16815372: Pulling from google_containers/metrics-scraper
18dd5eddb60d: Pull complete
1930c20668a8: Pull complete
Digest: sha256:36d5b3f60e1a144cc5ada820910535074bdf5cf73fb70d1ff1681537eef4e172
Status: Downloaded newer image for registry.aliyuncs.com/google_containers/metrics-scraper@sha256:36d5b3f60e1a144cc5ada35074bdf5cf73fb70d1ff1681537eef4e172
registry.aliyuncs.com/google_containers/metrics-scraper:v1.0.7@sha256:36d5b3f60e1a144cc5ada820910535074bdf5cf73fb70d1ffeef4e172

```

 **docker pull registry.aliyuncs.com/google_containers/dashboard:v2.3.1@sha256:ec27f462cf1946220f5a9ace416a84a57c18f98c777876a8054405d1428cc92e**

```
registry.aliyuncs.com/google_containers/dashboard@sha256:ec27f462cf1946220f5a9ace416a84a57c18f98c777876a8054405d1428cc92e: Pulling from google_containers/dashboard
b82bd84ec244: Pull complete
21c9e94e8195: Pull complete
Digest: sha256:ec27f462cf1946220f5a9ace416a84a57c18f98c777876a8054405d1428cc92e
Status: Downloaded newer image for registry.aliyuncs.com/google_containers/dashboard@sha256:ec27f462cf1946220f5a9ace416a84a57c18f98c777876a8054405d1428cc92e
registry.aliyuncs.com/google_containers/dashboard:v2.3.1@sha256:ec27f462cf1946220f5a9ace416a84a57c18f98c777876a8054405d1428cc92e

```

### 2.5.4	重打标签

**docker tag registry.aliyuncs.com/google_containers/metrics-scraper:v1.0.7@sha256:36d5b3f60e1a144cc5ada820910535074bdf5cf73fb70d1ff1681537eef4e172 registry.aliyuncs.com/google_containers/kubernetesui/metrics-scraper:v1.0.7@sha256:36d5b3f60e1a144cc5ada820910535074bdf5cf73fb70d1ff1681537eef4e172**

**docker tag registry.aliyuncs.com/google_containers/dashboard:v2.3.1@sha256:ec27f462cf1946220f5a9ace416a84a57c18f98c777876a8054405d1428cc92e registry.aliyuncs.com/google_containers/kubernetesui/dashboard:v2.3.1@sha256:ec27f462cf1946220f5a9ace416a84a57c18f98c777876a8054405d1428cc92e**

### 2.5.5	查看pod信息

**kubectl get pods -A**

```
NAMESPACE              NAME                                         READY   STATUS    RESTARTS   AGE
kube-system            coredns-6d8c4cb4d-7mjfx                      1/1     Running   0          35m
kube-system            etcd-minikube                                1/1     Running   0          35m
kube-system            kube-apiserver-minikube                      1/1     Running   0          35m
kube-system            kube-controller-manager-minikube             1/1     Running   0          35m
kube-system            kube-proxy-8r7h5                             1/1     Running   0          35m
kube-system            kube-scheduler-minikube                      1/1     Running   0          35m
kube-system            storage-provisioner                          1/1     Running   0          35m
kubernetes-dashboard   dashboard-metrics-scraper-5496b5d99f-4nsjj   1/1     Running   0          11m
kubernetes-dashboard   kubernetes-dashboard-58b48666f8-6pjjp        1/1     Running   0          11m
```

### 2.5.6	访问dashboard



# 三、管理minikube

## 3.1	删除 minikube 

**minikube delete**

**minikube delete --all**

## 3.2	暂停minikube

**minikube pause**

**minikube unpause**

## 3.3	停止minikube 

**minikube stop**

## 3.4	内存升配置(需重启)

**minikube config set memory 16384**



# 四、使用minikube

## 4.1	发布应用

**kubectl create deployment hello-minikube --image=registry.aliyuncs.com/google_containers/echoserver:1.4**

```
NAMESPACE              NAME                                         READY   STATUS    RESTARTS   AGE
default                hello-minikube-6bc9dcf684-qdb8f              1/1     Running   0          9s
kube-system            coredns-6d8c4cb4d-7mjfx                      1/1     Running   0          41m
kube-system            etcd-minikube                                1/1     Running   0          41m
kube-system            kube-apiserver-minikube                      1/1     Running   0          41m
kube-system            kube-controller-manager-minikube             1/1     Running   0          41m
kube-system            kube-proxy-8r7h5                             1/1     Running   0          41m
kube-system            kube-scheduler-minikube                      1/1     Running   0          41m
kube-system            storage-provisioner                          1/1     Running   0          41m
kubernetes-dashboard   dashboard-metrics-scraper-5496b5d99f-4nsjj   1/1     Running   0          17m
kubernetes-dashboard   kubernetes-dashboard-58b48666f8-6pjjp        1/1     Running   0          17m

```

**kubectl expose deployment hello-minikube --type=NodePort --port=8080**

**minikube service hello-minikube**

**kubectl port-forward service/hello-minikube 7080:8080**

**kubectl get svc**

```
NAMESPACE              NAME                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE
default                hello-minikube              NodePort    10.106.134.98   <none>        8080:32003/TCP           2m28s
default                kubernetes                  ClusterIP   10.96.0.1       <none>        443/TCP                  44m
kube-system            kube-dns                    ClusterIP   10.96.0.10      <none>        53/UDP,53/TCP,9153/TCP   44m
kubernetes-dashboard   dashboard-metrics-scraper   ClusterIP   10.96.214.204   <none>        8000/TCP                 20m
kubernetes-dashboard   kubernetes-dashboard        ClusterIP   10.106.75.0     <none>        80/TCP                   20m

```

```shell
kubectl create deployment balanced --image=registry.aliyuncs.com/google_containers/echoserver:1.4
kubectl expose deployment balanced --type=LoadBalancer --port=8080
```