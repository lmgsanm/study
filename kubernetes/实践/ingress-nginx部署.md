

```
wget  https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml

##修改deploy.yaml文件的发布端口，如下 
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
    nodePort: 30443
    targetPort: https
  selector:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
  type: NodePort

kubectl create -f deploy.yaml

[root@kube-master ingress-nginx]# kubectl get svc -n ingress-nginx
NAME                                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             NodePort    10.111.97.191    <none>        80:30080/TCP,443:30443/TCP   38m
ingress-nginx-controller-admission   ClusterIP   10.108.142.104   <none>        443/TCP                      38m


```

将nodeport端口转发为80和443

```
yum -y install haproxy
systemctl enable --now haproxy
cp /etc/haproxy/haproxy.cfg{,-bk}
#在/etc/haproxy/haproxy.cfg添加如下配置
frontend http
    bind *:80
    default_backend             http
frontend https
    bind *:443
    default_backend             https

backend http
    balance     roundrobin
    server   kube-maser 172.23.171.172:30080 check
    server   kube-node 172.23.171.173:30080 check
backend https
    balance     roundrobin
    server   kube-maser 172.23.171.173:30443 check
    server   kube-node 172.23.171.173:30443 check

```

ingress标准模板

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



### Controller 全局配置模板 (ConfigMap)

kubectl get configmap -n ingress-nginx

kubectl edit configmap ingress-nginx-controller  -n ingress-nginx  ##编辑，按需添加配置

```
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
  # 全局上传文件大小限制 (解决 413 Request Entity Too Large)
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



示例

test-app.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo
  template:
    metadata:
      labels:
        app: demo
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: demo-service
spec:
  selector:
    app: demo
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: demo.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: demo-service
            port:
              number: 80
```



```
[root@kube-master ingress-nginx]# kubectl create -f test-app.yaml
deployment.apps/demo-app created
service/demo-service created
ingress.networking.k8s.io/demo-ingress created
[root@kube-master ingress-nginx]# kubectl get svc
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
demo-service   ClusterIP   10.99.71.100     <none>        80/TCP    78s
kubernetes     ClusterIP   10.96.0.1        <none>        443/TCP   133m
nginx          ClusterIP   10.105.224.127   <none>        80/TCP    113m

```

test-ingress.yaml

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: standard-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"

spec:
  ingressClassName: nginx

    #  tls:
    #    - hosts:
    #        - example.com
    #      secretName: example-tls-secret

  rules:
    - host: lmgsanm.test.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-api-service
                port:
                  number: 80

```



```
[root@kube-master ingress-nginx]# kubectl create -f test-ingress.yaml
ingress.networking.k8s.io/standard-ingress created
[root@kube-master ingress-nginx]# kubectl get ingress
NAME               CLASS   HOSTS              ADDRESS          PORTS   AGE
demo-ingress       nginx   demo.local         172.23.171.173   80      26m
standard-ingress   nginx   lmgsanm.test.com   172.23.171.173   80      9m10s
```

