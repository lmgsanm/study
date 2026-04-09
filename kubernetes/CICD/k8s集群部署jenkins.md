创建NFS服务

安装nfs服务组件

```
yum install -y nfs-utils rpcbind
```

在 Kubernetes 中使用 NFS 作为存储来安装 Jenkins，主要分为四个核心步骤：搭建 NFS 服务、配置 K8s 存储资源（PV/PVC）、配置权限（RBAC）以及部署 Jenkins 应用。

以下是基于最新资料整理的详细操作指南。

### 📋 架构概览

- **NFS Server**: 提供持久化存储（可以是 K8s 集群外的独立服务器，也可以是集群内的某个节点）。
- **K8s Cluster**: 运行 Jenkins 的 Master 和动态 Slave 节点。
- **Jenkins**: 将数据目录 `/var/jenkins_home` 挂载到 NFS 存储上。

------

### 🚀 第一步：搭建 NFS 服务端

你需要一台机器作为 NFS 服务器（假设 IP 为 `192.168.1.100`，系统为 CentOS 7/Ubuntu）。

#### 1. 安装 NFS 服务

- **CentOS**: `yum install -y nfs-utils rpcbind`
- **Ubuntu**: `apt install nfs-kernel-server`

#### 2. 创建共享目录并授权

Jenkins 容器通常以用户 ID `1000` 运行，因此需要确保 NFS 目录有相应的读写权限。

bash



```
1# 创建目录
2mkdir -p /data/nfs/jenkins
3
4# 授权 (简单粗暴方式：777，生产环境建议精确控制)
5chmod 777 /data/nfs/jenkins
6# 或者指定用户组 (推荐)
7# chown -R 1000:1000 /data/nfs/jenkins
```

#### 3. 配置 NFS 导出

编辑 `/etc/exports` 文件，添加以下内容：

bash



```
1/data/nfs/jenkins *(rw,sync,no_root_squash,no_all_squash)
```

- `rw`: 读写权限。
- `no_root_squash`: 允许 root 用户权限映射（某些 K8s 组件需要）。
- `no_all_squash`: 保持用户身份。

#### 4. 启动服务

bash



```
1systemctl enable --now nfs rpcbind
2exportfs -r  # 刷新配置
3showmount -e localhost # 验证是否生效
```

------

### 🗄️ 第二步：在 K8s 中创建 PV 和 PVC

我们需要创建持久卷（PV）来指向 NFS 目录，并创建持久卷声明（PVC）供 Jenkins 使用。

创建文件 `jenkins-storage.yaml`：

yaml



```
1apiVersion: v1
2kind: PersistentVolume
3metadata:
4  name: jenkins-pv
5  labels:
6    app: jenkins
7spec:
8  capacity:
9    storage: 10Gi  # 存储大小
10  accessModes:
11    - ReadWriteOnce # 或者 ReadWriteMany，取决于你的需求
12  persistentVolumeReclaimPolicy: Retain # 删除 PVC 后保留数据
13  storageClassName: nfs-jenkins # 必须与 PVC 中的 storageClassName 一致
14  nfs:
15    server: 192.168.1.100 # 你的 NFS 服务器 IP
16    path: /data/nfs/jenkins
17---
18apiVersion: v1
19kind: PersistentVolumeClaim
20metadata:
21  name: jenkins-pvc
22  namespace: jenkins
23spec:
24  accessModes:
25    - ReadWriteOnce
26  resources:
27    requests:
28      storage: 10Gi
29  storageClassName: nfs-jenkins
30  selector:
31    matchLabels:
32      app: jenkins
```

应用配置：

bash



```
1kubectl create namespace jenkins
2kubectl apply -f jenkins-storage.yaml
```

------

### 🔐 第三步：配置 RBAC 权限

为了让 Jenkins 能够管理 K8s 集群（例如动态创建 Slave Pod），需要配置 ServiceAccount 和 ClusterRoleBinding。

创建文件 `jenkins-rbac.yaml`：

yaml



```
1apiVersion: v1
2kind: ServiceAccount
3metadata:
4  name: jenkins-admin
5  namespace: jenkins
6---
7kind: ClusterRoleBinding
8apiVersion: rbac.authorization.k8s.io/v1beta1
9metadata:
10  name: jenkins-admin
11subjects:
12- kind: ServiceAccount
13  name: jenkins-admin
14  namespace: jenkins
15roleRef:
16  kind: ClusterRole
17  name: cluster-admin # 赋予集群管理员权限，方便 Jenkins 操作集群
18  apiGroup: rbac.authorization.k8s.io
```

应用配置：

bash



```
1kubectl apply -f jenkins-rbac.yaml
```

------

### 🏗️ 第四步：部署 Jenkins

创建文件 `jenkins-deployment.yaml`：

yaml



```
1apiVersion: apps/v1
2kind: Deployment
3metadata:
4  name: jenkins
5  namespace: jenkins
6spec:
7  replicas: 1
8  selector:
9    matchLabels:
10      app: jenkins
11  template:
12    metadata:
13      labels:
14        app: jenkins
15    spec:
16      serviceAccountName: jenkins-admin # 绑定上面创建的账号
17      securityContext:
18        fsGroup: 1000 # 关键：确保 Pod 使用正确的组 ID 挂载 NFS
19      containers:
20      - name: jenkins
21        image: jenkins/jenkins:lts
22        ports:
23        - containerPort: 8080
24        - containerPort: 50000
25        volumeMounts:
26        - name: jenkins-storage
27          mountPath: /var/jenkins_home
28        resources:
29          limits:
30            memory: 2Gi
31            cpu: 1000m
32          requests:
33            memory: 500Mi
34            cpu: 500m
35      volumes:
36      - name: jenkins-storage
37        persistentVolumeClaim:
38          claimName: jenkins-pvc
39---
40apiVersion: v1
41kind: Service
42metadata:
43  name: jenkins-service
44  namespace: jenkins
45spec:
46  type: NodePort # 生产环境建议使用 LoadBalancer 或 Ingress
47  ports:
48    - port: 8080
49      targetPort: 8080
50      nodePort: 30080 # 访问端口
51  selector:
52    app: jenkins
```

应用配置：

bash



```
1kubectl apply -f jenkins-deployment.yaml
```