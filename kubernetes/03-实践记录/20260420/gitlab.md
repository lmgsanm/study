# 1

在 Kubernetes (K8s) 中部署 GitLab 并将数据持久化到 Ceph 存储，需要完成三个核心步骤：准备 Ceph 存储、部署 GitLab、配置访问。以下是详细的步骤和说明。

### 🗄️ 第一步：准备 Ceph 存储

我们将使用 Rook 来管理 Ceph 集群，并为 GitLab 创建专用的存储资源。

#### 1. 创建 Ceph 存储池 (CephBlockPool)

首先，需要定义一个 Ceph 块存储池，用于存放 GitLab 的数据。

创建 `gitlab-ceph-pool.yaml` 文件：

yaml



```
1apiVersion: ceph.rook.io/v1
2kind: CephBlockPool
3metadata:
4  name: gitlab-pool
5  namespace: rook-ceph
6spec:
7  failureDomain: host
8  replicated:
9    size: 3 # 生产环境建议使用3副本以保证高可用
```

应用配置：

bash



```
1kubectl apply -f gitlab-ceph-pool.yaml
```

#### 2. 创建 StorageClass

StorageClass 允许 Kubernetes 动态地为 GitLab 创建持久卷 (PersistentVolume)。

创建 `gitlab-storageclass.yaml` 文件：

yaml



```
1apiVersion: storage.k8s.io/v1
2kind: StorageClass
3metadata:
4  name: gitlab-ceph-sc
5provisioner: rook-ceph.rbd.csi.ceph.com
6parameters:
7  clusterID: rook-ceph # Rook 部署的命名空间
8  pool: gitlab-pool    # 上面创建的 CephBlockPool 名称
9  imageFormat: "2"
10  imageFeatures: layering
11  csi.storage.k8s.io/provisioner-secret-name: rook-ceph-csi
12  csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
13  csi.storage.k8s.io/controller-expand-secret-name: rook-ceph-csi
14  csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
15  csi.storage.k8s.io/node-stage-secret-name: rook-ceph-csi
16  csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
17reclaimPolicy: Retain # 生产环境建议使用 Retain，防止 PVC 删除时数据丢失
18allowVolumeExpansion: true # 允许在线扩容
```

应用配置：

bash



```
1kubectl apply -f gitlab-storageclass.yaml
```

### 🚀 第二步：部署 GitLab

推荐使用官方的 GitLab Helm Chart 进行部署，这是最简便且易于维护的方式。

#### 1. 准备工作

bash



```
1# 添加 GitLab Helm 仓库
2helm repo add gitlab https://charts.gitlab.io/
3# 更新仓库信息
4helm repo update
5# 为 GitLab 创建独立的命名空间
6kubectl create namespace gitlab
```

#### 2. 自定义配置 values.yaml

为了使用我们创建的 Ceph StorageClass，需要自定义 Helm 的值文件。

创建 `gitlab-values.yaml` 文件：

yaml



```
1global:
2  hosts:
3    domain: example.com # 替换为你的域名
4  ingress:
5    configureCertmanager: false # 我们稍后手动配置 Ingress 和 TLS
6    class: nginx # 指定 Ingress Class
7
8# 配置 GitLab 各组件的持久化存储
9gitlab:
10  gitaly:
11    persistence:
12      enabled: true
13      size: 50Gi
14      storageClass: gitlab-ceph-sc # 使用 Ceph 存储
15
16gitlab-runner:
17  persistence:
18    enabled: true
19    size: 10Gi
20    storageClass: gitlab-ceph-sc
21
22# 配置各组件的存储类
23registry:
24  persistence:
25    enabled: true
26    size: 10Gi
27    storageClass: gitlab-ceph-sc
28
29gitlab-webservice:
30  persistence:
31    enabled: true
32    size: 10Gi
33    storageClass: gitlab-ceph-sc
34
35gitlab-sidekiq:
36  persistence:
37    enabled: true
38    size: 10Gi
39    storageClass: gitlab-ceph-sc
```

#### 3. 使用 Helm 安装 GitLab

bash



```
1helm install gitlab gitlab/gitlab \
2  --namespace gitlab \
3  -f gitlab-values.yaml \
4  --timeout 600s
```

等待所有 Pod 状态变为 `Running`。首次启动可能需要几分钟。

### 🔑 第三步：配置访问

#### 1. 获取初始 Root 密码

GitLab 安装完成后，获取初始管理员密码：

bash



```
1kubectl get secret --namespace gitlab gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode
```

用户名是 `root`。

#### 2. 配置 Ingress 和 HTTPS

为了通过 HTTPS 访问 GitLab，需要配置 Ingress 和 TLS 证书。

首先，创建一个 TLS Secret（请替换为你自己的证书和密钥）：

bash



```
1kubectl create secret tls gitlab-tls-secret \
2  --cert=path/to/tls.crt \
3  --key=path/to/tls.key \
4  -n gitlab
```

然后，更新或创建一个 Ingress 资源来启用 HTTPS。你可以直接修改 Helm 的 `values.yaml` 并升级，或者手动创建一个 Ingress。

这里展示手动创建 Ingress 的方法，创建 `gitlab-ingress.yaml`：

yaml



```
1apiVersion: networking.k8s.io/v1
2kind: Ingress
3metadata:
4  name: gitlab-ingress
5  namespace: gitlab
6  annotations:
7    nginx.ingress.kubernetes.io/proxy-body-size: "0" # GitLab 需要上传大文件
8    nginx.ingress.kubernetes.io/ssl-redirect: "true"
9spec:
10  ingressClassName: nginx
11  tls:
12  - hosts:
13    - gitlab.example.com # 你的 GitLab 域名
14    secretName: gitlab-tls-secret
15  rules:
16  - host: gitlab.example.com
17    http:
18      paths:
19      - path: /
20        pathType: Prefix
21        backend:
22          service:
23            name: gitlab-webservice
24            port:
25              number: 8181
```

应用配置：

bash



```
1kubectl apply -f gitlab-ingress.yaml
```

现在，你就可以通过 `https://gitlab.example.com` 访问你的 GitLab 实例了。



# 2



针对你描述的场景——Ingress-Nginx 所在的节点（或负载均衡器）同时拥有**内网 IP** 和 **公网 IP**，在 K8s 上部署 GitLab 时，核心策略是利用 **Ingress Class** 和 **Service 注解** 来精确控制流量入口。

以下是具体的配置步骤和访问方案：

### 1. 核心思路

- **流量入口控制**：我们需要配置 Ingress-Nginx 的 `Service`，使其明确绑定到指定的 IP（公网或内网），或者通过云厂商的负载均衡器（CLB/ALB）注解来指定使用哪个 IP。
- **GitLab 配置**：在 Helm 部署 GitLab 时，指定 `ingressClassName`，并配置正确的 `external_url`。

------

### 2. 配置 Ingress-Nginx (关键步骤)

Ingress-Nginx 通常以 `LoadBalancer` 类型的 Service 运行。你需要决定 GitLab 的流量是走公网 IP 还是内网 IP。

#### 场景 A：希望从公网访问 GitLab (推荐)

如果你希望 `gitlab.example.com` 解析到**公网 IP**，你需要确保 Ingress-Nginx 的 Service 暴露的是公网 IP。

如果你使用的是云厂商（如阿里云、腾讯云、AWS），通常通过注解来控制：

**修改 `ingress-nginx` 的 Service (通常在 `ingress-nginx` 命名空间下):**

yaml



```
1apiVersion: v1
2kind: Service
3metadata:
4  name: ingress-nginx-controller
5  namespace: ingress-nginx
6  annotations:
7    # 以阿里云为例，指定负载均衡类型为公网
8    service.beta.kubernetes.io/alibaba-cloud-loadbalancer-address-type: "internet"
9    # 如果是腾讯云，指定公网 IP
10    # service.beta.kubernetes.io/qcloud-loadbalancer-internal-subnetid: "" 
11spec:
12  type: LoadBalancer
13  # ... 其他配置
```

*应用更改后，`kubectl get svc -n ingress-nginx` 显示的 `EXTERNAL-IP` 应该是你的**公网 IP**。*

#### 场景 B：希望仅内网访问，或通过特定 IP 访问

如果你希望 GitLab 绑定到**内网 IP**（例如为了安全，只允许内网访问，或者通过内网 IP 做反向代理），则配置私网注解：

yaml



```
1apiVersion: v1
2kind: Service
3metadata:
4  name: ingress-nginx-controller
5  namespace: ingress-nginx
6  annotations:
7    # 以阿里云为例，指定为内网
8    service.beta.kubernetes.io/alibaba-cloud-loadbalancer-address-type: "intranet"
9spec:
10  type: LoadBalancer
```

*此时，`EXTERNAL-IP` 将显示为你的**内网 IP**。*

------

### 3. 部署 GitLab (Helm 配置)

在部署 GitLab 时，我们需要告诉 Helm 使用上面配置好的 Ingress-Nginx，并设置正确的域名。

修改你的 `gitlab-values.yaml`：

yaml



```
1global:
2  # 1. 设置访问域名 (必须解析到 Ingress-Nginx 的 IP)
3  hosts:
4    domain: gitlab.example.com 
5    https: true # 建议开启 HTTPS
6
7  # 2. 指定 Ingress Class
8  ingress:
9    class: nginx
10    # 如果是云厂商，可能需要指定特定的 annotations 来关联负载均衡器
11    annotations:
12      nginx.ingress.kubernetes.io/proxy-body-size: "0"
13      nginx.ingress.kubernetes.io/ssl-redirect: "true"
14
15# 关闭自动证书管理 (除非你配置了 cert-manager)，手动配置 TLS Secret
16certmanager:
17  install: false
18
19# 配置 Ingress 资源
20ingress:
21  enabled: true
22  class: nginx
23  # 配置 TLS
24  tls:
25    enabled: true
26    secretName: gitlab-tls-secret # 提前创建好的 TLS Secret
```

**部署命令：**

bash



```
1helm install gitlab gitlab/gitlab -f gitlab-values.yaml -n gitlab
```

------

### 4. 从本机如何访问 GitLab

根据你选择的网络模式，访问方式如下：

#### 方式一：通过公网域名访问 (最常用)

如果你的 Ingress-Nginx 暴露的是**公网 IP**，且你有域名。

1. 配置 DNS

   ：

   在你的 DNS 服务商（阿里云解析、Cloudflare 等）处添加一条 

   A 记录

   ：

   - 主机记录: `gitlab` (即 `gitlab.example.com`)
   - 记录值: **Ingress-Nginx 的公网 IP**

2. **访问**：
   在浏览器输入 `https://gitlab.example.com`。

#### 方式二：通过内网 IP 直接访问 (无域名/测试用)

如果你的 Ingress-Nginx 暴露的是**内网 IP**，或者你想绕过 DNS 直接测试。

1. **修改本机 Hosts 文件**：
   你需要欺骗本机，让域名指向 K8s 集群的内网入口 IP。

   - **Linux/Mac**: `sudo vim /etc/hosts`
   - **Windows**: `C:\Windows\System32\drivers\etc\hosts`

   添加内容：

   text

   

   ```
   1<你的 Ingress-Nginx 内网 IP>  gitlab.example.com
   ```

2. **访问**：
   确保你的电脑能和 K8s 节点的内网 IP 通信（例如你在公司内网，或通过 VPN 连接），然后访问 `https://gitlab.example.com`。

#### 方式三：端口转发 (仅限临时调试)

如果你不想配置网络，只想临时进去看一眼：

bash



```
1kubectl port-forward svc/gitlab-webservice -n gitlab 8080:8181
```

然后访问 `http://localhost:8080`。
*注意：这种方式不支持 Git SSH 克隆，仅用于 Web 界面调试。*

### 总结建议

1. **生产环境**：建议 Ingress-Nginx 使用**公网 IP**（通过云厂商 LB 暴露），配置域名解析 `gitlab.example.com` -> `公网 IP`。
2. **安全性**：在 GitLab 的 `values.yaml` 中开启 `https: true`，并配置好 TLS Secret，防止密码和代码传输被劫持。
3. **SSH 访问**：如果你需要通过 `git clone git@gitlab.example.com:...` 进行代码克隆，还需要在 Ingress-Nginx 中配置 **TCP 代理**（将节点的 22 端口转发到 GitLab Shell 服务），这通常需要修改 Ingress-Nginx 的 ConfigMap。

# 3

在 AWS 或 Google Cloud (GCP/GKE) 环境下，服务器（节点）同时拥有内网和公网 IP 是标准配置。但 Kubernetes 的 Ingress-Nginx 通常不会直接使用节点的 IP，而是通过云厂商的 **负载均衡器 (Load Balancer)** 来暴露服务。

针对你的需求，核心在于**控制 Ingress-Nginx 的 Service 类型**，使其申请一个**公网负载均衡器**，从而获得一个公网入口。

以下是详细的配置步骤和访问方案：

### 🌐 第一步：配置 Ingress-Nginx (暴露公网入口)

在 AWS 和 GKE 上，Ingress-Nginx 默认通常是通过 `LoadBalancer` 类型的 Service 暴露的。我们需要确保它申请的是**公网**负载均衡器。

#### 1. 修改 Ingress-Nginx Service

你需要编辑或修改部署 Ingress-Nginx 的 Service YAML 文件（通常在 `ingress-nginx` 命名空间下）。

**通用配置 (适用于 AWS 和 GKE):**

yaml



```
1apiVersion: v1
2kind: Service
3metadata:
4  name: ingress-nginx-controller
5  namespace: ingress-nginx
6  annotations:
7    # --- AWS 特定配置 ---
8    # 确保创建的是公网 CLB/NLB (默认为 internet-facing)
9    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
10    # 如果需要指定 IP，可以使用此注解 (需先创建好 EIP)
11    # service.beta.kubernetes.io/aws-load-balancer-eip-allocations: "eipalloc-xxxx,..."
12
13    # --- GKE 特定配置 ---
14    # GKE 默认创建公网负载均衡器，无需特殊注解
15    # 如果想指定静态 IP，需先创建 Global Static IP 并在此指定
16    # kubernetes.io/ingress.global-static-ip-name: "your-static-ip-name"
17spec:
18  type: LoadBalancer
19  selector:
20    app.kubernetes.io/component: controller
21  ports:
22    - name: http
23      port: 80
24      targetPort: http
25    - name: https
26      port: 443
27      targetPort: https
```

**操作后检查：**
执行 `kubectl get svc -n ingress-nginx`。
查看 `EXTERNAL-IP` 列：

- **AWS**: 会显示一个负载均衡器的 DNS 名称（如 `...elb.amazonaws.com`）。
- **GKE**: 会显示一个外部 IP 地址。

> **关键点**：这个 `EXTERNAL-IP` (或 DNS) 就是你的 GitLab **公网入口**。

------

### 🚀 第二步：部署 GitLab (配置 Ingress)

在部署 GitLab 的 Helm Chart (`values.yaml`) 时，你需要将域名指向刚才获取的公网入口。

**`gitlab-values.yaml` 配置示例：**

yaml



```
1global:
2  # 1. 设置你的 GitLab 访问域名
3  hosts:
4    domain: gitlab.example.com
5    https: true
6
7  # 2. 指定 Ingress Class
8  ingress:
9    class: nginx
10    configureCertmanager: false # 建议手动管理证书或使用 Cloudflare
11
12# 配置 Ingress 资源
13ingress:
14  enabled: true
15  class: nginx
16  annotations:
17    nginx.ingress.kubernetes.io/proxy-body-size: "0"
18    nginx.ingress.kubernetes.io/ssl-redirect: "true"
19  tls:
20    enabled: true
21    secretName: gitlab-tls-secret # 提前创建好 TLS Secret
```

------

### 💻 第三步：从本机访问 GitLab

根据你的网络环境和需求，有三种访问方式：

#### 方式 1：通过公网域名访问 (生产环境标准做法)

这是最推荐的方式，适用于所有场景。

1. 获取入口 IP/DNS

   ：

   - **GKE**: 获取 Ingress-Nginx Service 的 `EXTERNAL-IP`。
   - **AWS**: 获取 Ingress-Nginx Service 的 `EXTERNAL-IP` (DNS 名称)，或者去 EC2 控制台查看对应的 ELB 的公网 IP。

2. 配置 DNS

   ：

   在你的域名服务商（如阿里云、GoDaddy、Route53）处添加一条 

   A 记录

   ：

   - 主机记录: `gitlab` (对应 `gitlab.example.com`)
   - 记录值: **GKE 的外部 IP** (如果是 AWS 且使用 DNS 入口，则使用 CNAME 记录指向 ELB DNS)。

3. **访问**：
   在浏览器输入 `https://gitlab.example.com`。

#### 方式 2：通过本机 Hosts 映射 (开发/测试用)

如果你还没有配置域名，或者想直接通过 IP 测试。

1. **获取公网 IP**：确保你使用的是 Ingress-Nginx 的**公网 IP**（不是节点的内网 IP）。

2. **修改本机 Hosts 文件**：

   - **Windows**: `C:\Windows\System32\drivers\etc\hosts`
   - **Mac/Linux**: `/etc/hosts`

   添加一行：

   text

   

   ```
   1<Ingress-Nginx 的公网 IP>  gitlab.example.com
   ```

3. **访问**：
   浏览器访问 `https://gitlab.example.com`。
   *注意：如果是自签名证书，浏览器会报不安全，需点击“高级”->“继续访问”。*

#### 方式 3：SSH 协议访问 (Git Clone/Push)

GitLab 的 HTTP 走 Ingress (80/443 端口)，但 **Git SSH** 通常走 22 端口。Ingress-Nginx 默认只处理 HTTP/HTTPS。

如果你需要用 `git clone git@gitlab.example.com:group/project.git`，你需要配置 **TCP 代理**。

**修改 Ingress-Nginx ConfigMap (`kubectl edit cm ingress-nginx-controller -n ingress-nginx`):**

yaml



```
1data:
2  # 将 Ingress-Nginx 的 22 端口流量转发到 GitLab Shell 服务
3  # 格式: "端口": "命名空间/服务名:服务端口"
4  "22": "gitlab/gitlab-gitlab-shell:22"
```

**修改 Ingress-Nginx Service:**
确保 Service 也监听了 22 端口：

yaml



```
1spec:
2  ports:
3    - name: ssh
4      port: 22
5      targetPort: 22
6      protocol: TCP
```

配置完成后，你就可以通过公网 IP (或绑定的域名) 的 22 端口进行 SSH 克隆了。

### 📌 总结

表格



| 步骤            | AWS 操作                                                     | GKE 操作                                         |
| :-------------- | :----------------------------------------------------------- | :----------------------------------------------- |
| **1. 暴露服务** | 配置 Service 注解 `aws-load-balancer-scheme: internet-facing` | 配置 Service `type: LoadBalancer` (默认即为公网) |
| **2. 获取地址** | 获取 ELB 的 DNS 或公网 IP                                    | 获取 Service 的 `EXTERNAL-IP`                    |
| **3. 域名解析** | Route53 添加 A 记录/CNAME                                    | Cloud DNS 添加 A 记录                            |
| **4. 本机访问** | 浏览器访问域名                                               | 浏览器访问域名                                   |

**推荐方案**：在云厂商控制台为负载均衡器绑定一个**弹性 IP (EIP/Static IP)**，然后将域名解析到这个固定 IP，这样即使重启集群，GitLab 的访问地址也不会变。