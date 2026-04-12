

https://argo-cd.readthedocs.io/en/stable/



```
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

wget https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
#编辑install.yaml，添加server.insecure: "true"配置（configmap）
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/name: argocd-cmd-params-cm
    app.kubernetes.io/part-of: argocd
  name: argocd-cmd-params-cm
data:
  server.insecure: "true"

kubectl apply -n argocd --server-side --force-conflicts -f install.yaml

```



```
[root@kube-master argocd]# kubectl get cm -n argocd
NAME                        DATA   AGE
argocd-cm                   9      27s
argocd-cmd-params-cm        1      27s
argocd-gpg-keys-cm          0      27s
argocd-notifications-cm     0      27s
argocd-rbac-cm              0      27s
argocd-ssh-known-hosts-cm   1      27s
argocd-tls-certs-cm         0      27s
kube-root-ca.crt            1      5m54s
[root@kube-master argocd]# kubectl get cm argocd-cmd-params-cm -n argocd -o yaml
apiVersion: v1
data:
  server.insecure: "true"
kind: ConfigMap
metadata:
  creationTimestamp: "2026-04-11T05:22:07Z"
  labels:
    app.kubernetes.io/name: argocd-cmd-params-cm
    app.kubernetes.io/part-of: argocd
  name: argocd-cmd-params-cm
  namespace: argocd
  resourceVersion: "25200"
  uid: e4f72cdf-87cc-4fac-9c0e-a158f78ad0b9

[root@kube-master argocd]# kubectl get pod -n argocd
NAME                                               READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                    1/1     Running   0          76s
argocd-applicationset-controller-6c467cf5b-xpkrg   1/1     Running   0          76s
argocd-dex-server-6764988664-mfqg6                 1/1     Running   0          76s
argocd-notifications-controller-74c7c8f67-fgmxl    1/1     Running   0          76s
argocd-redis-6f88b647dc-lxtm7                      1/1     Running   0          76s
argocd-repo-server-6744fb949d-lk4mz                1/1     Running   0          76s
argocd-server-968c69bfb-wk4v4                      1/1     Running   0          76s
[root@kube-master argocd]# kubectl get svc -n argocd
NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
argocd-applicationset-controller          ClusterIP   10.109.165.84    <none>        7000/TCP,8080/TCP            2m8s
argocd-dex-server                         ClusterIP   10.103.141.180   <none>        5556/TCP,5557/TCP,5558/TCP   2m8s
argocd-metrics                            ClusterIP   10.105.254.1     <none>        8082/TCP                     2m8s
argocd-notifications-controller-metrics   ClusterIP   10.107.18.27     <none>        9001/TCP                     2m8s
argocd-redis                              ClusterIP   10.98.191.182    <none>        6379/TCP                     2m8s
argocd-repo-server                        ClusterIP   10.100.249.132   <none>        8081/TCP,8084/TCP            2m8s
argocd-server                             ClusterIP   10.104.2.242     <none>        80/TCP,443/TCP               2m8s
argocd-server-metrics                     ClusterIP   10.105.7.129     <none>        8083/TCP                     2m8s

```

argocd-ingress.yaml

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"

spec:
  ingressClassName: nginx

  rules:
    - host: argocd.lmgsanm.test.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 80

```



```
wget https://github.com/argoproj/argo-cd/releases/download/v3.3.6/argocd-linux-amd64
mv argocd-linux-amd64 argocd
chmod u+x argocd
cp argocd /usr/local/bin/


[root@kube-master argocd]# argocd version
argocd: v3.3.6+998fb59
  BuildDate: 2026-03-27T14:09:03Z
  GitCommit: 998fb59dc355653c0657908a6ea2f87136e022d1
  GitTreeState: clean
  GoVersion: go1.25.5
  Compiler: gc
  Platform: linux/amd64
{"level":"fatal","msg":"Argo CD server address unspecified","time":"2026-04-11T13:33:25+08:00"}


```



```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

```



```
cat  >> /etc/hosts << EOF
172.23.171.173	argocd.lmgsanm.test.com
EOF
[root@kube-master helm]# kubectl get svc -n argocd
NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
argocd-applicationset-controller          ClusterIP   10.109.165.84    <none>        7000/TCP,8080/TCP            177m
argocd-dex-server                         ClusterIP   10.103.141.180   <none>        5556/TCP,5557/TCP,5558/TCP   177m
argocd-metrics                            ClusterIP   10.105.254.1     <none>        8082/TCP                     177m
argocd-notifications-controller-metrics   ClusterIP   10.107.18.27     <none>        9001/TCP                     177m
argocd-redis                              ClusterIP   10.98.191.182    <none>        6379/TCP                     177m
argocd-repo-server                        ClusterIP   10.100.249.132   <none>        8081/TCP,8084/TCP            177m
argocd-server                             ClusterIP   10.104.2.242     <none>        80/TCP,443/TCP               177m
argocd-server-metrics                     ClusterIP   10.105.7.129     <none>        8083/TCP                     177m
[root@kube-master helm]# argocd login 10.104.2.242:80 --username admin --password gKX00DB6AHMorIjQ
WARNING: server is not configured with TLS. Proceed (y/n)? y
'admin:login' logged in successfully
Context '10.104.2.242:80' updated

[root@kube-master helm]# argocd account update-password --account admin --current-password gKX00DB6AHMorIjQ --new-password lmgSANM@2026
Password updated
Context '10.104.2.242:80' updated

```

