# 问题背景

coredns的2个pod调度到1台node节点

如出现该节点重启或该节点因资源紧张出现pod驱逐时，可能因驱逐了coredns服务，而造成网络服务异常

# 解决方案

## 查看coredns服务节点分布

kubectl get pods -n kube-system -o wide | grep coredns

## 查看节点标签信息

kubectl get node 172.25.131.3 --show-labels -n kube-system

```
NAME           STATUS   ROLES    AGE   VERSION   LABELS

172.25.131.3   Ready       91d   v1.15.4   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,caas_cluster=kube-system,host_name=vm-001473,kubernetes.io/arch=amd64,kubernetes.io/hostname=172.25.131.3,kubernetes.io/os=linux
```



## 查看deployment 配置文件

 kubectl edit deployment coredns -n kube-system -oyaml

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"extensions/v1beta1","kind":"Deployment","metadata":{"annotations":{"deployment.kubernetes.io/revision":"1"},"generation":1,"labels":{"k8s-app":"kube-dns"},"name":"coredns","namespace":"kube-system"},"spec":{"progressDeadlineSeconds":600,"replicas":2,"revisionHistoryLimit":10,"selector":{"matchLabels":{"k8s-app":"kube-dns"}},"strategy":{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":1},"type":"RollingUpdate"},"template":{"metadata":{"creationTimestamp":null,"labels":{"k8s-app":"kube-dns"}},"spec":{"containers":[{"args":["-conf","/etc/coredns/Corefile"],"image":"harbor-vip.pcloud.localdomain/library/coredns:1.3.1","imagePullPolicy":"IfNotPresent","livenessProbe":{"failureThreshold":5,"httpGet":{"path":"/health","port":8080,"scheme":"HTTP"},"initialDelaySeconds":60,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5},"name":"coredns","ports":[{"containerPort":53,"name":"dns","protocol":"UDP"},{"containerPort":53,"name":"dns-tcp","protocol":"TCP"},{"containerPort":9153,"name":"metrics","protocol":"TCP"}],"readinessProbe":{"failureThreshold":3,"httpGet":{"path":"/health","port":8080,"scheme":"HTTP"},"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1},"resources":{"limits":{"memory":"170Mi"},"requests":{"cpu":"100m","memory":"70Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"add":["NET_BIND_SERVICE"],"drop":["all"]},"readOnlyRootFilesystem":true},"terminationMessagePath":"/dev/termination-log","terminationMessagePolicy":"File","volumeMounts":[{"mountPath":"/etc/coredns","name":"config-volume","readOnly":true},{"mountPath":"/tmp","name":"tmp"}]}],"dnsPolicy":"Default","nodeSelector":{"caas_cluster":"kube-system"},"priorityClassName":"system-cluster-critical","restartPolicy":"Always","schedulerName":"default-scheduler","securityContext":{},"serviceAccount":"coredns","serviceAccountName":"coredns","terminationGracePeriodSeconds":30,"tolerations":[{"key":"CriticalAddonsOnly","operator":"Exists"},{"effect":"NoSchedule","key":"node-role.kubernetes.io/master"}],"volumes":[{"emptyDir":{},"name":"tmp"},{"configMap":{"defaultMode":420,"items":[{"key":"Corefile","path":"Corefile"}],"name":"coredns"},"name":"config-volume"}]}}}}
  creationTimestamp: "2022-02-08T09:01:12Z"
  generation: 1
  labels:
    k8s-app: kube-dns
  name: coredns
  namespace: kube-system
  resourceVersion: "1200"
  selfLink: /apis/extensions/v1beta1/namespaces/kube-system/deployments/coredns
  uid: a057d689-5d2c-4db9-89b1-0e480392f861
spec:
  progressDeadlineSeconds: 600
  replicas: 2
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kube-dns
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        k8s-app: kube-dns
    spec:
      containers:
      - args:
        - -conf
        - /etc/coredns/Corefile
        image: harbor-vip.pcloud.localdomain/library/coredns:1.3.1
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 5
          httpGet:
            path: /health
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 5
        name: coredns
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
        - containerPort: 9153
          name: metrics
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /health
            port: 8080
            scheme: HTTP
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        resources:
          limits:
            memory: 170Mi
          requests:
            cpu: 100m
            memory: 70Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - NET_BIND_SERVICE
            drop:
            - all
          readOnlyRootFilesystem: true
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /etc/coredns
          name: config-volume
          readOnly: true
        - mountPath: /tmp
          name: tmp
      dnsPolicy: Default
      nodeSelector:
        caas_cluster: kube-system
      priorityClassName: system-cluster-critical
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      serviceAccount: coredns
      serviceAccountName: coredns
      terminationGracePeriodSeconds: 30
      tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - effect: NoSchedule
        key: node-role.kubernetes.io/master
      volumes:
      - emptyDir: {}
        name: tmp
      - configMap:
          defaultMode: 420
          items:
          - key: Corefile
            path: Corefile
          name: coredns
        name: config-volume
status:
  availableReplicas: 2
  conditions:
  - lastTransitionTime: "2022-02-08T09:02:21Z"
    lastUpdateTime: "2022-02-08T09:02:21Z"
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
  - lastTransitionTime: "2022-02-08T09:01:12Z"
    lastUpdateTime: "2022-02-08T09:02:27Z"
    message: ReplicaSet "coredns-5dfd59d95c" has successfully progressed.
    reason: NewReplicaSetAvailable
    status: "True"
    type: Progressing
  observedGeneration: 1
  readyReplicas: 2
  replicas: 2
  updatedReplicas: 2

```

## 配置分析

coredns未配置node节点亲和策略，导致coredns的pod可能会被调用到同一个节点上

## 配置内容

      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: k8s-app
                operator: In
                values:
                - coredns
            topologyKey: kubernetes.io/hostname

## 配置修改

kubectl edit deployment coredns -n kube-system -oyaml

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "2"
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"extensions/v1beta1","kind":"Deployment","metadata":{"annotations":{"deployment.kubernetes.io/revision":"1"},"generation":1,"labels":{"k8s-app":"kube-dns"},"name":"coredns","namespace":"kube-system"},"spec":{"progressDeadlineSeconds":600,"replicas":2,"revisionHistoryLimit":10,"selector":{"matchLabels":{"k8s-app":"kube-dns"}},"strategy":{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":1},"type":"RollingUpdate"},"template":{"metadata":{"creationTimestamp":null,"labels":{"k8s-app":"kube-dns"}},"spec":{"containers":[{"args":["-conf","/etc/coredns/Corefile"],"image":"harbor-vip.pcloud.localdomain/library/coredns:1.3.1","imagePullPolicy":"IfNotPresent","livenessProbe":{"failureThreshold":5,"httpGet":{"path":"/health","port":8080,"scheme":"HTTP"},"initialDelaySeconds":60,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5},"name":"coredns","ports":[{"containerPort":53,"name":"dns","protocol":"UDP"},{"containerPort":53,"name":"dns-tcp","protocol":"TCP"},{"containerPort":9153,"name":"metrics","protocol":"TCP"}],"readinessProbe":{"failureThreshold":3,"httpGet":{"path":"/health","port":8080,"scheme":"HTTP"},"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1},"resources":{"limits":{"memory":"170Mi"},"requests":{"cpu":"100m","memory":"70Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"add":["NET_BIND_SERVICE"],"drop":["all"]},"readOnlyRootFilesystem":true},"terminationMessagePath":"/dev/termination-log","terminationMessagePolicy":"File","volumeMounts":[{"mountPath":"/etc/coredns","name":"config-volume","readOnly":true},{"mountPath":"/tmp","name":"tmp"}]}],"dnsPolicy":"Default","nodeSelector":{"caas_cluster":"kube-system"},"priorityClassName":"system-cluster-critical","restartPolicy":"Always","schedulerName":"default-scheduler","securityContext":{},"serviceAccount":"coredns","serviceAccountName":"coredns","terminationGracePeriodSeconds":30,"tolerations":[{"key":"CriticalAddonsOnly","operator":"Exists"},{"effect":"NoSchedule","key":"node-role.kubernetes.io/master"}],"volumes":[{"emptyDir":{},"name":"tmp"},{"configMap":{"defaultMode":420,"items":[{"key":"Corefile","path":"Corefile"}],"name":"coredns"},"name":"config-volume"}]}}}}
  creationTimestamp: "2022-02-08T09:01:12Z"
  generation: 2
  labels:
    k8s-app: kube-dns
  name: coredns
  namespace: kube-system
  resourceVersion: "26200487"
  selfLink: /apis/extensions/v1beta1/namespaces/kube-system/deployments/coredns
  uid: a057d689-5d2c-4db9-89b1-0e480392f861
spec:
  progressDeadlineSeconds: 600
  replicas: 2
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kube-dns
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        k8s-app: kube-dns
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: k8s-app
                operator: In
                values:
                - coredns
            topologyKey: kubernetes.io/hostname
      containers:
      - args:
        - -conf
        - /etc/coredns/Corefile
        image: harbor-vip.pcloud.localdomain/library/coredns:1.3.1
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 5
          httpGet:
            path: /health
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 5
        name: coredns
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
        - containerPort: 9153
          name: metrics
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /health
            port: 8080
            scheme: HTTP
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        resources:
          limits:
            memory: 170Mi
          requests:
            cpu: 100m
            memory: 70Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - NET_BIND_SERVICE
            drop:
            - all
          readOnlyRootFilesystem: true
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /etc/coredns
          name: config-volume
          readOnly: true
        - mountPath: /tmp
          name: tmp
      dnsPolicy: Default
      nodeSelector:
        caas_cluster: kube-system
      priorityClassName: system-cluster-critical
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      serviceAccount: coredns
      serviceAccountName: coredns
      terminationGracePeriodSeconds: 30
      tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - effect: NoSchedule
        key: node-role.kubernetes.io/master
      volumes:
      - emptyDir: {}
        name: tmp
      - configMap:
          defaultMode: 420
          items:
          - key: Corefile
            path: Corefile
          name: coredns
        name: config-volume
status:
  availableReplicas: 2
  conditions:
  - lastTransitionTime: "2022-02-08T09:02:21Z"
    lastUpdateTime: "2022-02-08T09:02:21Z"
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
  - lastTransitionTime: "2022-02-08T09:01:12Z"
    lastUpdateTime: "2022-05-11T06:28:06Z"
    message: ReplicaSet "coredns-548b55d588" has successfully progressed.
    reason: NewReplicaSetAvailable
    status: "True"
    type: Progressing
  observedGeneration: 2
  readyReplicas: 2
  replicas: 2
  updatedReplicas: 2

```

# 测试验证

## 配置生效后调度结果

kubectl get pods -n kube-system -owide | grep coredns

```
coredns-548b55d588-9f88b                  1/1     Running   0          3h36m   192.168.184.214   172.25.131.3    <none>           <none>
coredns-548b55d588-9tr4p                  1/1     Running   0          3h36m   192.168.157.157   172.25.131.2    <none>           <none>

```

## 查看svc信息

kubectl get svc -n kube-system

```
NAME                                 TYPE        CLUSTER-IP        EXTERNAL-IP   PORT(S)             AGE
calico-typha                         ClusterIP   172.254.75.120    <none>        5473/TCP            92d
csi-attacher-plugin                  ClusterIP   172.254.226.26    <none>        12347/TCP           92d
csi-provisioner-plugin               ClusterIP   172.254.213.218   <none>        12348/TCP           92d
etcd-k8s                             ClusterIP   None              <none>        2379/TCP            92d
ingress-nginx                        ClusterIP   172.254.63.7      <none>        80/TCP,443/TCP      92d
kube-apiserver                       ClusterIP   None              <none>        443/TCP             92d
kube-controller-manager-monitoring   ClusterIP   None              <none>        10252/TCP           92d
kube-dns                             ClusterIP   172.254.0.2       <none>        53/UDP,53/TCP       92d
kube-scheduler-monitoring            ClusterIP   None              <none>        10251/TCP           92d
kube-state-metrics                   ClusterIP   None              <none>        8443/TCP,9443/TCP   92d
kubelet                              ClusterIP   None              <none>        10250/TCP           92d
metrics-server                       ClusterIP   172.254.168.214   <none>        443/TCP             92d
node-exporter                        ClusterIP   None              <none>        9100/TCP            92d
prometheus-k8s                       NodePort    172.254.23.245    <none>        9090:30004/TCP      92d
prometheus-operated                  ClusterIP   None              <none>        9090/TCP            92d
prometheus-operator                  ClusterIP   None              <none>        8080/TCP            92d
tiller-deploy                        ClusterIP   172.254.251.97    <none>        44134/TCP           92d

```



## DNS服务测试

登陆任意一台非master节点

dig @172.254.0.2 prometheus-k8s-0.prometheus-operated.kube-system.svc

```

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-9.P2.el7 <<>> @172.254.0.2 prometheus-k8s-0.prometheus-operated.kube-system.svc
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 29446
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;prometheus-k8s-0.prometheus-operated.kube-system.svc. IN A

;; AUTHORITY SECTION:
.                       30      IN      SOA     a.root-servers.net. nstld.verisign-grs.com. 2022051100 1800 900 604800 86400

;; Query time: 42 msec
;; SERVER: 172.254.0.2#53(172.254.0.2)
;; WHEN: Wed May 11 14:41:17 CST 2022
;; MSG SIZE  rcvd: 156

```

