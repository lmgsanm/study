# 1

在 Kubernetes (K8s) 中部署 Jenkins，使用 Ceph 作为持久化存储，并设计一条自动化流水线来部署包含前端和后端的 Go 项目，这是一个非常经典且实用的 CI/CD 场景。

整个方案可以分为三个主要部分：

1. **在 K8s 中部署 Jenkins**：配置好使用 Ceph 的持久化存储。
2. **准备 Go 项目**：确保前后端项目有合适的 `Dockerfile` 和 K8s 部署配置文件。
3. **设计 Jenkins 流水线**：编写 `Jenkinsfile` 来自动化整个构建、测试、打包和部署流程。

### 🗄️ 第一部分：在 K8s 中部署 Jenkins (使用 Ceph 存储)

为了在生产环境中稳定运行，Jenkins 需要持久化存储来保存其配置、插件、构建历史和凭据。我们将使用 Ceph RBD 作为后端存储，并通过 Kubernetes 的 StorageClass 动态创建 PersistentVolumeClaim (PVC)。

#### 1. 创建 Jenkins 命名空间

首先，为 Jenkins 创建一个独立的命名空间，以便更好地管理资源。

bash



```
1kubectl create namespace jenkins
```

#### 2. 配置 Ceph StorageClass (如果尚未配置)

确保你的 K8s 集群已经配置了 Ceph CSI 驱动。然后，创建一个 `StorageClass`，用于动态供给 Jenkins 所需的存储。

`jenkins-sc.yaml`:

yaml



```
1apiVersion: storage.k8s.io/v1
2kind: StorageClass
3metadata:
4  name: jenkins-sc
5provisioner: rbd.csi.ceph.com # 根据你的 Ceph CSI 驱动调整
6parameters:
7  clusterID: <your-ceph-cluster-id>
8  pool: <your-rbd-pool-name>
9  imageFeatures: layering
10  csi.storage.k8s.io/provisioner-secret-name: csi-rbd-secret
11  csi.storage.k8s.io/provisioner-secret-namespace: <ceph-csi-namespace>
12  csi.storage.k8s.io/controller-expand-secret-name: csi-rbd-secret
13  csi.storage.k8s.io/controller-expand-secret-namespace: <ceph-csi-namespace>
14  csi.storage.k8s.io/node-stage-secret-name: csi-rbd-secret
15  csi.storage.k8s.io/node-stage-secret-namespace: <ceph-csi-namespace>
16reclaimPolicy: Retain # 生产环境建议使用 Retain，防止误删
17allowVolumeExpansion: true
```

应用配置：`kubectl apply -f jenkins-sc.yaml`

#### 3. 创建 Jenkins RBAC 权限

Jenkins 需要权限来与 K8s API 交互，例如创建 Pod 来执行流水线任务。

`jenkins-rbac.yaml`:

yaml



```
1---
2apiVersion: v1
3kind: ServiceAccount
4metadata:
5  name: jenkins
6  namespace: jenkins
7---
8apiVersion: rbac.authorization.k8s.io/v1
9kind: ClusterRole
10metadata:
11  name: jenkins
12rules:
13- apiGroups: [""]
14  resources: ["pods", "pods/exec", "pods/log", "persistentvolumeclaims", "events"]
15  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
16- apiGroups: ["apps"]
17  resources: ["deployments", "daemonsets", "replicasets", "statefulsets"]
18  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
19---
20apiVersion: rbac.authorization.k8s.io/v1
21kind: ClusterRoleBinding
22metadata:
23  name: jenkins
24roleRef:
25  apiGroup: rbac.authorization.k8s.io
26  kind: ClusterRole
27  name: jenkins
28subjects:
29- kind: ServiceAccount
30  name: jenkins
31  namespace: jenkins
```

应用配置：`kubectl apply -f jenkins-rbac.yaml`

#### 4. 部署 Jenkins

创建一个 `StatefulSet` 来部署 Jenkins，并挂载由 Ceph 提供的 PVC。使用 `StatefulSet` 可以获得稳定的网络标识和存储。

`jenkins-statefulset.yaml`:

yaml



```
1apiVersion: apps/v1
2kind: StatefulSet
3metadata:
4  name: jenkins
5  namespace: jenkins
6spec:
7  serviceName: jenkins
8  replicas: 1
9  selector:
10    matchLabels:
11      app: jenkins
12  template:
13    metadata:
14      labels:
15        app: jenkins
16    spec:
17      serviceAccountName: jenkins
18      securityContext:
19        fsGroup: 1000 # Jenkins 容器内用户的组ID
20      containers:
21      - name: jenkins
22        image: jenkins/jenkins:2.426.1-lts-jdk17 # 使用LTS版本
23        ports:
24        - containerPort: 8080
25          name: http
26        - containerPort: 50000
27          name: agent
28        resources:
29          requests:
30            cpu: "1"
31            memory: "2Gi"
32          limits:
33            cpu: "2"
34            memory: "4Gi"
35        livenessProbe:
36          httpGet:
37            path: /login
38            port: 8080
39          initialDelaySeconds: 120
40          periodSeconds: 10
41        readinessProbe:
42          httpGet:
43            path: /login
44            port: 8080
45          initialDelaySeconds: 60
46          periodSeconds: 10
47        volumeMounts:
48        - name: jenkins-home
49          mountPath: /var/jenkins_home
50  volumeClaimTemplates:
51  - metadata:
52      name: jenkins-home
53    spec:
54      accessModes: ["ReadWriteOnce"]
55      storageClassName: jenkins-sc # 引用上面创建的 StorageClass
56      resources:
57        requests:
58          storage: 50Gi # 根据需要调整存储大小
```

应用配置：`kubectl apply -f jenkins-statefulset.yaml`

#### 5. 暴露 Jenkins 服务

通过 `Service` 和 `Ingress` 来访问 Jenkins 的 Web 界面。

`jenkins-service.yaml`:

yaml



```
1apiVersion: v1
2kind: Service
3metadata:
4  name: jenkins-service
5  namespace: jenkins
6spec:
7  selector:
8    app: jenkins
9  ports:
10  - name: http
11    port: 80
12    targetPort: 8080
13  - name: agent
14    port: 50000
15    targetPort: 50000
16  type: ClusterIP
```

`jenkins-ingress.yaml` (以 Nginx Ingress 为例):

yaml



```
1apiVersion: networking.k8s.io/v1
2kind: Ingress
3metadata:
4  name: jenkins-ingress
5  namespace: jenkins
6  annotations:
7    nginx.ingress.kubernetes.io/proxy-body-size: "50m" # 允许上传较大的构建产物
8spec:
9  rules:
10  - host: jenkins.yourdomain.com # 替换为你的域名
11    http:
12      paths:
13      - path: /
14        pathType: Prefix
15        backend:
16          service:
17            name: jenkins-service
18            port:
19              name: http
```

应用配置：`kubectl apply -f jenkins-service.yaml` 和 `kubectl apply -f jenkins-ingress.yaml`

完成部署后，你可以通过 `http://jenkins.yourdomain.com` 访问 Jenkins，并根据控制台日志获取初始管理员密码进行初始化设置。

------

### 📦 第二部分：准备 Go 项目

假设你的项目结构如下：

文本



```
1my-go-project/
2├── backend/
3│   ├── main.go
4│   ├── go.mod
5│   └── Dockerfile
6├── frontend/
7│   ├── main.go (或其他前端框架，如React/Vue的构建产物)
8│   ├── go.mod
9│   └── Dockerfile
10└── k8s/
11    ├── backend-deployment.yaml
12    ├── backend-service.yaml
13    ├── frontend-deployment.yaml
14    └── frontend-service.yaml
```

#### 1. 编写 Dockerfile

为前后端分别编写 `Dockerfile`，以实现多阶段构建，减小最终镜像体积。

`backend/Dockerfile`:

dockerfile



```
1# 构建阶段
2FROM golang:1.21-alpine AS builder
3WORKDIR /app
4COPY go.mod go.sum ./
5RUN go mod download
6COPY . .
7# 编译为 Linux 可执行文件
8RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o backend .
9
10# 运行阶段
11FROM alpine:latest
12RUN apk --no-cache add ca-certificates
13WORKDIR /root/
14# 从构建阶段复制可执行文件
15COPY --from=builder /app/backend .
16EXPOSE 8080
17CMD ["./backend"]
```

`frontend/Dockerfile` (如果前端也是 Go 服务):

dockerfile



```
1# 构建阶段
2FROM golang:1.21-alpine AS builder
3WORKDIR /app
4COPY go.mod go.sum ./
5RUN go mod download
6COPY . .
7RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o frontend .
8
9# 运行阶段
10FROM nginx:alpine
11# 如果你的前端是静态文件，可以这样配置
12# COPY --from=builder /app/dist /usr/share/nginx/html
13# 如果是Go服务，则类似后端
14COPY --from=builder /app/frontend .
15EXPOSE 80
16# CMD ["./frontend"]
```

#### 2. 编写 K8s 部署文件

为前后端服务编写 Deployment 和 Service 配置文件。

`k8s/backend-deployment.yaml`:

yaml



```
1apiVersion: apps/v1
2kind: Deployment
3metadata:
4  name: myapp-backend
5  namespace: default # 部署到默认命名空间，可按需修改
6spec:
7  replicas: 2
8  selector:
9    matchLabels:
10      app: myapp-backend
11  template:
12    metadata:
13      labels:
14        app: myapp-backend
15    spec:
16      containers:
17      - name: backend
18        image: your-docker-registry.com/your-namespace/myapp-backend:latest # 镜像名，由流水线更新
19        ports:
20        - containerPort: 8080
21        resources:
22          requests:
23            memory: "128Mi"
24            cpu: "100m"
25          limits:
26            memory: "256Mi"
27            cpu: "500m"
28        livenessProbe:
29          httpGet:
30            path: /health
31            port: 8080
32          initialDelaySeconds: 30
33          periodSeconds: 10
34        readinessProbe:
35          httpGet:
36            path: /ready
37            port: 8080
38          initialDelaySeconds: 5
39          periodSeconds: 5
```

`k8s/frontend-deployment.yaml` (结构类似，只需修改名称和端口)

`k8s/backend-service.yaml`:

yaml



```
1apiVersion: v1
2kind: Service
3metadata:
4  name: myapp-backend-service
5  namespace: default
6spec:
7  selector:
8    app: myapp-backend
9  ports:
10    - protocol: TCP
11      port: 80
12      targetPort: 8080
13  type: ClusterIP
```

`k8s/frontend-service.yaml` (结构类似，可考虑使用 `LoadBalancer` 或 `Ingress` 暴露外部访问)

------

### 🚀 第三部分：设计 Jenkins 流水线

将 `Jenkinsfile` 放在项目根目录，Jenkins 会自动识别并执行。

#### 1. 配置 Jenkins 凭据

在 Jenkins 的 "系统" -> "凭据" 中，添加以下凭据：

- **Docker Registry 凭据**: 用户名和密码，ID 设为 `docker-registry-cred`。
- **Kubeconfig 凭据**: 一个可以访问目标 K8s 集群的 `kubeconfig` 文件，ID 设为 `k8s-kubeconfig`。

#### 2. 编写 Jenkinsfile

这个 `Jenkinsfile` 会并行构建前后端，然后依次部署。

`Jenkinsfile`:

groovy



```
1pipeline {
2    agent any
3
4    environment {
5        // 定义环境变量
6        DOCKER_REGISTRY = 'your-docker-registry.com/your-namespace'
7        BACKEND_IMAGE = "${DOCKER_REGISTRY}/myapp-backend"
8        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/myapp-frontend"
9        // 使用 Git commit hash 作为镜像标签，保证唯一性
10        GIT_COMMIT_HASH = "${sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()}"
11        IMAGE_TAG = "${GIT_COMMIT_HASH}"
12        KUBECONFIG_CREDENTIALS_ID = 'k8s-kubeconfig'
13        DOCKER_CREDENTIALS_ID = 'docker-registry-cred'
14    }
15
16    stages {
17        stage('Checkout') {
18            steps {
19                // 从 Git 仓库拉取代码
20                checkout scm
21            }
22        }
23
24        stage('Build & Push Images') {
25            parallel {
26                stage('Build & Push Backend') {
27                    steps {
28                        script {
29                            // 构建并推送后端镜像
30                            withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
31                                sh """
32                                    docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD} ${DOCKER_REGISTRY}
33                                    docker build -t ${BACKEND_IMAGE}:${IMAGE_TAG} ./backend
34                                    docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
35                                """
36                            }
37                        }
38                    }
39                }
40                stage('Build & Push Frontend') {
41                    steps {
42                        script {
43                            // 构建并推送前端镜像
44                            withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
45                                sh """
46                                    docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD} ${DOCKER_REGISTRY}
47                                    docker build -t ${FRONTEND_IMAGE}:${IMAGE_TAG} ./frontend
48                                    docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}
49                                """
50                            }
51                        }
52                    }
53                }
54            }
55        }
56
57        stage('Deploy to Kubernetes') {
58            steps {
59                script {
60                    // 使用 Kubeconfig 凭据部署到 K8s
61                    withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS_ID}", variable: 'KUBECONFIG')]) {
62                        sh """
63                            # 替换 Deployment 中的镜像标签
64                            export IMAGE_TAG=${IMAGE_TAG}
65                            export DOCKER_REGISTRY=${DOCKER_REGISTRY}
66                            
67                            # 使用 envsubst 替换环境变量并应用配置
68                            envsubst < k8s/backend-deployment.yaml | kubectl --kubeconfig=\$KUBECONFIG apply -f -
69                            kubectl --kubeconfig=\$KUBECONFIG apply -f k8s/backend-service.yaml
70                            
71                            envsubst < k8s/frontend-deployment.yaml | kubectl --kubeconfig=\$KUBECONFIG apply -f -
72                            kubectl --kubeconfig=\$KUBECONFIG apply -f k8s/frontend-service.yaml
73
74                            # 等待部署完成
75                            kubectl --kubeconfig=\$KUBECONFIG rollout status deployment/myapp-backend
76                            kubectl --kubeconfig=\$KUBECONFIG rollout status deployment/myapp-frontend
77                        """
78                    }
79                }
80            }
81        }
82    }
83
84    post {
85        always {
86            // 无论成功或失败，都清理工作区
87            cleanWs()
88        }
89        success {
90            echo "🎉 部署成功！后端镜像: ${BACKEND_IMAGE}:${IMAGE_TAG}, 前端镜像: ${FRONTEND_IMAGE}:${IMAGE_TAG}"
91        }
92        failure {
93            echo "❌ 部署失败，请检查构建日志。"
94            // 可以在这里添加通知逻辑，如发送邮件或 Slack 消息
95        }
96    }
97}
```

完成以上所有步骤后，当代码推送到 Git 仓库时，Jenkins 就会自动触发流水线，完成从代码到 K8s 集群的全自动部署。



在 Kubernetes (K8s) 中部署 Jenkins 并集成 Ceph 存储，然后设计一条自动化流水线来部署包含前端和后端的 Go 项目，这是一个非常经典且实用的 CI/CD 场景。

整个方案可以分为三个主要部分：

1. **在 K8s 中部署 Ceph 存储**：作为 Jenkins 和应用的持久化后端。
2. **在 K8s 中部署 Jenkins**：配置好使用 Ceph 的持久化存储。
3. **设计 Jenkins 流水线**：编写 `Jenkinsfile` 来自动化整个构建、测试、打包和部署流程。

------

# 2

### 🗄️ 第一部分：在 K8s 中部署 Ceph 存储

我们将使用 Rook 作为 Ceph 的 Kubernetes 编排器，它能极大地简化 Ceph 的部署和管理。

#### 1. 部署 Rook Operator

Rook Operator 负责在 K8s 集群中创建和管理 Ceph 集群。

bash



```
1# 克隆 Rook 仓库
2git clone --single-branch --branch v1.12.0 https://github.com/rook/rook.git
3cd rook/cluster/examples/kubernetes/ceph
4
5# 创建 Rook Operator
6kubectl create -f crds.yaml -f common.yaml -f operator.yaml
```

#### 2. 创建 Ceph 集群

Operator 部署完成后，创建 Ceph 集群实例。

bash



```
1# 创建 Ceph 集群
2kubectl create -f cluster.yaml
```

`cluster.yaml` 定义了 Ceph 集群的基本配置，如 Monitor、OSD 的数量等。

#### 3. 创建 Ceph 存储池 (Pools)

Ceph 存储池是数据组织的逻辑单元。我们将为 Jenkins 和 Go 应用创建不同的存储池。

`pool-config.yaml`:

yaml



```
1---
2apiVersion: ceph.rook.io/v1
3kind: CephBlockPool
4metadata:
5  name: replicapool
6  namespace: rook-ceph
7spec:
8  failureDomain: host
9  replicated:
10    size: 3
11    # 在测试环境可以使用 1，生产环境建议 3
12    requireSafeReplicaSize: 1
13---
14apiVersion: ceph.rook.io/v1
15kind: CephFilesystem
16metadata:
17  name: cephfs
18  namespace: rook-ceph
19spec:
20  metadataPool:
21    replicated:
22      size: 3
23  dataPools:
24    - failureDomain: host
25      replicated:
26        size: 3
27  metadataServer:
28    activeCount: 1
29    activeStandby: true
```

应用配置：`kubectl apply -f pool-config.yaml`

- **CephBlockPool (replicapool)**: 用于创建 RBD (RADOS Block Device) 类型的存储，性能好，适合数据库和 Jenkins 主目录。
- **CephFilesystem (cephfs)**: 提供 CephFS 文件系统，支持多节点读写，适合共享存储场景。

#### 4. 创建 StorageClass

StorageClass 允许我们动态地创建 PersistentVolume (PV)。

`storageclass.yaml`:

yaml



```
1---
2apiVersion: storage.k8s.io/v1
3kind: StorageClass
4metadata:
5  name: rook-ceph-block
6provisioner: rook-ceph.rbd.csi.ceph.com
7parameters:
8  clusterID: rook-ceph
9  pool: replicapool
10  imageFormat: "2"
11  imageFeatures: layering
12  csi.storage.k8s.io/provisioner-secret-name: rook-ceph-csi
13  csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
14  csi.storage.k8s.io/controller-expand-secret-name: rook-ceph-csi
15  csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
16  csi.storage.k8s.io/node-stage-secret-name: rook-ceph-csi
17  csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
18reclaimPolicy: Retain # 生产环境建议使用 Retain
19allowVolumeExpansion: true
20---
21apiVersion: storage.k8s.io/v1
22kind: StorageClass
23metadata:
24  name: rook-cephfs
25provisioner: rook-ceph.cephfs.csi.ceph.com
26parameters:
27  clusterID: rook-ceph
28  fsName: cephfs
29  pool: cephfs-data
30  csi.storage.k8s.io/provisioner-secret-name: rook-ceph-csi
31  csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
32  csi.storage.k8s.io/controller-expand-secret-name: rook-ceph-csi
33  csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
34  csi.storage.k8s.io/node-stage-secret-name: rook-ceph-csi
35  csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
36reclaimPolicy: Retain
37allowVolumeExpansion: true
```

应用配置：`kubectl apply -f storageclass.yaml`

- **rook-ceph-block**: 用于 Jenkins 主目录等需要高性能块存储的场景。
- **rook-cephfs**: 用于需要共享访问的场景。

------

### 🗂️ 第二部分：在 K8s 中部署 Jenkins (使用 Ceph 存储)

#### 1. 创建 Jenkins 命名空间

bash



```
1kubectl create namespace jenkins
```

#### 2. 创建 Jenkins RBAC 权限

Jenkins 需要权限来与 K8s API 交互。

`jenkins-rbac.yaml`:

yaml



```
1---
2apiVersion: v1
3kind: ServiceAccount
4metadata:
5  name: jenkins
6  namespace: jenkins
7---
8apiVersion: rbac.authorization.k8s.io/v1
9kind: ClusterRole
10metadata:
11  name: jenkins
12rules:
13- apiGroups: [""]
14  resources: ["pods", "pods/exec", "pods/log", "persistentvolumeclaims", "events"]
15  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
16- apiGroups: ["apps"]
17  resources: ["deployments", "daemonsets", "replicasets", "statefulsets"]
18  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
19---
20apiVersion: rbac.authorization.k8s.io/v1
21kind: ClusterRoleBinding
22metadata:
23  name: jenkins
24roleRef:
25  apiGroup: rbac.authorization.k8s.io
26  kind: ClusterRole
27  name: jenkins
28subjects:
29- kind: ServiceAccount
30  name: jenkins
31  namespace: jenkins
```

应用配置：`kubectl apply -f jenkins-rbac.yaml`

#### 3. 部署 Jenkins

使用 `StatefulSet` 部署 Jenkins，并挂载由 Ceph RBD 提供的 PVC。

`jenkins-statefulset.yaml`:

yaml



```
1apiVersion: apps/v1
2kind: StatefulSet
3metadata:
4  name: jenkins
5  namespace: jenkins
6spec:
7  serviceName: jenkins
8  replicas: 1
9  selector:
10    matchLabels:
11      app: jenkins
12  template:
13    metadata:
14      labels:
15        app: jenkins
16    spec:
17      serviceAccountName: jenkins
18      securityContext:
19        fsGroup: 1000
20      containers:
21      - name: jenkins
22        image: jenkins/jenkins:2.426.1-lts-jdk17
23        ports:
24        - containerPort: 8080
25          name: http
26        - containerPort: 50000
27          name: agent
28        resources:
29          requests:
30            cpu: "1"
31            memory: "2Gi"
32          limits:
33            cpu: "2"
34            memory: "4Gi"
35        livenessProbe:
36          httpGet:
37            path: /login
38            port: 8080
39          initialDelaySeconds: 120
40          periodSeconds: 10
41        readinessProbe:
42          httpGet:
43            path: /login
44            port: 8080
45          initialDelaySeconds: 60
46          periodSeconds: 10
47        volumeMounts:
48        - name: jenkins-home
49          mountPath: /var/jenkins_home
50  volumeClaimTemplates:
51  - metadata:
52      name: jenkins-home
53    spec:
54      accessModes: ["ReadWriteOnce"]
55      storageClassName: rook-ceph-block # 引用 Ceph RBD StorageClass
56      resources:
57        requests:
58          storage: 50Gi
```

应用配置：`kubectl apply -f jenkins-statefulset.yaml`

#### 4. 暴露 Jenkins 服务

`jenkins-service.yaml`:

yaml



```
1apiVersion: v1
2kind: Service
3metadata:
4  name: jenkins-service
5  namespace: jenkins
6spec:
7  selector:
8    app: jenkins
9  ports:
10  - name: http
11    port: 80
12    targetPort: 8080
13  - name: agent
14    port: 50000
15    targetPort: 50000
16  type: ClusterIP
```

`jenkins-ingress.yaml`:

yaml



```
1apiVersion: networking.k8s.io/v1
2kind: Ingress
3metadata:
4  name: jenkins-ingress
5  namespace: jenkins
6  annotations:
7    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
8spec:
9  rules:
10  - host: jenkins.yourdomain.com
11    http:
12      paths:
13      - path: /
14        pathType: Prefix
15        backend:
16          service:
17            name: jenkins-service
18            port:
19              name: http
```

应用配置：`kubectl apply -f jenkins-service.yaml` 和 `kubectl apply -f jenkins-ingress.yaml`

------

### 🚀 第三部分：设计 Jenkins 流水线

#### 1. 准备 Go 项目

假设项目结构如下：

文本



```
1my-go-project/
2├── backend/
3│   ├── main.go
4│   ├── go.mod
5│   └── Dockerfile
6├── frontend/
7│   ├── main.go
8│   ├── go.mod
9│   └── Dockerfile
10└── k8s/
11    ├── backend-deployment.yaml
12    ├── backend-service.yaml
13    ├── frontend-deployment.yaml
14    └── frontend-service.yaml
```

**Dockerfile 示例 (backend/Dockerfile):**

dockerfile



```
1FROM golang:1.21-alpine AS builder
2WORKDIR /app
3COPY go.mod go.sum ./
4RUN go mod download
5COPY . .
6RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o backend .
7
8FROM alpine:latest
9RUN apk --no-cache add ca-certificates
10WORKDIR /root/
11COPY --from=builder /app/backend .
12EXPOSE 8080
13CMD ["./backend"]
```

**K8s 部署文件示例 (k8s/backend-deployment.yaml):**

yaml



```
1apiVersion: apps/v1
2kind: Deployment
3metadata:
4  name: myapp-backend
5  namespace: default
6spec:
7  replicas: 2
8  selector:
9    matchLabels:
10      app: myapp-backend
11  template:
12    metadata:
13      labels:
14        app: myapp-backend
15    spec:
16      containers:
17      - name: backend
18        image: your-docker-registry.com/your-namespace/myapp-backend:latest
19        ports:
20        - containerPort: 8080
```

#### 2. 配置 Jenkins 凭据

在 Jenkins 的 "系统" -> "凭据" 中，添加：

- **Docker Registry 凭据**: ID 为 `docker-registry-cred`。
- **Kubeconfig 凭据**: ID 为 `k8s-kubeconfig`。

#### 3. 编写 Jenkinsfile

groovy



```
1pipeline {
2    agent any
3
4    environment {
5        DOCKER_REGISTRY = 'your-docker-registry.com/your-namespace'
6        BACKEND_IMAGE = "${DOCKER_REGISTRY}/myapp-backend"
7        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/myapp-frontend"
8        GIT_COMMIT_HASH = "${sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()}"
9        IMAGE_TAG = "${GIT_COMMIT_HASH}"
10        KUBECONFIG_CREDENTIALS_ID = 'k8s-kubeconfig'
11        DOCKER_CREDENTIALS_ID = 'docker-registry-cred'
12    }
13
14    stages {
15        stage('Checkout') {
16            steps {
17                checkout scm
18            }
19        }
20
21        stage('Build & Push Images') {
22            parallel {
23                stage('Build & Push Backend') {
24                    steps {
25                        script {
26                            withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
27                                sh """
28                                    docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD} ${DOCKER_REGISTRY}
29                                    docker build -t ${BACKEND_IMAGE}:${IMAGE_TAG} ./backend
30                                    docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
31                                """
32                            }
33                        }
34                    }
35                }
36                stage('Build & Push Frontend') {
37                    steps {
38                        script {
39                            withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
40                                sh """
41                                    docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD} ${DOCKER_REGISTRY}
42                                    docker build -t ${FRONTEND_IMAGE}:${IMAGE_TAG} ./frontend
43                                    docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}
44                                """
45                            }
46                        }
47                    }
48                }
49            }
50        }
51
52        stage('Deploy to Kubernetes') {
53            steps {
54                script {
55                    withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS_ID}", variable: 'KUBECONFIG')]) {
56                        sh """
57                            export IMAGE_TAG=${IMAGE_TAG}
58                            export DOCKER_REGISTRY=${DOCKER_REGISTRY}
59                            
60                            envsubst < k8s/backend-deployment.yaml | kubectl --kubeconfig=\$KUBECONFIG apply -f -
61                            kubectl --kubeconfig=\$KUBECONFIG apply -f k8s/backend-service.yaml
62                            
63                            envsubst < k8s/frontend-deployment.yaml | kubectl --kubeconfig=\$KUBECONFIG apply -f -
64                            kubectl --kubeconfig=\$KUBECONFIG apply -f k8s/frontend-service.yaml
65
66                            kubectl --kubeconfig=\$KUBECONFIG rollout status deployment/myapp-backend
67                            kubectl --kubeconfig=\$KUBECONFIG rollout status deployment/myapp-frontend
68                        """
69                    }
70                }
71            }
72        }
73    }
74
75    post {
76        always {
77            cleanWs()
78        }
79        success {
80            echo "🎉 部署成功！"
81        }
82        failure {
83            echo "❌ 部署失败！"
84        }
85    }
86}
```

完成以上所有步骤后，当代码推送到 Git 仓库时，Jenkins 就会自动触发流水线，完成从代码到 K8s 集群的全自动部署。

# 3

### 第一阶段：配置 Ceph 存储 (基于 Rook)

假设你已经在 K8s 集群中安装了 Rook Operator。我们需要创建存储池和 StorageClass，以便 Jenkins 可以使用。

#### 1. 创建 CephBlockPool 和 StorageClass

我们需要一个高性能的块存储（RBD）给 Jenkins 使用。

创建 `ceph-storage.yaml`：

yaml



```
1# 1. 定义存储池
2apiVersion: ceph.rook.io/v1
3kind: CephBlockPool
4metadata:
5  name: replicapool
6  namespace: rook-ceph
7spec:
8  failureDomain: host
9  replicated:
10    size: 3 # 生产环境建议3副本
11    requireSafeReplicaSize: true
12
13---
14# 2. 定义 StorageClass
15apiVersion: storage.k8s.io/v1
16kind: StorageClass
17metadata:
18  name: rook-ceph-block
19  annotations:
20    storageclass.kubernetes.io/is-default-class: "true" # 设为默认类
21provisioner: rook-ceph.rbd.csi.ceph.com
22parameters:
23  clusterID: rook-ceph
24  pool: replicapool
25  imageFormat: "2"
26  imageFeatures: layering
27  csi.storage.k8s.io/provisioner-secret-name: rook-ceph-csi
28  csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
29  csi.storage.k8s.io/controller-expand-secret-name: rook-ceph-csi
30  csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
31  csi.storage.k8s.io/node-stage-secret-name: rook-ceph-csi
32  csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
33reclaimPolicy: Retain # 生产环境建议保留数据
34allowVolumeExpansion: true
```

应用配置：

bash



```
1kubectl apply -f ceph-storage.yaml
```

------

### 🏗️ 第二阶段：在 K8s 中部署 Jenkins

我们将使用 StatefulSet 部署 Jenkins，以确保存储的稳定挂载。

#### 1. 创建 RBAC 权限

Jenkins 需要权限来管理 K8s 资源（如部署应用）。

创建 `jenkins-rbac.yaml`：

yaml



```
1apiVersion: v1
2kind: ServiceAccount
3metadata:
4  name: jenkins
5  namespace: default
6---
7apiVersion: rbac.authorization.k8s.io/v1
8kind: ClusterRole
9metadata:
10  name: jenkins-role
11rules:
12- apiGroups: [""]
13  resources: ["pods", "pods/exec", "pods/log", "services", "persistentvolumeclaims"]
14  verbs: ["*"]
15- apiGroups: ["apps"]
16  resources: ["deployments", "daemonsets", "replicasets", "statefulsets"]
17  verbs: ["*"]
18- apiGroups: ["networking.k8s.io"]
19  resources: ["ingresses"]
20  verbs: ["*"]
21---
22apiVersion: rbac.authorization.k8s.io/v1
23kind: ClusterRoleBinding
24metadata:
25  name: jenkins-role-binding
26roleRef:
27  apiGroup: rbac.authorization.k8s.io
28  kind: ClusterRole
29  name: jenkins-role
30subjects:
31- kind: ServiceAccount
32  name: jenkins
33  namespace: default
```

#### 2. 部署 Jenkins StatefulSet

创建 `jenkins-statefulset.yaml`：

yaml



```
1apiVersion: apps/v1
2kind: StatefulSet
3metadata:
4  name: jenkins
5spec:
6  serviceName: jenkins
7  replicas: 1
8  selector:
9    matchLabels:
10      app: jenkins
11  template:
12    metadata:
13      labels:
14        app: jenkins
15    spec:
16      serviceAccountName: jenkins
17      securityContext:
18        fsGroup: 1000 # 关键：确保 Ceph 卷权限正确
19      containers:
20      - name: jenkins
21        image: jenkins/jenkins:2.426.1-lts-jdk17
22        ports:
23        - containerPort: 8080
24        - containerPort: 50000
25        env:
26        - name: JAVA_OPTS
27          value: "-Xmx2048m -Dhudson.slaves.NodeProvisioner.MARGIN=50"
28        volumeMounts:
29        - name: jenkins-data
30          mountPath: /var/jenkins_home
31        resources:
32          requests:
33            memory: "2Gi"
34            cpu: "1000m"
35          limits:
36            memory: "4Gi"
37            cpu: "2000m"
38  volumeClaimTemplates:
39  - metadata:
40      name: jenkins-data
41    spec:
42      accessModes: ["ReadWriteOnce"]
43      storageClassName: rook-ceph-block # 使用 Ceph 存储
44      resources:
45        requests:
46          storage: 50Gi
```

#### 3. 暴露 Jenkins 服务

bash



```
1kubectl apply -f jenkins-rbac.yaml
2kubectl apply -f jenkins-statefulset.yaml
3
4# 创建一个简单的 LoadBalancer 或 NodePort 服务用于初次访问
5kubectl expose statefulset jenkins --name=jenkins-service --port=8080 --target-port=8080 --type=NodePort
```

------

### 🚀 第三阶段：Go 项目与流水线设计

假设你的 Go 项目结构如下：

text



```
1my-app/
2├── backend/          # Go 后端代码
3│   ├── main.go
4│   └── Dockerfile
5├── frontend/         # Go 前端代码 (或静态资源)
6│   ├── main.go
7│   └── Dockerfile
8├── k8s/              # K8s 部署模板
9│   ├── deployment.yaml
10│   └── service.yaml
11└── Jenkinsfile
```

#### 1. 准备 Dockerfile

**backend/Dockerfile** (多阶段构建):

dockerfile



```
1FROM golang:1.21-alpine AS builder
2WORKDIR /app
3COPY . .
4RUN go build -o server .
5
6FROM alpine:latest
7RUN apk --no-cache add ca-certificates
8WORKDIR /root/
9COPY --from=builder /app/server .
10EXPOSE 8080
11CMD ["./server"]
```

#### 2. 准备 K8s 部署模板 (k8s/deployment.yaml)

这里我们使用占位符，由 Jenkins 在部署时替换镜像版本。

yaml



```
1apiVersion: apps/v1
2kind: Deployment
3metadata:
4  name: mygo-app
5spec:
6  replicas: 2
7  selector:
8    matchLabels:
9      app: mygo-app
10  template:
11    metadata:
12      labels:
13        app: mygo-app
14    spec:
15      containers:
16      - name: backend
17        image: ${DOCKER_REGISTRY}/backend:${IMAGE_TAG} # 变量替换点
18        ports:
19        - containerPort: 8080
20        resources:
21          requests:
22            memory: "128Mi"
23            cpu: "100m"
24---
25apiVersion: v1
26kind: Service
27metadata:
28  name: mygo-app-service
29spec:
30  selector:
31    app: mygo-app
32  ports:
33    - protocol: TCP
34      port: 80
35      targetPort: 8080
36  type: ClusterIP
```

#### 3. 设计 Jenkinsfile (核心部分)

这个流水线将完成：拉取代码 -> 构建镜像 -> 推送镜像 -> 替换版本 -> 部署到 K8s。

**前提**：在 Jenkins 凭据管理中添加以下 ID 的凭据：

- `docker-cred`: Docker 仓库账号密码。
- `kubeconfig`: K8s 集群管理员配置文件。

groovy



```
1pipeline {
2    agent any
3
4    environment {
5        // 定义环境变量
6        DOCKER_REGISTRY = 'registry.example.com/mygroup' // 你的镜像仓库地址
7        IMAGE_TAG = "${env.BUILD_NUMBER}-${gitCommit()}" // 使用构建号+Git哈希作为标签
8        APP_NAME = 'mygo-app'
9        NAMESPACE = 'default'
10        // 指定 Kubeconfig 文件路径
11        KUBECONFIG_CREDENTIALS_ID = 'kubeconfig'
12        DOCKER_CREDENTIALS_ID = 'docker-cred'
13    }
14
15    tools {
16        // 确保 Jenkins 节点安装了 Docker 和 Kubectl 工具
17        jdk 'jdk17' 
18    }
19
20    stages {
21        stage('Checkout') {
22            steps {
23                checkout scm
24            }
25        }
26
27        stage('Build & Push Images') {
28            parallel {
29                stage('Build Backend') {
30                    steps {
31                        script {
32                            docker.withRegistry("https://${DOCKER_REGISTRY}", DOCKER_CREDENTIALS_ID) {
33                                def backendImage = docker.build("${DOCKER_REGISTRY}/backend:${IMAGE_TAG}", "./backend")
34                                backendImage.push()
35                            }
36                        }
37                    }
38                }
39                stage('Build Frontend') {
40                    steps {
41                        script {
42                            docker.withRegistry("https://${DOCKER_REGISTRY}", DOCKER_CREDENTIALS_ID) {
43                                def frontendImage = docker.build("${DOCKER_REGISTRY}/frontend:${IMAGE_TAG}", "./frontend")
44                                frontendImage.push()
45                            }
46                        }
47                    }
48                }
49            }
50        }
51
52        stage('Deploy to K8s') {
53            steps {
54                script {
55                    // 使用 Kubeconfig 凭据
56                    withCredentials([file(credentialsId: KUBECONFIG_CREDENTIALS_ID, variable: 'KUBECONFIG')]) {
57                        // 设置环境变量用于 envsubst 替换
58                        sh '''
59                            export KUBECONFIG=$KUBECONFIG
60                            export DOCKER_REGISTRY=$DOCKER_REGISTRY
61                            export IMAGE_TAG=$IMAGE_TAG
62                            
63                            # 使用 envsubst 替换 deployment.yaml 中的变量并应用
64                            envsubst < k8s/deployment.yaml | kubectl apply -f -
65                            kubectl apply -f k8s/service.yaml
66                            
67                            # 等待部署完成
68                            kubectl rollout status deployment/$APP_NAME
69                        '''
70                    }
71                }
72            }
73        }
74    }
75
76    post {
77        always {
78            // 清理工作区
79            cleanWs()
80            // 清理 Docker 镜像缓存以防磁盘爆满
81            sh 'docker system prune -f'
82        }
83        success {
84            echo "🎉 部署成功！访问地址：https://your-domain.com"
85        }
86        failure {
87            echo "❌ 部署失败，请检查日志。"
88        }
89    }
90}
91
92// 辅助函数：获取 Git Commit Hash
93def gitCommit() {
94    return sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
95}
```

------

### 🔒 第四阶段：配置 Ingress Nginx 与 HTTPS

为了让前端通过 HTTPS 访问，我们需要配置 Ingress。

#### 1. 安装 Ingress Nginx Controller

如果你还没有安装：

bash



```
1kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

#### 2. 配置 HTTPS Ingress

你需要一个 TLS 证书（可以使用 Let's Encrypt 或自签名证书）。将证书和密钥存储在 K8s Secret 中。

bash



```
1# 创建 TLS Secret
2kubectl create secret tls mygo-tls-secret \
3  --cert=path/to/tls.crt \
4  --key=path/to/tls.key \
5  -n default
```

#### 3. 创建 Ingress 资源

在 `k8s/ingress.yaml` 中定义：

yaml



```
1apiVersion: networking.k8s.io/v1
2kind: Ingress
3metadata:
4  name: mygo-ingress
5  annotations:
6    nginx.ingress.kubernetes.io/rewrite-target: /
7    nginx.ingress.kubernetes.io/ssl-redirect: "true" # 强制跳转 HTTPS
8spec:
9  ingressClassName: nginx
10  tls:
11  - hosts:
12    - myapp.example.com # 你的域名
13    secretName: mygo-tls-secret
14  rules:
15  - host: myapp.example.com
16    http:
17      paths:
18      - path: /
19        pathType: Prefix
20        backend:
21          service:
22            name: mygo-app-service # 对应 K8s Service 名称
23            port:
24              number: 80
```

应用 Ingress：

bash



```
1kubectl apply -f k8s/ingress.yaml
```

### 📌 总结

1. **存储**：通过 Rook Ceph 提供了可靠的 `rook-ceph-block` 存储类，Jenkins 数据（50Gi）持久化在 Ceph 中。
2. **流水线**：Jenkins 并行构建前后端镜像，推送到仓库，利用 `envsubst` 动态替换 K8s YAML 中的镜像版本，实现原子更新。
3. **访问**：通过 Ingress Nginx 监听 443 端口，绑定 TLS Secret，实现了安全的 HTTPS 访问。

