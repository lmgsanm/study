

The Ingress-Nginx Controller can export Prometheus metrics, by setting `controller.metrics.enabled` to `true`.

You can add Prometheus annotations to the metrics service using `controller.metrics.service.annotations`. Alternatively, if you use the Prometheus Operator, you can enable ServiceMonitor creation using `controller.metrics.serviceMonitor.enabled`. And set `controller.metrics.serviceMonitor.additionalLabels.release="prometheus"`. "release=prometheus" should match the label configured in the prometheus servicemonitor ( see `kubectl get servicemonitor prometheus-kube-prom-prometheus -oyaml -n prometheus`)

```
[root@kube-master kube-prometheus-stack]# kubectl get svc -n ingress-nginx
NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             NodePort    10.111.140.61   <none>        80:30080/TCP,443:30443/TCP   53m
ingress-nginx-controller-admission   ClusterIP   10.108.250.32   <none>        443/TCP                 

[root@kube-master kube-prometheus-stack]# kubectl describe svc ingress-nginx-controller -n ingress-nginx
Name:                     ingress-nginx-controller
Namespace:                ingress-nginx
Labels:                   app.kubernetes.io/component=controller
                          app.kubernetes.io/instance=ingress-nginx
                          app.kubernetes.io/name=ingress-nginx
                          app.kubernetes.io/part-of=ingress-nginx
                          app.kubernetes.io/version=1.15.1
Annotations:              <none>
Selector:                 app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.111.140.61
IPs:                      10.111.140.61
Port:                     http  80/TCP
TargetPort:               http/TCP
NodePort:                 http  30080/TCP
Endpoints:                192.168.238.55:80
Port:                     https  443/TCP
TargetPort:               https/TCP
NodePort:                 https  30443/TCP
Endpoints:                192.168.238.55:443
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:                   <none>

[root@kube-master kube-prometheus-stack]# kubectl describe svc ingress-nginx-controller-admission -n ingress-nginx
Name:                     ingress-nginx-controller-admission
Namespace:                ingress-nginx
Labels:                   app.kubernetes.io/component=controller
                          app.kubernetes.io/instance=ingress-nginx
                          app.kubernetes.io/name=ingress-nginx
                          app.kubernetes.io/part-of=ingress-nginx
                          app.kubernetes.io/version=1.15.1
Annotations:              <none>
Selector:                 app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.108.250.32
IPs:                      10.108.250.32
Port:                     https-webhook  443/TCP
TargetPort:               webhook/TCP
Endpoints:                192.168.238.55:8443
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

```

# 准备工作

## helm部署

- The Ingress-Nginx Controller should already be deployed according to the deployment instructions [here](https://github.com/kubernetes/ingress-nginx/blob/main/docs/deploy/index.md).

- The controller should be configured for exporting metrics. This requires 3 configurations to the controller. These configurations are:

  1. controller.metrics.enabled=true
  2. controller.podAnnotations."prometheus.io/scrape"="true"
  3. controller.podAnnotations."prometheus.io/port"="10254"

  - The easiest way to configure the controller for metrics is via helm upgrade. Assuming you have installed the ingress-nginx controller as a helm release named ingress-nginx, then you can simply type the command shown below :

  ```
  helm upgrade ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.metrics.enabled=true \
  --set-string controller.podAnnotations."prometheus\.io/scrape"="true" \
  --set-string controller.podAnnotations."prometheus\.io/port"="10254"
  ```

  

  - You can validate that the controller is configured for metrics by looking at the values of the installed release, like this:

  ```
  helm get values ingress-nginx --namespace ingress-nginx
  ```

  

  - You should be able to see the values shown below:

  ```
  ..
  controller:
    metrics:
      enabled: true
    podAnnotations:
      prometheus.io/port: "10254"
      prometheus.io/scrape: "true"
  ..
  ```

- ```
  helm upgrade ingress-nginx ingress-nginx/ingress-nginx --version 4.15.1 \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.service.nodePorts.http=30080 \
    --set controller.service.nodePorts.https=30443 \
    --set controller.service.type=NodePort \
    --set controller.metrics.enabled=true \
    --set-string controller.podAnnotations."prometheus\.io/scrape"="true" \
    --set-string controller.podAnnotations."prometheus\.io/port"="10254" 
    
  ```



```
[root@kube-master kube-prometheus-stack]# kubectl get svc -n ingress-nginx
NAME                                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             NodePort    10.100.42.105    <none>        80:30080/TCP,443:30443/TCP   25m
ingress-nginx-controller-admission   ClusterIP   10.111.255.118   <none>        443/TCP                      25m
ingress-nginx-controller-metrics     ClusterIP   10.98.177.110    <none>        10254/TCP                    2m57s

```



## deploy部署

- - If you are not using helm, you will have to edit your manifests like this:

    Service manifest:

    ```
    apiVersion: v1
    kind: Service
    ..
    spec:
      ports:
        - name: prometheus
          port: 10254
          targetPort: prometheus
          ..
    ```

​	Deployment manifest:

```
apiVersion: v1
kind: Deployment
..
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "10254"
    spec:
      containers:
        - name: controller
          args:
            ..
            - '--enable-metrics=true'
          ports:
            - name: prometheus
              containerPort: 10254
```

Error from server (Invalid): error when replacing "deploy.yaml": Service "ingress-nginx-controller" is invalid: spec.ports[0].targetPort: Invalid value: "prometheus`": must contain only alpha-numeric characters (a-z, 0-9), and hyphens (-)
Error from server (BadRequest): error when replacing "deploy.yaml": Deployment in version "v1" cannot be handled as a Deployment: strict decoding error: unknown field "spec.template.metadata.prometheus.io/port", unknown field "spec.template.metadata.prometheus.io/scrape"

# 接入prometheus

## describe meric的svc

```
[root@kube-master ingress-nginx]# kubectl describe svc ingress-nginx-controller-metrics -n ingress-nginx
Name:                     ingress-nginx-controller-metrics
Namespace:                ingress-nginx
Labels:                   app.kubernetes.io/component=controller
                          app.kubernetes.io/instance=ingress-nginx
                          app.kubernetes.io/managed-by=Helm
                          app.kubernetes.io/name=ingress-nginx
                          app.kubernetes.io/part-of=ingress-nginx
                          app.kubernetes.io/version=1.15.1
                          helm.sh/chart=ingress-nginx-4.15.1
Annotations:              meta.helm.sh/release-name: ingress-nginx
                          meta.helm.sh/release-namespace: ingress-nginx
Selector:                 app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.98.177.110
IPs:                      10.98.177.110
Port:                     metrics  10254/TCP
TargetPort:               metrics/TCP
Endpoints:                192.168.0.147:10254
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

```

## 查看metrics详情

```
[root@kube-master ingress-nginx]# kubectl get svc ingress-nginx-controller-metrics -n ingress-nginx -oyaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    meta.helm.sh/release-name: ingress-nginx
    meta.helm.sh/release-namespace: ingress-nginx
  creationTimestamp: "2026-04-19T09:18:09Z"
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.15.1
    helm.sh/chart: ingress-nginx-4.15.1
  name: ingress-nginx-controller-metrics
  namespace: ingress-nginx
  resourceVersion: "100560"
  uid: 5170237f-311c-4e58-a0a1-b062a8e13ae9
spec:
  clusterIP: 10.98.177.110
  clusterIPs:
  - 10.98.177.110
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: metrics
    port: 10254
    protocol: TCP
    targetPort: metrics
  selector:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
```



# 可监控指标

```

# HELP go_gc_duration_seconds A summary of the wall-time pause (stop-the-world) duration in garbage collection cycles.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 6.9116e-05
go_gc_duration_seconds{quantile="0.25"} 0.00010614
go_gc_duration_seconds{quantile="0.5"} 0.000243601
go_gc_duration_seconds{quantile="0.75"} 0.000318926
go_gc_duration_seconds{quantile="1"} 0.000947398
go_gc_duration_seconds_sum 0.003083786
go_gc_duration_seconds_count 12
# HELP go_gc_gogc_percent Heap size target percentage configured by the user, otherwise 100. This value is set by the GOGC environment variable, and the runtime/debug.SetGCPercent function. Sourced from /gc/gogc:percent.
# TYPE go_gc_gogc_percent gauge
go_gc_gogc_percent 100
# HELP go_gc_gomemlimit_bytes Go runtime memory limit configured by the user, otherwise math.MaxInt64. This value is set by the GOMEMLIMIT environment variable, and the runtime/debug.SetMemoryLimit function. Sourced from /gc/gomemlimit:bytes.
# TYPE go_gc_gomemlimit_bytes gauge
go_gc_gomemlimit_bytes 9.223372036854776e+18
# HELP go_goroutines Number of goroutines that currently exist.
# TYPE go_goroutines gauge
go_goroutines 96
# HELP go_info Information about the Go environment.
# TYPE go_info gauge
go_info{version="go1.26.1"} 1
# HELP go_memstats_alloc_bytes Number of bytes allocated in heap and currently in use. Equals to /memory/classes/heap/objects:bytes.
# TYPE go_memstats_alloc_bytes gauge
go_memstats_alloc_bytes 6.388736e+06
# HELP go_memstats_alloc_bytes_total Total number of bytes allocated in heap until now, even if released already. Equals to /gc/heap/allocs:bytes.
# TYPE go_memstats_alloc_bytes_total counter
go_memstats_alloc_bytes_total 3.429576e+07
# HELP go_memstats_buck_hash_sys_bytes Number of bytes used by the profiling bucket hash table. Equals to /memory/classes/profiling/buckets:bytes.
# TYPE go_memstats_buck_hash_sys_bytes gauge
go_memstats_buck_hash_sys_bytes 1.46099e+06
# HELP go_memstats_frees_total Total number of heap objects frees. Equals to /gc/heap/frees:objects + /gc/heap/tiny/allocs:objects.
# TYPE go_memstats_frees_total counter
go_memstats_frees_total 322776
# HELP go_memstats_gc_sys_bytes Number of bytes used for garbage collection system metadata. Equals to /memory/classes/metadata/other:bytes.
# TYPE go_memstats_gc_sys_bytes gauge
go_memstats_gc_sys_bytes 3.990256e+06
# HELP go_memstats_heap_alloc_bytes Number of heap bytes allocated and currently in use, same as go_memstats_alloc_bytes. Equals to /memory/classes/heap/objects:bytes.
# TYPE go_memstats_heap_alloc_bytes gauge
go_memstats_heap_alloc_bytes 6.388736e+06
# HELP go_memstats_heap_idle_bytes Number of heap bytes waiting to be used. Equals to /memory/classes/heap/released:bytes + /memory/classes/heap/free:bytes.
# TYPE go_memstats_heap_idle_bytes gauge
go_memstats_heap_idle_bytes 9.322496e+06
# HELP go_memstats_heap_inuse_bytes Number of heap bytes that are in use. Equals to /memory/classes/heap/objects:bytes + /memory/classes/heap/unused:bytes
# TYPE go_memstats_heap_inuse_bytes gauge
go_memstats_heap_inuse_bytes 9.814016e+06
# HELP go_memstats_heap_objects Number of currently allocated objects. Equals to /gc/heap/objects:objects.
# TYPE go_memstats_heap_objects gauge
go_memstats_heap_objects 72450
# HELP go_memstats_heap_released_bytes Number of heap bytes released to OS. Equals to /memory/classes/heap/released:bytes.
# TYPE go_memstats_heap_released_bytes gauge
go_memstats_heap_released_bytes 7.340032e+06
# HELP go_memstats_heap_sys_bytes Number of heap bytes obtained from system. Equals to /memory/classes/heap/objects:bytes + /memory/classes/heap/unused:bytes + /memory/classes/heap/released:bytes + /memory/classes/heap/free:bytes.
# TYPE go_memstats_heap_sys_bytes gauge
go_memstats_heap_sys_bytes 1.9136512e+07
# HELP go_memstats_last_gc_time_seconds Number of seconds since 1970 of last garbage collection.
# TYPE go_memstats_last_gc_time_seconds gauge
go_memstats_last_gc_time_seconds 1.776590324351364e+09
# HELP go_memstats_mallocs_total Total number of heap objects allocated, both live and gc-ed. Semantically a counter version for go_memstats_heap_objects gauge. Equals to /gc/heap/allocs:objects + /gc/heap/tiny/allocs:objects.
# TYPE go_memstats_mallocs_total counter
go_memstats_mallocs_total 395226
# HELP go_memstats_mcache_inuse_bytes Number of bytes in use by mcache structures. Equals to /memory/classes/metadata/mcache/inuse:bytes.
# TYPE go_memstats_mcache_inuse_bytes gauge
go_memstats_mcache_inuse_bytes 18368
# HELP go_memstats_mcache_sys_bytes Number of bytes used for mcache structures obtained from system. Equals to /memory/classes/metadata/mcache/inuse:bytes + /memory/classes/metadata/mcache/free:bytes.
# TYPE go_memstats_mcache_sys_bytes gauge
go_memstats_mcache_sys_bytes 32144
# HELP go_memstats_mspan_inuse_bytes Number of bytes in use by mspan structures. Equals to /memory/classes/metadata/mspan/inuse:bytes.
# TYPE go_memstats_mspan_inuse_bytes gauge
go_memstats_mspan_inuse_bytes 194880
# HELP go_memstats_mspan_sys_bytes Number of bytes used for mspan structures obtained from system. Equals to /memory/classes/metadata/mspan/inuse:bytes + /memory/classes/metadata/mspan/free:bytes.
# TYPE go_memstats_mspan_sys_bytes gauge
go_memstats_mspan_sys_bytes 261120
# HELP go_memstats_next_gc_bytes Number of heap bytes when next garbage collection will take place. Equals to /gc/heap/goal:bytes.
# TYPE go_memstats_next_gc_bytes gauge
go_memstats_next_gc_bytes 1.0368746e+07
# HELP go_memstats_other_sys_bytes Number of bytes used for other system allocations. Equals to /memory/classes/other:bytes.
# TYPE go_memstats_other_sys_bytes gauge
go_memstats_other_sys_bytes 1.749386e+06
# HELP go_memstats_stack_inuse_bytes Number of bytes obtained from system for stack allocator in non-CGO environments. Equals to /memory/classes/heap/stacks:bytes.
# TYPE go_memstats_stack_inuse_bytes gauge
go_memstats_stack_inuse_bytes 1.835008e+06
# HELP go_memstats_stack_sys_bytes Number of bytes obtained from system for stack allocator. Equals to /memory/classes/heap/stacks:bytes + /memory/classes/os-stacks:bytes.
# TYPE go_memstats_stack_sys_bytes gauge
go_memstats_stack_sys_bytes 1.835008e+06
# HELP go_memstats_sys_bytes Number of bytes obtained from system. Equals to /memory/classes/total:byte.
# TYPE go_memstats_sys_bytes gauge
go_memstats_sys_bytes 2.8465416e+07
# HELP go_sched_gomaxprocs_threads The current runtime.GOMAXPROCS setting, or the number of operating system threads that can execute user-level Go code simultaneously. Sourced from /sched/gomaxprocs:threads.
# TYPE go_sched_gomaxprocs_threads gauge
go_sched_gomaxprocs_threads 8
# HELP go_threads Number of OS threads created.
# TYPE go_threads gauge
go_threads 14
# HELP nginx_ingress_controller_admission_config_size The size of the tested configuration
# TYPE nginx_ingress_controller_admission_config_size gauge
nginx_ingress_controller_admission_config_size{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 0
# HELP nginx_ingress_controller_admission_render_duration The processing duration of ingresses rendering by the admission controller (float seconds)
# TYPE nginx_ingress_controller_admission_render_duration gauge
nginx_ingress_controller_admission_render_duration{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 0
# HELP nginx_ingress_controller_admission_render_ingresses The length of ingresses rendered by the admission controller
# TYPE nginx_ingress_controller_admission_render_ingresses gauge
nginx_ingress_controller_admission_render_ingresses{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 0
# HELP nginx_ingress_controller_admission_roundtrip_duration The complete duration of the admission controller at the time to process a new event (float seconds)
# TYPE nginx_ingress_controller_admission_roundtrip_duration gauge
nginx_ingress_controller_admission_roundtrip_duration{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 0
# HELP nginx_ingress_controller_admission_tested_duration The processing duration of the admission controller tests (float seconds)
# TYPE nginx_ingress_controller_admission_tested_duration gauge
nginx_ingress_controller_admission_tested_duration{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 0
# HELP nginx_ingress_controller_admission_tested_ingresses The length of ingresses processed by the admission controller
# TYPE nginx_ingress_controller_admission_tested_ingresses gauge
nginx_ingress_controller_admission_tested_ingresses{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 0
# HELP nginx_ingress_controller_build_info A metric with a constant '1' labeled with information about the build.
# TYPE nginx_ingress_controller_build_info gauge
nginx_ingress_controller_build_info{build="0df02f2cfcf5fe4ad3cf31492bca770ac2a1606a",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",release="v1.15.1",repository="https://github.com/kubernetes/ingress-nginx"} 1
# HELP nginx_ingress_controller_bytes_sent DEPRECATED The number of bytes sent to a client
# TYPE nginx_ingress_controller_bytes_sent histogram
nginx_ingress_controller_bytes_sent_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="10"} 0
nginx_ingress_controller_bytes_sent_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="100"} 0
nginx_ingress_controller_bytes_sent_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="1000"} 1
nginx_ingress_controller_bytes_sent_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="10000"} 1
nginx_ingress_controller_bytes_sent_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="100000"} 1
nginx_ingress_controller_bytes_sent_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="1e+06"} 1
nginx_ingress_controller_bytes_sent_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="1e+07"} 1
nginx_ingress_controller_bytes_sent_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="+Inf"} 1
nginx_ingress_controller_bytes_sent_sum{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200"} 180
nginx_ingress_controller_bytes_sent_count{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200"} 1
# HELP nginx_ingress_controller_config_hash Running configuration hash actually running
# TYPE nginx_ingress_controller_config_hash gauge
nginx_ingress_controller_config_hash{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 3.1325924438330885e+18
# HELP nginx_ingress_controller_config_last_reload_successful Whether the last configuration reload attempt was successful
# TYPE nginx_ingress_controller_config_last_reload_successful gauge
nginx_ingress_controller_config_last_reload_successful{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 1
# HELP nginx_ingress_controller_config_last_reload_successful_timestamp_seconds Timestamp of the last successful configuration reload.
# TYPE nginx_ingress_controller_config_last_reload_successful_timestamp_seconds gauge
nginx_ingress_controller_config_last_reload_successful_timestamp_seconds{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 1.776590291e+09
# HELP nginx_ingress_controller_connect_duration_seconds The time spent on establishing a connection with the upstream server
# TYPE nginx_ingress_controller_connect_duration_seconds histogram
nginx_ingress_controller_connect_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.005"} 1
nginx_ingress_controller_connect_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.01"} 1
nginx_ingress_controller_connect_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.025"} 1
nginx_ingress_controller_connect_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.05"} 1
nginx_ingress_controller_connect_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.1"} 1
nginx_ingress_controller_connect_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.25"} 1
nginx_ingress_controller_connect_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.5"} 1
nginx_ingress_controller_connect_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="1"} 1
nginx_ingress_controller_connect_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="2.5"} 1
nginx_ingress_controller_connect_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="5"} 1
nginx_ingress_controller_connect_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="10"} 1
nginx_ingress_controller_connect_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="+Inf"} 1
nginx_ingress_controller_connect_duration_seconds_sum{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200"} 0.001
nginx_ingress_controller_connect_duration_seconds_count{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200"} 1
# HELP nginx_ingress_controller_header_duration_seconds The time spent on receiving first header from the upstream server
# TYPE nginx_ingress_controller_header_duration_seconds histogram
nginx_ingress_controller_header_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.005"} 1
nginx_ingress_controller_header_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.01"} 1
nginx_ingress_controller_header_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.025"} 1
nginx_ingress_controller_header_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.05"} 1
nginx_ingress_controller_header_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.1"} 1
nginx_ingress_controller_header_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.25"} 1
nginx_ingress_controller_header_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.5"} 1
nginx_ingress_controller_header_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="1"} 1
nginx_ingress_controller_header_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="2.5"} 1
nginx_ingress_controller_header_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="5"} 1
nginx_ingress_controller_header_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="10"} 1
nginx_ingress_controller_header_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="+Inf"} 1
nginx_ingress_controller_header_duration_seconds_sum{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200"} 0.003
nginx_ingress_controller_header_duration_seconds_count{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200"} 1
# HELP nginx_ingress_controller_nginx_process_connections current number of client connections with state {active, reading, writing, waiting}
# TYPE nginx_ingress_controller_nginx_process_connections gauge
nginx_ingress_controller_nginx_process_connections{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",state="active"} 1
nginx_ingress_controller_nginx_process_connections{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",state="reading"} 0
nginx_ingress_controller_nginx_process_connections{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",state="waiting"} 0
nginx_ingress_controller_nginx_process_connections{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",state="writing"} 1
# HELP nginx_ingress_controller_nginx_process_connections_total total number of connections with state {accepted, handled}
# TYPE nginx_ingress_controller_nginx_process_connections_total counter
nginx_ingress_controller_nginx_process_connections_total{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",state="accepted"} 21
nginx_ingress_controller_nginx_process_connections_total{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",state="handled"} 21
# HELP nginx_ingress_controller_nginx_process_cpu_seconds_total Cpu usage in seconds
# TYPE nginx_ingress_controller_nginx_process_cpu_seconds_total counter
nginx_ingress_controller_nginx_process_cpu_seconds_total{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 0.25999999999999995
# HELP nginx_ingress_controller_nginx_process_num_procs number of processes
# TYPE nginx_ingress_controller_nginx_process_num_procs gauge
nginx_ingress_controller_nginx_process_num_procs{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 12
# HELP nginx_ingress_controller_nginx_process_oldest_start_time_seconds start time in seconds since 1970/01/01
# TYPE nginx_ingress_controller_nginx_process_oldest_start_time_seconds gauge
nginx_ingress_controller_nginx_process_oldest_start_time_seconds{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 1.776590289e+09
# HELP nginx_ingress_controller_nginx_process_read_bytes_total number of bytes read
# TYPE nginx_ingress_controller_nginx_process_read_bytes_total counter
nginx_ingress_controller_nginx_process_read_bytes_total{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 0
# HELP nginx_ingress_controller_nginx_process_requests_total total number of client requests
# TYPE nginx_ingress_controller_nginx_process_requests_total counter
nginx_ingress_controller_nginx_process_requests_total{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 20
# HELP nginx_ingress_controller_nginx_process_resident_memory_bytes number of bytes of memory in use
# TYPE nginx_ingress_controller_nginx_process_resident_memory_bytes gauge
nginx_ingress_controller_nginx_process_resident_memory_bytes{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 2.1164032e+08
# HELP nginx_ingress_controller_nginx_process_virtual_memory_bytes number of bytes of memory in use
# TYPE nginx_ingress_controller_nginx_process_virtual_memory_bytes gauge
nginx_ingress_controller_nginx_process_virtual_memory_bytes{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 2.651070464e+09
# HELP nginx_ingress_controller_nginx_process_write_bytes_total number of bytes written
# TYPE nginx_ingress_controller_nginx_process_write_bytes_total counter
nginx_ingress_controller_nginx_process_write_bytes_total{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 61440
# HELP nginx_ingress_controller_orphan_ingress Gauge reporting status of ingress orphanity, 1 indicates orphaned ingress.\n                       'namespace' is the string used to identify namespace of ingress, 'ingress' for ingress name and 'type' for 'no-service' or 'no-endpoint' of orphanity
# TYPE nginx_ingress_controller_orphan_ingress gauge
nginx_ingress_controller_orphan_ingress{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",ingress="monitoring-ingress",namespace="monitoring",type="no-endpoint"} 0
nginx_ingress_controller_orphan_ingress{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",ingress="monitoring-ingress",namespace="monitoring",type="no-service"} 0
# HELP nginx_ingress_controller_request_duration_seconds The request processing time in milliseconds
# TYPE nginx_ingress_controller_request_duration_seconds histogram
nginx_ingress_controller_request_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.005"} 0
nginx_ingress_controller_request_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.01"} 0
nginx_ingress_controller_request_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.025"} 0
nginx_ingress_controller_request_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.05"} 0
nginx_ingress_controller_request_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.1"} 0
nginx_ingress_controller_request_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.25"} 1
nginx_ingress_controller_request_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.5"} 1
nginx_ingress_controller_request_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="1"} 1
nginx_ingress_controller_request_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="2.5"} 1
nginx_ingress_controller_request_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="5"} 1
nginx_ingress_controller_request_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="10"} 1
nginx_ingress_controller_request_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="+Inf"} 1
nginx_ingress_controller_request_duration_seconds_sum{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200"} 0.133
nginx_ingress_controller_request_duration_seconds_count{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200"} 1
# HELP nginx_ingress_controller_request_size The request length (including request line, header, and request body)
# TYPE nginx_ingress_controller_request_size histogram
nginx_ingress_controller_request_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="10"} 0
nginx_ingress_controller_request_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="20"} 0
nginx_ingress_controller_request_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="30"} 0
nginx_ingress_controller_request_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="40"} 0
nginx_ingress_controller_request_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="50"} 0
nginx_ingress_controller_request_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="60"} 0
nginx_ingress_controller_request_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="70"} 0
nginx_ingress_controller_request_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="80"} 0
nginx_ingress_controller_request_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="90"} 0
nginx_ingress_controller_request_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="100"} 0
nginx_ingress_controller_request_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="+Inf"} 1
nginx_ingress_controller_request_size_sum{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200"} 359
nginx_ingress_controller_request_size_count{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200"} 1
# HELP nginx_ingress_controller_requests The total number of client requests
# TYPE nginx_ingress_controller_requests counter
nginx_ingress_controller_requests{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200"} 1
# HELP nginx_ingress_controller_response_duration_seconds The time spent on receiving the response from the upstream server
# TYPE nginx_ingress_controller_response_duration_seconds histogram
nginx_ingress_controller_response_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.005"} 0
nginx_ingress_controller_response_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.01"} 0
nginx_ingress_controller_response_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.025"} 0
nginx_ingress_controller_response_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.05"} 0
nginx_ingress_controller_response_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.1"} 0
nginx_ingress_controller_response_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.25"} 1
nginx_ingress_controller_response_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="0.5"} 1
nginx_ingress_controller_response_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="1"} 1
nginx_ingress_controller_response_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="2.5"} 1
nginx_ingress_controller_response_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="5"} 1
nginx_ingress_controller_response_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="10"} 1
nginx_ingress_controller_response_duration_seconds_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="+Inf"} 1
nginx_ingress_controller_response_duration_seconds_sum{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200"} 0.134
nginx_ingress_controller_response_duration_seconds_count{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200"} 1
# HELP nginx_ingress_controller_response_size The response length (including request line, header, and request body)
# TYPE nginx_ingress_controller_response_size histogram
nginx_ingress_controller_response_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="10"} 0
nginx_ingress_controller_response_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="20"} 0
nginx_ingress_controller_response_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="30"} 0
nginx_ingress_controller_response_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="40"} 0
nginx_ingress_controller_response_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="50"} 0
nginx_ingress_controller_response_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="60"} 0
nginx_ingress_controller_response_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="70"} 0
nginx_ingress_controller_response_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="80"} 0
nginx_ingress_controller_response_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="90"} 0
nginx_ingress_controller_response_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="100"} 0
nginx_ingress_controller_response_size_bucket{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200",le="+Inf"} 1
nginx_ingress_controller_response_size_sum{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200"} 180
nginx_ingress_controller_response_size_count{canary="",controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh",host="prometheus.example.com",ingress="monitoring-ingress",method="GET",namespace="monitoring",path="/",service="prometheus-stack-kube-prom-prometheus",status="200"} 1
# HELP nginx_ingress_controller_ssl_certificate_info Hold all labels associated to a certificate
# TYPE nginx_ingress_controller_ssl_certificate_info gauge
nginx_ingress_controller_ssl_certificate_info{class="k8s.io/ingress-nginx",host="_",identifier="-165626895043401770364299435549261304887",issuer_common_name="Kubernetes Ingress Controller Fake Certificate",issuer_organization="Acme Co",namespace="",public_key_algorithm="RSA",secret_name="",serial_number="165626895043401770364299435549261304887"} 1
# HELP nginx_ingress_controller_success Cumulative number of Ingress controller reload operations
# TYPE nginx_ingress_controller_success counter
nginx_ingress_controller_success{controller_class="k8s.io/ingress-nginx",controller_namespace="ingress-nginx",controller_pod="ingress-nginx-controller-559584768b-g5tnh"} 1
# HELP process_cpu_seconds_total Total user and system CPU time spent in seconds.
# TYPE process_cpu_seconds_total counter
process_cpu_seconds_total 0.47
# HELP process_max_fds Maximum number of open file descriptors.
# TYPE process_max_fds gauge
process_max_fds 524287
# HELP process_network_receive_bytes_total Number of bytes received by the process over the network.
# TYPE process_network_receive_bytes_total counter
process_network_receive_bytes_total 813456
# HELP process_network_transmit_bytes_total Number of bytes sent by the process over the network.
# TYPE process_network_transmit_bytes_total counter
process_network_transmit_bytes_total 52724
# HELP process_open_fds Number of open file descriptors.
# TYPE process_open_fds gauge
process_open_fds 17
# HELP process_resident_memory_bytes Resident memory size in bytes.
# TYPE process_resident_memory_bytes gauge
process_resident_memory_bytes 5.5730176e+07
# HELP process_start_time_seconds Start time of the process since unix epoch in seconds.
# TYPE process_start_time_seconds gauge
process_start_time_seconds 1.77659028991e+09
# HELP process_virtual_memory_bytes Virtual memory size in bytes.
# TYPE process_virtual_memory_bytes gauge
process_virtual_memory_bytes 1.345814528e+09
# HELP process_virtual_memory_max_bytes Maximum amount of virtual memory available in bytes.
# TYPE process_virtual_memory_max_bytes gauge
process_virtual_memory_max_bytes 1.8446744073709552e+19
# HELP promhttp_metric_handler_requests_in_flight Current number of scrapes being served.
# TYPE promhttp_metric_handler_requests_in_flight gauge
promhttp_metric_handler_requests_in_flight 1
# HELP promhttp_metric_handler_requests_total Total number of scrapes by HTTP status code.
# TYPE promhttp_metric_handler_requests_total counter
promhttp_metric_handler_requests_total{code="200"} 0
promhttp_metric_handler_requests_total{code="500"} 0
promhttp_metric_handler_requests_total{code="503"} 0
```

