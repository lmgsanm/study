# 一、环境信息

## 1.1	环境准备

### 1.1.1	服务器信息

操作系统：CentOS7.9

内核版本：3.10.0-1160.el7.x86_64

### 1.1.2	硬件配置

CPU：4C

内存：4G

磁盘：64GB

## 1.2	/etc/hosts配置

### 1.2.1主机信息

node01	192.168.1.211（master）

node02	192.168.1.212

node02	192.168.1.213

### 1.2.2	/etc/hosts配置

*cat /etc/hosts*

```
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.1.211 node01
192.168.1.212 node02
192.168.1.213 node03
```



# 二、系统准备

```
yum -y install net-tools lrzsz vim wget
```



## 2.1	关闭防火墙和selinux

```
setenforce 0
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config
```

## 2.2	关闭swap交换分区

```
swapoff -a
cp /etc/fstab{,-bk} && sed -i '/swap/d' /etc/fstab
```

## 2.3	加载br_netfilter

```
modprobe br_netfilter   #加载br_netfilter，删除br_netfilter模块modprobe -r br_netfilter
lsmod | grep br_netfilter	#查看br_netfilter是否被加载
```

## 2.4	配置内核参数

```
cat > /etc/sysctl.d/k8s.conf <<EOF 
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl -p /etc/sysctl.d/k8s.conf
```

## 2.5	文件打开数

### 2.5.1	调整ulimit最大打开文件数

```
echo "* soft nofile 655360" >> /etc/security/limits.conf
echo "* hard nofile 655360" >> /etc/security/limits.conf
echo "* soft nproc 655360" >> /etc/security/limits.conf
echo "* hard nproc 655360" >> /etc/security/limits.conf
echo "* soft memlock unlimited" >> /etc/security/limits.conf
echo "* hard memlock unlimited" >> /etc/security/limits.conf
```

*cat /etc/security/limits.conf*

![image-20220504203815531](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220504203815531.png)

### 2.5.2	调整systemctl管理的服务文件打开最大数

```
echo "DefaultLimitNOFILE=1024000" >> /etc/systemd/system.conf
echo "DefaultLimitNPROC=1024000" >> /etc/systemd/system.conf
```

 cat /etc/systemd/system.conf

![image-20220504203852405](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220504203852405.png)

## 2.6	配置yum源

### 2.6.1、配置CentOS的yum源

```
mkdir /etc/yum.repos.d/backup && mv /etc/yum.repos.d/CentOS-* /etc/yum.repos.d/backup/
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/epel.repo
yum clean all && yum makecache
```

![image-20220504204204374](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220504204204374.png)

### 2.6.2	配置kubernetes安装下载源

```
cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
EOF
yum clean all
yum makecache
```

### 2.6.3	配置docker的安装源

```
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
yum makecache fast
```



## 2.7	软件安装

### 2.7.1	安装docker-ce

```
yum -y install docker-ce
systemctl start docker
systemctl enable docker.service
```

![image-20220504205348174](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220504205348174.png)

*docker info*

```
Client:
 Context:    default
 Debug Mode: false
 Plugins:
  app: Docker App (Docker Inc., v0.9.1-beta3)
  buildx: Docker Buildx (Docker Inc., v0.8.1-docker)
  scan: Docker Scan (Docker Inc., v0.17.0)

Server:
 Containers: 0
  Running: 0
  Paused: 0
  Stopped: 0
 Images: 0
 Server Version: 20.10.14
 Storage Driver: overlay2
  Backing Filesystem: xfs
  Supports d_type: true
  Native Overlay Diff: true
  userxattr: false
 Logging Driver: json-file
 Cgroup Driver: cgroupfs
 Cgroup Version: 1
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local logentries splunk syslog
 Swarm: inactive
 Runtimes: io.containerd.runc.v2 io.containerd.runtime.v1.linux runc
 Default Runtime: runc
 Init Binary: docker-init
 containerd version: 3df54a852345ae127d1fa3092b95168e4a88e2f8
 runc version: v1.0.3-0-gf46b6ba
 init version: de40ad0
 Security Options:
  seccomp
   Profile: default
 Kernel Version: 3.10.0-1160.el7.x86_64
 Operating System: CentOS Linux 7 (Core)
 OSType: linux
 Architecture: x86_64
 CPUs: 4
 Total Memory: 3.7GiB
 Name: node01
 ID: MHDS:WODT:UBSU:56L6:WLK2:7ATU:H2ZU:56JQ:T2KI:MNF5:GUYZ:PPYO
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
 Registry: https://index.docker.io/v1/
 Labels:
 Experimental: false
 Insecure Registries:
  127.0.0.0/8
 Live Restore Enabled: false

```

 *docker version*

```
Client: Docker Engine - Community
 Version:           20.10.14
 API version:       1.41
 Go version:        go1.16.15
 Git commit:        a224086
 Built:             Thu Mar 24 01:49:57 2022
 OS/Arch:           linux/amd64
 Context:           default
 Experimental:      true

Server: Docker Engine - Community
 Engine:
  Version:          20.10.14
  API version:      1.41 (minimum version 1.12)
  Go version:       go1.16.15
  Git commit:       87a90dc
  Built:            Thu Mar 24 01:48:24 2022
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.5.11
  GitCommit:        3df54a852345ae127d1fa3092b95168e4a88e2f8
 runc:
  Version:          1.0.3
  GitCommit:        v1.0.3-0-gf46b6ba
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0

```



### 2.7.2	安装kubeadm依赖

```
yum install -y conntrack ipvsadm ipset jq sysstat curl iptables libseccomp bash-completion yum-utils device-mapper-persistent-data lvm2 net-tools conntrack-tools vim libtool-ltdl nc nmap
```

![image-20220504205514388](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220504205514388.png)

### 2.7.3	安装时间同步服务器

```
yum install -y chrony
systemctl enable chronyd.service 
systemctl start chronyd.service
```

### 2.7.4安装kubeadm等

查看可安装的版本：*yum list kubeadm --showduplicates | sort -r*

```
yum install -y kubelet  kubeadm kubectl --disableexcludes=kubernetes
systemctl enable kubelet && systemctl start kubelet
```

![image-20220504205726343](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220504205726343.png)

*kubeadm version -ojson*

```
{
  "clientVersion": {
    "major": "1",
    "minor": "24",
    "gitVersion": "v1.24.0",
    "gitCommit": "4ce5a8954017644c5420bae81d72b09b735c21f0",
    "gitTreeState": "clean",
    "buildDate": "2022-05-03T13:44:24Z",
    "goVersion": "go1.18.1",
    "compiler": "gc",
    "platform": "linux/amd64"
  }
}

```



## 2.8	软件配置

### 2.8.1	配置docker镜像加速器

```
cat > /etc/docker/daemon.json  << EOF

{
  "registry-mirrors": [
    "https://mciwm180.mirror.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn/",
    "https://4agcatqs.mirror.aliyuncs.com",
    "https://registry.docker-cn.com"
    ],
  "log-driver": "json-file",
  "log-opts": {
    "max-file": "10",
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "exec-opts": [
    "native.cgroupdriver=systemd"
    ],
  "storage-opts": [
    "overlay2.override_kernel_check=true"
    ]
}
EOF
systemctl daemon-reload
systemctl restart docker
```

*cat /etc/docker/daemon.json*

![image-20220504210600819](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220504210600819.png)

*docker info*

```
Client:
 Context:    default
 Debug Mode: false
 Plugins:
  app: Docker App (Docker Inc., v0.9.1-beta3)
  buildx: Docker Buildx (Docker Inc., v0.8.1-docker)
  scan: Docker Scan (Docker Inc., v0.17.0)

Server:
 Containers: 0
  Running: 0
  Paused: 0
  Stopped: 0
 Images: 0
 Server Version: 20.10.14
 Storage Driver: overlay2
  Backing Filesystem: xfs
  Supports d_type: true
  Native Overlay Diff: true
  userxattr: false
 Logging Driver: json-file
 Cgroup Driver: systemd
 Cgroup Version: 1
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local logentries splunk syslog
 Swarm: inactive
 Runtimes: runc io.containerd.runc.v2 io.containerd.runtime.v1.linux
 Default Runtime: runc
 Init Binary: docker-init
 containerd version: 3df54a852345ae127d1fa3092b95168e4a88e2f8
 runc version: v1.0.3-0-gf46b6ba
 init version: de40ad0
 Security Options:
  seccomp
   Profile: default
 Kernel Version: 3.10.0-1160.el7.x86_64
 Operating System: CentOS Linux 7 (Core)
 OSType: linux
 Architecture: x86_64
 CPUs: 4
 Total Memory: 3.7GiB
 Name: node03
 ID: H3TG:NQZX:MVFO:63YJ:6OWZ:LBW5:36G4:DEWC:JZI5:4KDF:HY3A:BCWQ
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
 Registry: https://index.docker.io/v1/
 Labels:
 Experimental: false
 Insecure Registries:
  127.0.0.0/8
 Registry Mirrors:
  https://mciwm180.mirror.aliyuncs.com/
  https://docker.mirrors.ustc.edu.cn/
  https://4agcatqs.mirror.aliyuncs.com/
  https://registry.docker-cn.com/
 Live Restore Enabled: false

```



```
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```



```
modprobe br_netfilter
modprobe overlay
```



```
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
```

```
sysctl --system
```



# 三、kubernetes集群部署

## 3.1	images下载

### 3.1.1	查看需下载的镜像版本

- 查看kubeadm默认支持的镜像版本

*kubeadm config images list*

```
k8s.gcr.io/kube-apiserver:v1.24.0
k8s.gcr.io/kube-controller-manager:v1.24.0
k8s.gcr.io/kube-scheduler:v1.24.0
k8s.gcr.io/kube-proxy:v1.24.0
k8s.gcr.io/pause:3.7
k8s.gcr.io/etcd:3.5.3-0
k8s.gcr.io/coredns/coredns:v1.8.6
```

### 3.1.2	image下载脚本

*cat images_install.sh*

```
#!/bin/bash
apiserver_version="v1.24.0"
controller_version="v1.24.0"
scheduler_version="v1.24.0"
proxy_version="v1.24.0"
pause_version="3.7"
etcd_version="3.5.3-0"
coredns_version="v1.8.6"

grc_uri="k8s.gcr.io"
aliyuncs_uri="registry.aliyuncs.com/google_containers"
#docker pull
docker pull ${aliyuncs_uri}/kube-apiserver:${apiserver_version}
sleep 10
docker pull ${aliyuncs_uri}/kube-controller-manager:${controller_version}
sleep 10
docker pull ${aliyuncs_uri}/kube-scheduler:${scheduler_version}
sleep 10
docker pull ${aliyuncs_uri}/kube-proxy:${proxy_version}
sleep 10
docker pull ${aliyuncs_uri}/pause:${pause_version}
sleep 10
docker pull ${aliyuncs_uri}/etcd:${etcd_version}
sleep 10
docker pull ${aliyuncs_uri}/coredns:${coredns_version}
sleep 10

#tag images
docker tag ${aliyuncs_uri}/kube-apiserver:${apiserver_version} ${grc_uri}/kube-apiserver:${apiserver_version}
docker tag ${aliyuncs_uri}/kube-controller-manager:${controller_version} ${grc_uri}/kube-controller-manager:${controller_version}
docker tag ${aliyuncs_uri}/kube-scheduler:${scheduler_version} ${grc_uri}/kube-scheduler:${scheduler_version}
docker tag ${aliyuncs_uri}/kube-proxy:${proxy_version} ${grc_uri}/kube-proxy:${proxy_version}
docker tag ${aliyuncs_uri}/pause:${pause_version} ${grc_uri}/pause:${pause_version}
docker tag ${aliyuncs_uri}/etcd:${etcd_version} ${grc_uri}/etcd:${etcd_version}
docker tag ${aliyuncs_uri}/coredns:${coredns_version} ${grc_uri}/coredns/coredns:${coredns_version}

#remove aliyun images
docker rmi ${aliyuncs_uri}/kube-apiserver:${apiserver_version}
docker rmi ${aliyuncs_uri}/kube-controller-manager:${controller_version}
docker rmi ${aliyuncs_uri}/kube-scheduler:${scheduler_version}
docker rmi ${aliyuncs_uri}/kube-proxy:${proxy_version}
docker rmi ${aliyuncs_uri}/pause:${pause_version}
docker rmi ${aliyuncs_uri}/etcd:${etcd_version}
docker rmi ${aliyuncs_uri}/coredns:${coredns_version}



docker load -i kube-apiserver.tar.gz 
docker load -i kube-controller-manager.tar.gz
docker load -i kube-scheduler.tar.gz
docker load -i kube-proxy.tar.gz
docker load -i pause.tar.gz 
docker load -i etcd.tar.gz
docker load -i coredns.tar.gz

```

### 3.1.3	运行脚本

```
/bin/bash images_install.sh
```



### 3.3.4	查看镜像信息

 docker images

```
REPOSITORY                           TAG       IMAGE ID       CREATED        SIZE
k8s.gcr.io/kube-apiserver            v1.24.0   529072250ccc   24 hours ago   130MB
k8s.gcr.io/kube-proxy                v1.24.0   77b49675beae   24 hours ago   110MB
k8s.gcr.io/kube-controller-manager   v1.24.0   88784fb4ac2f   24 hours ago   119MB
k8s.gcr.io/kube-scheduler            v1.24.0   e3ed7dee73e9   24 hours ago   51MB
k8s.gcr.io/etcd                      3.5.3-0   aebe758cef4c   2 weeks ago    299MB
k8s.gcr.io/pause                     3.7       221177c6082a   7 weeks ago    711kB
k8s.gcr.io/coredns/coredns           v1.8.6    a4ca41631cc7   6 months ago   46.8MB
```



## 3.2	集群初始化

### 3.2.1	生成初始化配置文件

```
kubeadm config print init-defaults > kubeadm.conf
```

*cat kubeadm.conf*

```
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 1.2.3.4
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  name: node
  taints: null
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
```

### 3.2.2改初始化配置文件

- advertiseAddress

  将advertiseAddress: 1.2.3.4修改为advertiseAddress: 192.168.1.211

- criSocket

  将 criSocket: unix:///var/run/containerd/containerd.sock修改为

  criSocket: unix:///run/containerd/containerd.sock

  （通过ps aux | grep docker查看cri的socket文件）

  ```
  ps aux | grep docker
  root     13090  0.3  1.9 1110968 76528 ?       Ssl  21:07   0:11 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
  
  ```

- networking

  新增网络配置

  如果网络插件为calico，则新增podSubnet: 192.168.0.0/16

  如果网络插件为flannel，则新增podSubnet: 10.224.0.0/16

- 查看kubeadm.conf

  *kubeadm.conf*

  ```
  apiVersion: kubeadm.k8s.io/v1beta3
  bootstrapTokens:
  - groups:
    - system:bootstrappers:kubeadm:default-node-token
    token: abcdef.0123456789abcdef
    ttl: 24h0m0s
    usages:
    - signing
    - authentication
  kind: InitConfiguration
  localAPIEndpoint:
    advertiseAddress: 192.168.1.211
    bindPort: 6443
  nodeRegistration:
    criSocket: unix:///run/containerd/containerd.sock
    imagePullPolicy: IfNotPresent
    name: node
    taints: null
  ---
  apiServer:
    timeoutForControlPlane: 4m0s
  apiVersion: kubeadm.k8s.io/v1beta3
  certificatesDir: /etc/kubernetes/pki
  clusterName: kubernetes
  controllerManager: {}
  dns: {}
  etcd:
    local:
      dataDir: /var/lib/etcd
  imageRepository: k8s.gcr.io
  kind: ClusterConfiguration
  kubernetesVersion: 1.24.0
  networking:
    dnsDomain: cluster.local
    podSubnet: 192.168.0.0/16
    serviceSubnet: 10.96.0.0/12
  scheduler: {}
  
  ```

  

### 3.2.3	集群初始化

```
kubeadm init --apiserver-advertise-address 192.168.1.211 \
--kubernetes-version v1.24.0 \
--pod-network-cidr 192.168.0.0/16 \
--cri-socket unix:///run/containerd/containerd.sock
```



## 3.3	加入集群

# 四、网络插件部署

## 4.1	flannel部署

## 4.2	calico部署

# 五、监控组件部署

## 5.1	prometheus部署

## 5.2	grafana部署

# 六、日志服务部署

## 6.1	EFK

