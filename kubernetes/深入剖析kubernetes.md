# 第一部分  Kubernetes基础

## 第1章	背景回顾：云原生大事记

## 第2章	容器技术基础

## 第3章	Kubernetes设计与架构

## 第4章	Kubernetes集群搭建与配置

### 4.1	Kubernetes部署利器：kubeadm

#### 部署架构

![image-20220504101620205](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220504101620205.png)

- 192.168.1.200

​		部署harbor,nginx,ansible

- 192.168.1.211

​		部署kubeadm及k8s master

- 192.168.1.212

​		node01

- 192.168.1.213

​		node02

#### 部署过程

##### hosts文件配置



##### yum源配置

##### 软件安装

##### 软件配置

##### kubeadm初始化

##### kubeadm join

##### 网络插件安装

`systemctl enable kubelet`

`kubeadm config images list`

![image-20220504115457190](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220504115457190.png)

```
kubeadm init --image-repository registry.aliyuncs.com/google_containers --apiserver-advertise-address=192.168.1.211 --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=all
```

```
kubeadm reset --v=5

```

[root@master ~]# `docker info`

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
 Images: 7
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
 CPUs: 1
 Total Memory: 3.701GiB
 Name: master
 ID: 3KSF:UINS:NG7B:L35G:7GXD:W77Q:I67S:5CH3:ASAM:GLTL:7S3I:NQJ5
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

![image-20220504154749292](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220504154749292.png)

NM_CONTROLLED=no

![image-20220504154052393](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220504154052393.png)



```
kubeadm init --image-repository registry.aliyuncs.com/google_containers --apiserver-advertise-address=192.168.1.211 --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=all
W0504 16:08:54.163055    5754 version.go:103] could not fetch a Kubernetes version from the internet: unable to get URL "https://dl.k8s.io/release/stable-1.txt": Get "https://dl.k8s.io/release/stable-1.txt": dial tcp: lookup dl.k8s.io on [::1]:53: read udp [::1]:39881->[::1]:53: read: connection refused
W0504 16:08:54.163090    5754 version.go:104] falling back to the local client version: v1.24.0
[init] Using Kubernetes version: v1.24.0
[preflight] Running pre-flight checks
        [WARNING NumCPU]: the number of available CPUs 1 is less than the required 2
        [WARNING CRI]: container runtime is not running: output: time="2022-05-04T16:08:56+08:00" level=fatal msg="connect: connect endpoint 'unix:///var/run/containerd/containerd.sock', make sure you are running as root and the endpoint has been started: context deadline exceeded"
, error: exit status 1
        [WARNING FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables does not exist
        [WARNING FileContent--proc-sys-net-ipv4-ip_forward]: /proc/sys/net/ipv4/ip_forward contents are not set to 1
```



# 第二部分 Kubernetes核心原理

## 第5章	Kubernetes编排原理

## 第6章	Kubernetes存储原理

## 第7章	Kubernetes网络原理

## 第8章	Kubernetes调度与资源管理

## 第9章	容器运行时

## 第10章	Kubernetes监控与日志

# 第三部分 Kubernetes实践进阶

## 第11章	Kubernetes应用管理进阶