# 1

在 Kubernetes 上部署 Harbor 并将存储后端配置为 Ceph，主要有两种主流方案：

1. **方案一（推荐）：** 使用 Helm 部署 Harbor，通过 Kubernetes 的 **PersistentVolumeClaim (PVC)** 机制，利用 Rook-Ceph 提供的 StorageClass 动态申请 Ceph 存储。这是云原生环境下的标准做法。
2. **方案二：** 在宿主机上将 Ceph RBD 设备映射并挂载为本地目录，然后在部署 Harbor 时（通常使用离线安装包）将该目录配置为数据卷。这种方式更接近传统虚拟机部署。

下面将详细介绍这两种方案的完整步骤。

------

### 📦 方案一：使用 Helm 和 Rook-Ceph 动态供给存储（推荐）

此方案充分利用了 Kubernetes 的原生能力，管理更加便捷。

#### 第一步：部署 Ceph 集群 (使用 Rook Operator)

Rook 是一个 Kubernetes 操作符，可以自动化部署和管理 Ceph 集群。

1. **克隆 Rook 仓库并进入示例目录**

   bash

   

   ```
   1git clone --single-branch --branch v1.13.0 https://github.com/rook/rook.git
   2cd rook/deploy/examples
   ```

2. **部署 Rook Operator**
   这将创建 Rook 所需的命名空间、CRD 和 Operator 本身。

   bash

   

   ```
   1kubectl create -f crds.yaml
   2kubectl create -f common.yaml
   3kubectl create -f operator.yaml
   ```

   等待 `rook-ceph-operator` Pod 进入 `Running` 状态。

3. **准备存储节点**
   确保你的 K8s 节点上有未使用的磁盘（例如 `/dev/sdb`）供 Ceph 使用。

4. **部署 Ceph 集群**
   创建 `ceph-cluster.yaml` 文件，定义你的 Ceph 集群。

   yaml

   

   ```
   1# ceph-cluster.yaml
   2apiVersion: ceph.rook.io/v1
   3kind: CephCluster
   4metadata:
   5  name: rook-ceph
   6  namespace: rook-ceph
   7spec:
   8  cephVersion:
   9    image: quay.io/ceph/ceph:v18.2.0
   10  dataDirHostPath: /var/lib/rook
   11  mon:
   12    count: 3 # 建议至少3个以保证高可用
   13  mgr:
   14    count: 1
   15  storage:
   16    useAllNodes: false
   17    useAllDevices: false
   18    nodes:
   19    - name: "node1" # 替换为你的节点名
   20      devices:
   21      - name: "sdb" # 替换为你的磁盘名
   22    - name: "node2"
   23      devices:
   24      - name: "sdb"
   25    - name: "node3"
   26      devices:
   27      - name: "sdb"
   ```

   应用配置并等待集群就绪（可能需要 5-10 分钟）：

   bash

   

   ```
   1kubectl apply -f ceph-cluster.yaml
   2watch kubectl get pods -n rook-ceph
   ```

5. **创建 CephBlockPool 和 StorageClass**
   创建 `ceph-block-pool.yaml` 文件。

   yaml

   

   ```
   1# ceph-block-pool.yaml
   2apiVersion: ceph.rook.io/v1
   3kind: CephBlockPool
   4metadata:
   5  name: replicapool
   6  namespace: rook-ceph
   7spec:
   8  failureDomain: host
   9  replicated:
   10    size: 3
   11    requireSafeReplicaSize: true
   12---
   13apiVersion: storage.k8s.io/v1
   14kind: StorageClass
   15metadata:
   16  name: rook-ceph-block
   17provisioner: rook-ceph.rbd.csi.ceph.com
   18parameters:
   19  clusterID: rook-ceph
   20  pool: replicapool
   21  imageFormat: "2"
   22  imageFeatures: layering
   23  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
   24  csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
   25  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
   26  csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
   27  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
   28  csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
   29  csi.storage.k8s.io/fstype: ext4
   30allowVolumeExpansion: true
   31reclaimPolicy: Delete
   ```

   应用配置：

   bash

   

   ```
   1kubectl apply -f ceph-block-pool.yaml
   ```

#### 第二步：使用 Helm 部署 Harbor

1. **添加 Harbor Helm 仓库**

   bash

   

   ```
   1helm repo add harbor https://helm.goharbor.io
   2helm repo update
   ```

2. **准备 `values.yaml` 配置文件**
   下载并自定义 Helm Chart 的配置。关键是将持久化存储的 `storageClass` 设置为上一步创建的 `rook-ceph-block`。

   yaml

   

   ```
   1# values.yaml
   2externalURL: https://harbor.mydomain.com # 替换为你的域名
   3expose:
   4  type: ingress # 或 loadBalancer
   5  tls:
   6    enabled: true
   7    certSource: auto # 或 manual 并指定 secretName
   8  ingress:
   9    hosts:
   10      core: harbor.mydomain.com # 替换为你的域名
   11
   12persistence:
   13  enabled: true
   14  # 确保这里指定的 storageClass 存在
   15  persistentVolumeClaim:
   16    registry:
   17      storageClass: "rook-ceph-block"
   18      size: 100Gi # 镜像存储大小
   19    chartmuseum:
   20      storageClass: "rook-ceph-block"
   21      size: 10Gi
   22    database:
   23      storageClass: "rook-ceph-block"
   24      size: 10Gi
   25    redis:
   26      storageClass: "rook-ceph-block"
   27      size: 5Gi
   28    jobservice:
   29      storageClass: "rook-ceph-block"
   30      size: 1Gi
   31    trivy:
   32      storageClass: "rook-ceph-block"
   33      size: 5Gi
   34# 其他配置如 harbor_admin_password 等可根据需要修改
   ```

3. **安装 Harbor**

   bash

   

   ```
   1helm install harbor harbor/harbor -n harbor --create-namespace -f values.yaml
   ```

4. **验证部署**

   bash

   

   ```
   1kubectl get pods -n harbor
   2kubectl get pvc -n harbor
   ```

   确认所有 Pod 状态为 `Running`，且 PVC 状态为 `Bound`。

------

### 💻 方案二：宿主机挂载 Ceph RBD 并使用离线包部署

此方案适用于无法或不方便使用 Helm 的场景。

#### 第一步：在宿主机上配置 Ceph RBD 存储

1. **创建 Ceph Pool 和 RBD 镜像**
   在任意一个已安装 Ceph 客户端工具的节点上执行：

   bash

   

   ```
   1# 创建名为 harbor-pool 的存储池
   2ceph osd pool create harbor-pool 128 128
   3
   4# 在池中创建一个 300GB 的 RBD 镜像
   5rbd create harbor-pool/harbor-data --size 300G
   ```

2. **映射 RBD 镜像并格式化**

   bash

   

   ```
   1# 将 RBD 镜像映射到本地，通常会返回如 /dev/rbd0 的设备路径
   2rbd map harbor-pool/harbor-data
   3
   4# 格式化设备 (假设映射的设备是 /dev/rbd0)
   5mkfs.ext4 /dev/rbd0
   ```

3. **挂载设备并配置开机自动挂载**

   bash

   

   ```
   1# 创建挂载点
   2mkdir -p /mnt/harbor
   3
   4# 挂载设备
   5mount /dev/rbd0 /mnt/harbor
   6
   7# 编辑 /etc/fstab 实现开机自动挂载
   8# 添加如下一行:
   9# /dev/rbd0 /mnt/harbor ext4 defaults,_netdev 0 0
   10echo "/dev/rbd0 /mnt/harbor ext4 defaults,_netdev 0 0" >> /etc/fstab
   ```

#### 第二步：部署 Harbor

1. **下载并解压 Harbor 离线安装包**

   bash

   

   ```
   1tar xvf harbor-offline-installer-v2.14.1.tgz
   2cd harbor
   ```

2. **配置 `harbor.yml`**
   复制模板文件并进行编辑，关键是将 `data_volume` 指向 Ceph 的挂载点。

   yaml

   

   ```
   1# harbor.yml
   2hostname: harbor.mydomain.com # 替换为你的域名或IP
   3
   4http:
   5  port: 80
   6# https:
   7#   port: 443
   8#   certificate: /path/to/cert
   9#   private_key: /path/to/key
   10
   11harbor_admin_password: Harbor12345
   12
   13# 关键配置：将数据卷指向 Ceph 挂载目录
   14data_volume: /mnt/harbor
   ```

3. **执行安装**

   bash

   

   ```
   1./install.sh --with-trivy
   ```

4. **验证安装**

   bash

   

   ```
   1docker ps | grep harbor
   ```

   确认 Harbor 相关容器已正常启动。

# 2

在两台主机（1 Master + 1 Node）的 K8s 集群上部署 Ceph 存储，最推荐的方式是使用 **Rook**。Rook 是一个云原生存储编排工具，它能将 Ceph 的部署和管理完全自动化，使其像 K8s 的原生服务一样运行。

考虑到你只有两个节点，为了兼顾高可用性和资源利用率，我们将采用一种混合部署模式：

- **Ceph Monitor (MON) 和管理组件**：部署在 Master 节点上，保证控制平面的稳定。
- **Ceph OSD (数据存储)**：部署在 Node 节点上，利用其空闲磁盘提供实际的存储空间。

以下是详细的操作步骤。

------

### 🚀 第一步：在 K8s 集群上部署 Rook-Ceph

所有 `kubectl` 命令都在 Master 节点上执行。

1. **克隆 Rook 项目仓库**
   获取 Rook 的部署示例文件。

   bash

   

   ```
   1git clone --single-branch --branch v1.13.0 https://github.com/rook/rook.git
   2cd rook/deploy/examples
   ```

2. **部署 Rook Operator**
   这会创建 Rook 所需的命名空间、自定义资源定义（CRD）和 Operator 本身。

   bash

   

   ```
   1kubectl create -f crds.yaml
   2kubectl create -f common.yaml
   3kubectl create -f operator.yaml
   ```

   等待 `rook-ceph-operator` Pod 进入 `Running` 状态。

   bash

   

   ```
   1watch kubectl get pods -n rook-ceph
   2# 按 Ctrl+C 退出 watch
   ```

3. **准备 Node 节点的存储**
   确保你的 Node 节点上有一块或多块**未使用**的空闲磁盘（例如 `/dev/sdb`）。Rook 会自动发现并使用这些磁盘来创建 OSD。

4. **自定义 Ceph 集群配置**
   这是关键一步。我们需要修改 `cluster.yaml` 文件，明确指定 MON 和 OSD 的部署位置。

   yaml

   

   ```
   1# cluster.yaml
   2apiVersion: ceph.rook.io/v1
   3kind: CephCluster
   4metadata:
   5  name: rook-ceph
   6  namespace: rook-ceph
   7spec:
   8  cephVersion:
   9    image: quay.io/ceph/ceph:v18.2.0
   10  dataDirHostPath: /var/lib/rook
   11  mon:
   12    count: 1 # 只有两个节点，部署1个MON即可
   13    allowMultiplePerNode: false
   14  mgr:
   15    count: 1
   16  storage:
   17    useAllNodes: false # 不使用所有节点，我们将手动指定
   18    useAllDevices: false # 不使用所有设备，我们将手动指定
   19    nodes:
   20    - name: "node" # 替换为你的 Node 节点的主机名
   21      devices:
   22      - name: "sdb" # 替换为你在 Node 节点上准备的实际磁盘名，如 sdb, vdb 等
   23    - name: "master" # 让 Master 节点也加入存储集群，但只用它来放 MON/MGR
   24      devices:
   25      - name: "osd" # 这是一个占位符，表示 Master 节点不提供 OSD 磁盘
   26        filter: "nonexistent-disk-to-prevent-osd-creation" # 通过过滤器阻止在 Master 上创建 OSD
   ```

   应用此配置，Rook 将开始创建 Ceph 集群。

   bash

   

   ```
   1kubectl apply -f cluster.yaml
   2watch kubectl get pods -n rook-ceph
   3# 等待所有 Pod 状态为 Running，这可能需要几分钟
   ```

5. **验证 Ceph 集群状态**
   使用 Rook 提供的工具箱来检查集群健康状况。

   bash

   

   ```
   1# 进入工具箱 Pod
   2kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items.metadata.name}') -- bash
   3
   4# 在工具箱内执行
   5ceph -s
   6# 你应该能看到 health: HEALTH_OK
   7ceph osd tree
   8# 你应该能看到你的 node 节点及其上的 osd.0
   9exit
   ```

------

### 💾 第二步：创建存储池和 StorageClass

Ceph 集群就绪后，需要创建存储池（Pool）和对应的 Kubernetes StorageClass，以便应用可以动态申请存储。

1. **创建 CephBlockPool 和 StorageClass**
   创建一个名为 `ceph-block-pool.yaml` 的文件。

   yaml

   

   ```
   1# ceph-block-pool.yaml
   2apiVersion: ceph.rook.io/v1
   3kind: CephBlockPool
   4metadata:
   5  name: replicapool
   6  namespace: rook-ceph
   7spec:
   8  failureDomain: host # 故障域为主机级别
   9  replicated:
   10    size: 1 # 因为只有1个OSD，副本数必须为1
   11    requireSafeReplicaSize: true
   12---
   13apiVersion: storage.k8s.io/v1
   14kind: StorageClass
   15metadata:
   16  name: rook-ceph-block
   17provisioner: rook-ceph.rbd.csi.ceph.com
   18parameters:
   19  clusterID: rook-ceph
   20  pool: replicapool
   21  imageFormat: "2"
   22  imageFeatures: layering
   23  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
   24  csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
   25  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
   26  csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
   27  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
   28  csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
   29  csi.storage.k8s.io/fstype: ext4
   30allowVolumeExpansion: true
   31reclaimPolicy: Delete
   ```

   应用配置：

   bash

   

   ```
   1kubectl apply -f ceph-block-pool.yaml
   ```

2. **（可选）设置为默认 StorageClass**
   如果你希望所有未指定 StorageClass 的 PVC 都自动使用 Ceph 存储，可以将其设为默认。

   bash

   

   ```
   1kubectl patch storageclass rook-ceph-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
   ```

------

### ✅ 第三步：测试存储功能

创建一个简单的测试来验证 Ceph 存储是否可以正常分配和使用。

1. **创建测试 PVC 和 Pod**
   创建一个名为 `test-ceph.yaml` 的文件。

   yaml

   

   ```
   1# test-ceph.yaml
   2apiVersion: v1
   3kind: PersistentVolumeClaim
   4metadata:
   5  name: ceph-test-pvc
   6spec:
   7  accessModes:
   8    - ReadWriteOnce
   9  resources:
   10    requests:
   11      storage: 5Gi
   12  storageClassName: rook-ceph-block
   13---
   14apiVersion: v1
   15kind: Pod
   16metadata:
   17  name: ceph-test-pod
   18spec:
   19  containers:
   20  - name: test-container
   21    image: busybox
   22    command: ["/bin/sh", "-c"]
   23    args: ["while true; do date >> /mnt/ceph/data.txt; sleep 5; done"]
   24    volumeMounts:
   25    - name: ceph-storage
   26      mountPath: /mnt/ceph
   27  volumes:
   28  - name: ceph-storage
   29    persistentVolumeClaim:
   30      claimName: ceph-test-pvc
   ```

   应用配置：

   bash

   

   ```
   1kubectl apply -f test-ceph.yaml
   ```

2. **验证**

   bash

   

   ```
   1# 检查 PVC 状态是否为 Bound
   2kubectl get pvc ceph-test-pvc
   3
   4# 检查 Pod 是否运行
   5kubectl get pod ceph-test-pod
   6
   7# 进入 Pod 查看文件是否成功写入
   8kubectl exec -it ceph-test-pod -- cat /mnt/ceph/data.txt
   ```

   如果能看到不断写入的日期信息，恭喜你，Ceph 存储已经成功部署并可以正常使用了！

# 3

在只有两台主机（1 Master + 1 Node）且每台主机只有一块硬盘的情况下部署 Ceph，这是一个典型的**边缘计算或轻量级场景**。

由于 Ceph 的强一致性协议（Paxos/Raft）通常要求至少 3 个 Monitor 节点来选举主节点，且数据冗余（副本）通常要求至少 3 份，因此在 2 节点环境下，我们需要打破常规，采用**“混合部署 + 允许降级”**的策略。

以下是针对你硬件环境的**最佳实践方案**。

### ⚠️ 核心挑战与解决方案

表格



| 挑战             | 解决方案                                                     |
| :--------------- | :----------------------------------------------------------- |
| **Monitor 选举** | Ceph 默认需要奇数个 Monitor。在 2 节点下，我们部署 **2 个 Monitor**（Master 和 Node 各一个），并配置 `mon_allow_pool_size_one=true` 和 `mon_allow_pool_size_one=true` 相关的兼容参数，或者接受在脑裂时可能无法写入的风险。 |
| **数据冗余**     | 无法做 3 副本。我们将 Ceph 池配置为 **2 副本 (Size=2)** 或 **纠删码 (Erasure Code)**。推荐 **2 副本**，性能更好，配置更简单。 |
| **单盘限制**     | 如果这块盘是系统盘，**严禁**直接使用整块盘做 OSD。必须使用**目录（Directory）**或**分区**模式，利用空闲空间。 |

------

### 🚀 部署步骤 (基于 Rook-Ceph)

我们将使用 Rook，因为它能最好地处理这种非标准拓扑。

#### 第一步：准备存储 (关键)

由于只有一块盘（假设是 `/dev/sda` 且已安装系统），你不能把整块盘给 Ceph。我们需要用**目录**来模拟 OSD。

**在 Master 和 Node 节点上分别执行：**

1. **创建数据目录**（假设我们划拨 50G 给 Ceph）：

   bash

   

   ```
   1mkdir -p /var/lib/rook/osd0
   2# 注意：生产环境建议用 LVM 划分一个分区挂载到这里，这里为了演示直接用目录
   3# 确保该目录有足够空间
   ```

2. **安装 Rook 客户端工具** (可选，用于后续调试)：

   bash

   

   ```
   1yum install -y ceph-common
   ```

#### 第二步：部署 Rook Operator

在 **Master 节点** 上操作：

bash



```
1git clone --single-branch --branch v1.13.0 https://github.com/rook/rook.git
2cd rook/deploy/examples
3
4# 1. 创建 CRD 和 Operator
5kubectl create -f crds.yaml
6kubectl create -f common.yaml
7kubectl create -f operator.yaml
```

#### 第三步：配置 Ceph 集群 (适配 2 节点)

我们需要修改 `cluster.yaml` 来适应 2 节点和单盘环境。

创建或修改 `cluster.yaml`：

yaml



```
1apiVersion: ceph.rook.io/v1
2kind: CephCluster
3metadata:
4  name: rook-ceph
5  namespace: rook-ceph
6spec:
7  cephVersion:
8    image: quay.io/ceph/ceph:v18.2.0
9    allowUnsupported: false
10  dataDirHostPath: /var/lib/rook
11  mon:
12    count: 2 # 【关键】强制指定为 2 个 Monitor
13    allowMultiplePerNode: false
14  mgr:
15    count: 1
16  network:
17    connections:
18      encryption:
19        enabled: false
20  # 【关键】存储配置：使用目录模式
21  storage:
22    useAllNodes: true
23    useAllDevices: false # 【关键】不要使用所有设备，因为我们要用目录
24    # 定义节点，告诉 Rook 使用目录作为存储后端
25    nodes:
26    - name: "master" # 替换为你的 Master 主机名
27      directories:
28      - path: /var/lib/rook/osd0
29    - name: "node"   # 替换为你的 Node 主机名
30      directories:
31      - path: /var/lib/rook/osd0
32  # 【关键】允许 2 副本，否则 Ceph 会报错说无法放置数据
33  placement:
34    all:
35      tolerations:
36      - key: "node-role.kubernetes.io/master"
37        operator: "Exists"
38        effect: "NoSchedule"
```

应用配置：

bash



```
1kubectl apply -f cluster.yaml
```

**等待集群就绪：**

bash



```
1watch kubectl get pods -n rook-ceph
```

*注意：如果 OSD Pod 启动失败，查看日志，通常是因为目录权限问题。确保 `/var/lib/rook` 对 Rook 可见。*

#### 第四步：配置 2 副本存储池 (解决数据冗余问题)

默认的 Rook 配置是 3 副本，在 2 节点下会一直报错 `HEALTH_WARN` 且无法写入。我们需要将其改为 2 副本。

1. **进入 Ceph 工具箱**：

   bash

   

   ```
   1kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') -- bash
   ```

2. **修改默认副本数**：
   在工具箱内执行：

   bash

   

   ```
   1# 修改 replicapool 为 2 副本
   2ceph osd pool set replicapool size 2
   3ceph osd pool set replicapool min_size 1
   4
   5# 如果有 device health metrics pool，也建议调整
   6ceph osd pool set device_health_metrics size 2
   ```

3. **验证状态**：

   bash

   

   ```
   1ceph -s
   2# 此时应该看到 HEALTH_OK (或者 HEALTH_WARN 关于 mon 的，但数据应该是 clean 的)
   3ceph osd tree
   ```

#### 第五步：创建 StorageClass

为了让 K8s 能使用这个存储，我们需要一个允许 2 副本的 StorageClass。

创建 `storageclass.yaml`：

yaml



```
1apiVersion: storage.k8s.io/v1
2kind: StorageClass
3metadata:
4  name: rook-ceph-block-2replica
5  annotations:
6    storageclass.kubernetes.io/is-default-class: "true" # 设为默认类
7provisioner: rook-ceph.rbd.csi.ceph.com
8parameters:
9  clusterID: rook-ceph
10  pool: replicapool
11  imageFormat: "2"
12  imageFeatures: layering
13  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
14  csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
15  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
16  csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
17  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
18  csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
19  # 【关键】指定副本数为 2
20  replicaCount: "2"
21allowVolumeExpansion: true
22reclaimPolicy: Delete
```

应用：

bash



```
1kubectl apply -f storageclass.yaml
```

------

### 🧪 验证与测试

创建一个 PVC 来测试存储是否工作：

yaml



```
1apiVersion: v1
2kind: PersistentVolumeClaim
3metadata:
4  name: test-ceph-pvc
5spec:
6  accessModes:
7  - ReadWriteOnce
8  resources:
9    requests:
10      storage: 1Gi
11  storageClassName: rook-ceph-block-2replica
```

### ⚠️ 风险提示 (必读)

在这个 2 节点单盘架构中，你必须清楚以下风险：

1. 脑裂风险

   ：如果 Master 和 Node 之间的网络断开，Ceph Monitor 无法达成多数派（2 个节点断连变成 1:1），集群可能会变成

   只读

   状态以保护数据。

   - *缓解*：在生产环境中，通常会引入第 3 个非常轻量的节点（甚至是一个树莓派）只运行 Monitor 容器，凑成 3 票。

2. 数据丢失风险

   ：配置为 

   ```
   size=2
   ```

    意味着只要任意一个节点硬盘损坏，数据就会丢失（因为没有第 3 份副本）。

   - *建议*：务必做好应用层的数据备份。

3. **IO 性能**：由于是单盘且运行系统+OSD，磁盘 IO 争抢会比较严重。建议限制 OSD 的 IO 优先级。