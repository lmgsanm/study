# deploy.yaml部署

以NodePort方式部署ingress-nginx，并使用haproy将NodePort端口转为80或443

## 下载ingress-nginx部署文件

```
mkdir ingress-nginx
cd ingress-nginx/
wget  https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml
```

## 修改ingress-nginx部署文件

```
##修改deploy.yaml文件的发布端口，并配置固定端口号，如下 
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.15.1
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - appProtocol: http
    name: http
    port: 80
    protocol: TCP
    targetPort: http
    nodePort: 30080
  - appProtocol: https
    name: https
    port: 443
    protocol: TCP
    targetPort: https
    nodePort: 30443
  selector:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
  type: NodePort
```

![image-20260419093712218](ingress-nginx%E9%83%A8%E7%BD%B2.assets/image-20260419093712218.png)

## 部署Ingress-nginx

```
kubectl apply -f deploy.yaml
```

> namespace/ingress-nginx created
> serviceaccount/ingress-nginx created
> serviceaccount/ingress-nginx-admission created
> role.rbac.authorization.k8s.io/ingress-nginx created
> role.rbac.authorization.k8s.io/ingress-nginx-admission created
> clusterrole.rbac.authorization.k8s.io/ingress-nginx created
> clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
> rolebinding.rbac.authorization.k8s.io/ingress-nginx created
> rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
> clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
> clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
> configmap/ingress-nginx-controller created
> service/ingress-nginx-controller created
> service/ingress-nginx-controller-admission created
> deployment.apps/ingress-nginx-controller created
> job.batch/ingress-nginx-admission-create created
> job.batch/ingress-nginx-admission-patch created
> ingressclass.networking.k8s.io/nginx created
> validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created

## 查看服务状态

```
 kubectl get pod,svc -n ingress-nginx
```

![image-20260419094137186](ingress-nginx%E9%83%A8%E7%BD%B2.assets/image-20260419094137186.png)

## 部署haproxy

```
yum -y install haproxy
systemctl enable --now haproxy
```

## 配置haproxy

```
cp /etc/haproxy/haproxy.cfg{,.default}
cat > /etc/haproxy/haproxy.cfg << EOF
frontend http
    bind *:80
    default_backend             http
frontend https
    bind *:443
    default_backend             https

backend http
    balance     roundrobin
    server   kube-node01 172.23.171.174:30080 check
    server   kube-node02 172.23.171.173:30080 check
backend https
    balance     roundrobin
    server   kube-node01 172.23.171.174:30443 check
    server   kube-node02 172.23.171.173:30443 check
    
EOF
systemctl restart haproxy
```

## ingress-nginx全局配置

```
kubectl get configmap -n ingress-nginx
kubectl edit configmap ingress-nginx-controller -n ingress-nginx ##编辑，按需添加配置
data:
  # --- 1. 性能与连接优化 ---
  # 开启 Gzip 压缩
  enable-gzip: "true"
  gzip-types: "text/plain text/css application/json application/javascript text/xml application/xml"
  # 保持连接时间
  keep-alive: "75"
  # 最大并发连接数
  worker-connections: "65535"

  # --- 2. 超时与缓冲 ---
  # 全局上传文件大小限制 (解决 413 Request Entity Too Large)，如为空，表示不限制
  proxy-body-size: "500m"
  # 代理读取超时 (解决后端处理慢导致的 504)
  proxy-read-timeout: "60s"
  # 代理发送超时
  proxy-send-timeout: "60s"

  # --- 3. 真实 IP 获取 (关键) ---
  # 如果 Ingress 前面还有 ELB/SLB，必须开启此选项，否则日志里全是 LB 的 IP
  use-forwarded-headers: "true"
  compute-full-forwarded-for: "true"
  use-proxy-protocol: "false" # 如果前端 LB 开启了 Proxy Protocol，这里要改为 true

  # --- 4. 安全配置 ---
  # 隐藏 Nginx 版本号
  server-tokens: "false"
  # SSL 协议版本 (禁用老旧的 TLS 1.0/1.1)
  ssl-protocols: "TLSv1.2 TLSv1.3"
```

![image-20260419095129939](ingress-nginx%E9%83%A8%E7%BD%B2.assets/image-20260419095129939.png)

## ingress-nginx配置模板

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: standard-ingress
  namespace: default
  annotations:
    # --- 基础配置 ---
    # 指定使用的 Ingress Class (K8s 1.18+)
    kubernetes.io/ingress.class: nginx
    
    # --- 高级功能配置 ---
    # 1. 路径重写 (例如将 /api 重写为 /)
    # nginx.ingress.kubernetes.io/rewrite-target: /$2
    
    # 2. 强制 HTTPS 跳转 (默认 301)
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    
    # 3. 后端服务超时设置 (解决 504 Gateway Time-out)
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
    
    # 4. 文件上传大小限制 (默认 1M，这里设为 500M)
    nginx.ingress.kubernetes.io/proxy-body-size: "500m"
    
    # 5. 真实客户端 IP 获取 (如果前面还有负载均衡，需开启)
    nginx.ingress.kubernetes.io/use-forwarded-headers: "true"
spec:
  # 必须指定 ingressClassName，否则可能不生效
  ingressClassName: nginx
  
  # TLS 配置 (HTTPS)
  tls:
    - hosts:
        - example.com
      secretName: example-tls-secret  # 提前创建好的 kubernetes.io/tls 类型 Secret

  # 路由规则
  rules:
    - host: example.com
      http:
        paths:
          # 路径 1: 根路径
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-web-service
                port:
                  number: 80
          
          # 路径 2: API 路径 (如果需要单独路由)
          # - path: /api
          #   pathType: Prefix
          #   backend:
          #     service:
          #       name: my-api-service
          #       port:
          #         number: 8080
```

# helm安装

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress ingress-nginx/ingress-nginx -n ingress --create-namespace	##安装
helm uninstall ingress  -n ingress	##卸载
helm upgrade ingress ingress-nginx/ingress-nginx -n ingress  --install ##升级
helm show values ingress-nginx/ingress-nginx	##查看values配置

##或者将ingress-nginx/ingress-nginx的chart包下载下来再部署
helm pull ingress-nginx/ingress-nginx --untar
cd ingress-nginx
 cp values.yaml{,.defalut}
```

> [root@kube-master ingress-nginx]# helm install ingress ingress-nginx/ingress-nginx -n ingress --create-namespace
> NAME: ingress
> LAST DEPLOYED: Sun Apr 19 15:16:23 2026
> NAMESPACE: ingress
> STATUS: deployed
> REVISION: 1
> TEST SUITE: None
> NOTES:
> The ingress-nginx controller has been installed.
> It may take a few minutes for the load balancer IP to be available.
> You can watch the status by running 'kubectl get service --namespace ingress ingress-ingress-nginx-controller --output wide --watch'
>
> An example Ingress that makes use of the controller:
>   apiVersion: networking.k8s.io/v1
>   kind: Ingress
>   metadata:
>     name: example
>     namespace: foo
>   spec:
>     ingressClassName: nginx
>     rules:
>       - host: www.example.com
>         http:
>           paths:
>             - pathType: Prefix
>               backend:
>                 service:
>                   name: exampleService
>                   port:
>                     number: 80
>               path: /
>     # This section is only required if TLS is to be enabled for the Ingress
>     tls:
>       - hosts:
>         - www.example.com
>         secretName: example-tls
>
> If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:
>
>   apiVersion: v1
>   kind: Secret
>   metadata:
>     name: example-tls
>     namespace: foo
>   data:
>     tls.crt: <base64 encoded cert>
>     tls.key: <base64 encoded key>
>   type: kubernetes.io/tls

```
[root@kube-master ingress-nginx]# kubectl get svc -n ingress
NAME                                         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-ingress-nginx-controller             LoadBalancer   10.106.40.129   <pending>     80:31678/TCP,443:30575/TCP   13m
ingress-ingress-nginx-controller-admission   ClusterIP      10.97.230.142   <none>        443/TCP                      13m


```



```
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443 \
  --set controller.service.type=NodePort
```

```
helm upgrade ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443 \
  --set controller.service.type=NodePort
```

