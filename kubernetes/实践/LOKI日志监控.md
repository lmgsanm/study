

```
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
 helm show values  grafana/loki-stack > values.yaml
kubectl create namespace logging
helm install loki grafana/loki-stack   --namespace logging   -f values.yaml

helm upgrade loki grafana/loki-stack   --namespace logging   -f values.yaml

```



```
[root@kube-master loki]# kubectl get pod,svc,ingress -n logging
NAME                      READY   STATUS    RESTARTS   AGE
pod/loki-0                1/1     Running   0          13m
pod/loki-promtail-4wv5g   1/1     Running   0          13m
pod/loki-promtail-k8zvh   1/1     Running   0          10m

NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/loki              ClusterIP   10.104.133.191   <none>        3100/TCP   13m
service/loki-headless     ClusterIP   None             <none>        3100/TCP   13m
service/loki-memberlist   ClusterIP   None             <none>        7946/TCP   13m

NAME                                     CLASS   HOSTS                   ADDRESS          PORTS   AGE
ingress.networking.k8s.io/loki-ingress   nginx   loki.lmgsanm.test.com   172.23.171.173   80      5m55s


```



curl -v http://<你的Loki域名或IP>:3100/ready

```

```





```
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
kubectl create namespace logging
helm install loki grafana/loki \
  --namespace logging \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=10Gi \
  --set loki.storage.type=filesystem
  
 helm install promtail grafana/promtail \
  --namespace logging \
  --set config.lokiAddress=http://loki.loki.svc.cluster.local:3100/loki/api/v1/push
  

```

