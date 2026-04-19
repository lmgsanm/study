# helm部署

## helm安装

https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring --create-namespace

```

> NAME: prometheus-stack
> LAST DEPLOYED: Sun Apr 19 15:24:41 2026
> NAMESPACE: monitoring
> STATUS: deployed
> REVISION: 1
> TEST SUITE: None
> NOTES:
> kube-prometheus-stack has been installed. Check its status by running:
>   kubectl --namespace monitoring get pods -l "release=prometheus-stack"
>
> Get Grafana 'admin' user password by running:
>
>   kubectl --namespace monitoring get secrets prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
>
> Access Grafana local instance:
>
>   export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=prometheus-stack" -oname)
>   kubectl --namespace monitoring port-forward $POD_NAME 3000
>
> Get your grafana admin user password by running:
>
>   kubectl get secret --namespace monitoring -l app.kubernetes.io/component=admin-secret -o jsonpath="{.items[0].data.admin-password}" | base64 --decode ; echo
>
>
> Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.

```
[root@kube-master ~]# kubectl get pod -n monitoring
NAME                                                     READY   STATUS    RESTARTS   AGE
alertmanager-prometheus-stack-kube-prom-alertmanager-0   2/2     Running   0          9m48s
prometheus-prometheus-stack-kube-prom-prometheus-0       2/2     Running   0          9m47s
prometheus-stack-grafana-74bbcdf759-vr5jz                3/3     Running   0          9m54s
prometheus-stack-kube-prom-operator-69859674b8-rltwd     1/1     Running   0          9m54s
prometheus-stack-kube-state-metrics-5dbc5bbd58-g67vh     1/1     Running   0          9m54s
prometheus-stack-prometheus-node-exporter-6bknh          1/1     Running   0          9m54s
prometheus-stack-prometheus-node-exporter-6kvxd          1/1     Running   0          9m54s
prometheus-stack-prometheus-node-exporter-wtdj9          1/1     Running   0          9m54s

[root@kube-master ~]# kubectl get svc -n monitoring
NAME                                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
alertmanager-operated                       ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP   11m
prometheus-operated                         ClusterIP   None             <none>        9090/TCP                     11m
prometheus-stack-grafana                    ClusterIP   10.108.70.126    <none>        80/TCP                       11m
prometheus-stack-kube-prom-alertmanager     ClusterIP   10.101.20.249    <none>        9093/TCP,8080/TCP            11m
prometheus-stack-kube-prom-operator         ClusterIP   10.108.164.126   <none>        443/TCP                      11m
prometheus-stack-kube-prom-prometheus       ClusterIP   10.103.246.184   <none>        9090/TCP,8080/TCP            11m
prometheus-stack-kube-state-metrics         ClusterIP   10.96.94.60      <none>        8080/TCP                     11m
prometheus-stack-prometheus-node-exporter   ClusterIP   10.109.101.172   <none>        9100/TCP                     11m


```

查看values

```
helm show values oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack
```

```
kubectl -n kube-system edit cm kube-proxy
metricsBindAddress: 0.0.0.0:10249
```



## helm卸载

```
helm uninstall prometheus-community -n monitoring
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd probes.monitoring.coreos.com
kubectl delete crd prometheusagents.monitoring.coreos.com
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd scrapeconfigs.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
```



## ingresss配置

ingress-monitoring.yaml

## grafana密码

```
[root@kube-master ~]# kubectl get secret -n monitoring
NAME                                                                                  TYPE                 DATA   AGE
alertmanager-prometheus-stack-kube-prom-alertmanager                                  Opaque               1      24m
alertmanager-prometheus-stack-kube-prom-alertmanager-cluster-tls-config               Opaque               1      24m
alertmanager-prometheus-stack-kube-prom-alertmanager-generated                        Opaque               1      24m
alertmanager-prometheus-stack-kube-prom-alertmanager-tls-assets-0                     Opaque               0      24m
alertmanager-prometheus-stack-kube-prom-alertmanager-web-config                       Opaque               1      24m
prometheus-prometheus-stack-kube-prom-prometheus                                      Opaque               1      24m
prometheus-prometheus-stack-kube-prom-prometheus-thanos-prometheus-http-client-file   Opaque               1      24m
prometheus-prometheus-stack-kube-prom-prometheus-tls-assets-0                         Opaque               1      24m
prometheus-prometheus-stack-kube-prom-prometheus-web-config                           Opaque               1      24m
prometheus-stack-grafana                                                              Opaque               3      24m
prometheus-stack-kube-prom-admission                                                  Opaque               3      24m
sh.helm.release.v1.prometheus-stack.v1                                                helm.sh/release.v1   1      24m

[root@kube-master ~]# kubectl describe secret prometheus-stack-grafana -n monitoring
Name:         prometheus-stack-grafana
Namespace:    monitoring
Labels:       app.kubernetes.io/component=admin-secret
              app.kubernetes.io/instance=prometheus-stack
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=grafana
              app.kubernetes.io/version=12.4.3
              helm.sh/chart=grafana-11.6.1
Annotations:  meta.helm.sh/release-name: prometheus-stack
              meta.helm.sh/release-namespace: monitoring

Type:  Opaque

Data
====
admin-password:  40 bytes
admin-user:      5 bytes
ldap-toml:       0 bytes

```

```
kubectl get secret --namespace monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

```

# 访问地址

## prometheus

http://prometheus.example.com/query

![image-20260419165257787](prometheus%E9%83%A8%E7%BD%B2.assets/image-20260419165257787.png)

## alertmanager

http://alertmanager.example.com/#/alerts

## grafana

http://grafana.example.com/dashboards

![image-20260419165322548](prometheus%E9%83%A8%E7%BD%B2.assets/image-20260419165322548.png)

# 报错处理

## controller-manager获取不到监控数据

![image-20260419170400930](prometheus%E9%83%A8%E7%BD%B2.assets/image-20260419170400930.png)

## etcd获取不到监控数据

![image-20260419170438338](prometheus%E9%83%A8%E7%BD%B2.assets/image-20260419170438338.png)

## kube-proxy获取不到监控数据

![image-20260419170509234](prometheus%E9%83%A8%E7%BD%B2.assets/image-20260419170509234.png)

## kube-scheduler获取不到监控数据

![image-20260419170538944](prometheus%E9%83%A8%E7%BD%B2.assets/image-20260419170538944.png)