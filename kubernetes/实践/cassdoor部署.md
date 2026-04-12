

# Casdoor K8s 部署完整思路 + 一键部署步骤

Casdoor 是**国产开源、支持 OAuth2/OIDC/SAML**的统一身份认证平台（可替代 Keycloak，超轻量），非常适合在 K8s 部署。

我给你**最简洁、可直接落地**的部署思路 + 完整 yaml，**不用复杂改造，10 分钟跑起来**。

------

## 一、整体部署思路（极简版）

### 1. 核心架构（2 个组件）

- **casdoor**：主服务（Web UI + API）
- **数据库**：MySQL / PostgreSQL（你可以用现有 K8s 内数据库，或我给你一键部署）

### 2. 存储方案

- 配置数据：存数据库
- 静态资源 / 附件：**可直接用你现有的 MinIO**（完美匹配你现有环境）

### 3. 访问方式

- K8s Service + NodePort / Ingress（我给你两种都配好）

------

## 二、前置条件

- K8s 集群（1 节点以上）
- 可选：你已有的 **MySQL/PostgreSQL**（没有我给你一键起）
- 你已有的 **MinIO**（用于存储）

------

# 三、一键部署（全程复制执行）

## 步骤 1：创建命名空间

bash



运行









```
kubectl create namespace casdoor
```

------

## 步骤 2：部署数据库（如果你已有数据库，跳过这一步）

```
casdoor-db.yaml
```

yaml











```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: casdoor
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "casdoor123"
        - name: MYSQL_DATABASE
          value: "casdoor"
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
      volumes:
      - name: data
        emptyDir: {}  # 正式环境替换成 PVC
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: casdoor
spec:
  ports:
  - port: 3306
  selector:
    app: mysql
```

应用：

bash



运行









```
kubectl apply -f casdoor-db.yaml
```

------

## 步骤 3：部署 Casdoor 主服务（关键）

```
casdoor.yaml
```

yaml











```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: casdoor
  namespace: casdoor
spec:
  replicas: 1
  selector:
    matchLabels:
      app: casdoor
  template:
    metadata:
      labels:
        app: casdoor
    spec:
      containers:
      - name: casdoor
        image: casbin/casdoor:latest
        ports:
        - containerPort: 8000
        env:
        # 数据库配置
        - name: DRIVER_NAME
          value: "mysql"
        - name: DATA_SOURCE_NAME
          value: "root:casdoor123@tcp(mysql:3306)/casdoor"
        
        # 你的 MinIO 存储（必须改成你自己的）
        - name: MINIO_SERVER
          value: "minio.minio.svc:9000"
        - name: MINIO_ACCESS_KEY
          value: "你的MINIO_ACCESS_KEY"
        - name: MINIO_SECRET_KEY
          value: "你的MINIO_SECRET_KEY"
        - name: MINIO_SSL
          value: "false"
        - name: MINIO_BUCKET
          value: "casdoor"

---
# Service（提供访问）
apiVersion: v1
kind: Service
metadata:
  name: casdoor
  namespace: casdoor
spec:
  type: NodePort
  ports:
  - port: 8000
    nodePort: 30000  # 固定端口，方便访问
  selector:
    app: casdoor
```

**请把 MINIO 那 4 个配置改成你自己的！**

应用：

bash



运行









```
kubectl apply -f casdoor.yaml
```

------

## 步骤 4：检查是否运行成功

bash



运行









```
kubectl get pods -n casdoor
```

出现 2 个 running 就成功：

- casdoor-xxxx
- mysql-xxxx

------

# 四、访问 Casdoor Web UI

## 方式 1：NodePort 直接访问（最简单）

浏览器打开：

plaintext











```
http://你的集群IP:30000
```

## 方式 2：端口转发（测试用）

bash



运行









```
kubectl port-forward -n casdoor svc/casdoor 8000:8000
```

访问：

plaintext











```
http://localhost:8000
```

### 默认管理员账号（首次登录）

- 用户名：`admin`
- 密码：`123456`

**登录后第一时间修改密码！**

------

# 五、你可以用 Casdoor 做什么

✅ 统一用户登录（账号密码、短信、邮件）

✅ 第三方登录（微信、QQ、GitHub、Gitee）

✅ OAuth2 / OIDC 对接（你的应用一键接入登录）

✅ SSO 单点登录

✅ 对接 K8s Dashboard、Grafana、Harbor 等

------

# 六、进阶（可选）

## 1. 用 Ingress 域名访问

给你一个简单 Ingress 配置：

yaml











```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: casdoor
  namespace: casdoor
spec:
  rules:
  - host: casdoor.你的域名.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: casdoor
            port:
              number: 8000
```

## 2. 持久化数据库

把 MySQL 的 `emptyDir` 换成 PVC 即可。

------

# 七、总结（超清晰）

你只需要做 4 件事：

1. 创建命名空间
2. 部署 MySQL（已有则跳过）
3. 填写 MinIO 信息，部署 Casdoor
4. 访问 Web UI，开始使用