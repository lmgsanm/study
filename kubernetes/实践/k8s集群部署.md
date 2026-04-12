LMGsanm1984



# IP地址

47.253.183.14	172.23.171.172	kube-master

47.253.190.165	172.23.171.173	kube-node





```
cat >> /etc/hosts << EOF
172.23.171.172 kube-master
172.23.171.173 kube-node
EOF
```



### 关闭firewalld

```
for host in kube-master kube-node01 kube-node02 kube-node03 ;do ssh $host "systemctl disable --now firewalld";done
```



### 关闭selinux

```
setenforce 0
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config
reboot
getenforce
```



### 关闭swap分区

```
swapoff -a
cat >> /etc/sysctl.conf << EOF
vm.swappiness = 0
EOF
sysctl -p
cp /etc/fstab{,-bk} && sed -i '/swap/d' /etc/fstab
free -m
```



### 配置时间同步

#### 软件安装

所有服务器都安装

```
yum install -y chrony
systemctl start chronyd.service
systemctl enable chronyd.service
chronyc tracking	#显示当前系统的时钟同步状态，包括时间偏差、频率偏移等
```



### limit句柄配置

```
ulimit -SHn 65535
ulimit -n
cat >> /etc/security/limits.conf  << EOF
* soft nofile 655360
* hard nofile 655360
* soft nproc 655360
* hard nproc 655360
* soft memlock unlimited
* hard memlock unlimited
EOF
for host in kube-master kube-node01 kube-node02 kube-node03 ;do scp /etc/security/limits.conf $host:/etc/security/;done
```

### 系统组件安装

```
yum -y install wget jq psmisc vim net-tools telnet yum-utils device-mapper-persistent-data lvm2 git 
```



### 内核参数优化

```
cat >> /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-iptables = 1
fs.may.detach.mounts = 1
vm.overcommit_memory = 1
vm.panic_on_oom = 0
fs.inotify.max_user_watches = 89100
fs.file-max = 52706963
fs.nr_open = 52706963
net.netfilter.nf_conntrack_max = 2310720
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 327680
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384    
net.ipv4.tcp_timestamps = 0
net.core.somaxconn = 16384
EOF
sysctl -p
```



## 2.4	IPVS部署

```
yum -y install ipvsadm ipset sysstat conntrack libseccomp

modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack

cat > /etc/modules-load.d/ipvs.conf << EOF
ip_vs
ip_vs_lc
ip_vs_wlc
ip_vs_rr
ip_vs_wrr
ip_vs_lblc
ip_vs_lblcr
ip_vs_dh
ip_vs_sh
ip_vs_fo
ip_vs_nq
ip_vs_sed
ip_vs_ftp
ip_vs_sh
nf_conntrack
ip_tables
ip_set
xt_set
ipt_set
ipt_rpfilter
ipt_REJECT
ipip
EOF

systemctl enable --now systemd-modules-load.service
##查看ipvs的模块生效情况
lsmod  | grep ip
```



## docker部署

```
dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum --showduplicates list docker-ce
yum install -y docker-ce-20.10.20-3.el9 docker-ce-cli-20.10.20-3.el9 containerd.io
mkdir -p /etc/docker
cat > /etc/docker/daemon.json  << EOF
{
  "registry-mirrors": [
    "https://docker.elastic.co",
    "https://docker.io",
    "https://gcr.io",
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
    ]
}
EOF

systemctl daemon-reload
systemctl start docker.service
systemctl enable docker.service
systemctl restart docker.service
systemctl status docker.service
```

```
dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum --showduplicates list docker-ce
yum install -y docker-ce-20.10.20-3.el9 docker-ce-cli-20.10.20-3.el9 containerd.io
mkdir -p /etc/docker
cat > /etc/docker/daemon.json  << EOF
{
  "registry-mirrors": [
    "https://docker.elastic.co",
    "https://docker.io",
    "https://gcr.io",
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
    ]
}
EOF

systemctl daemon-reload
systemctl start docker.service
systemctl enable docker.service
systemctl restart docker.service
systemctl status docker.service
```





### cri-docker安装配置

```
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.24/cri-dockerd-0.3.24.amd64.tgz
tar xf cri-dockerd-0.3.24.amd64.tgz
cp cri-dockerd/cri-dockerd /usr/bin/
chmod +x /usr/bin/cri-dockerd

for host in kube-node01 kube-node02 kube-node03; do scp /usr/bin/cri-dockerd $host:/usr/bin/ ; done 

#cri-docker.service配置
cat > /etc/systemd/system/cri-docker.service << EOF
[Unit]
Description=CRI Interface for Docker Application Container Engine
Documentation=https://docs.mirantis.com
After=network-online.target firewalld.service docker.service
Wants=network-online.target
Requires=cri-docker.socket

[Service]
Type=notify
ExecStart=/usr/bin/cri-dockerd --container-runtime-endpoint fd://
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutSec=0
RestartSec=2
Restart=always

# Note that StartLimit* options were moved from "Service" to "Unit" in systemd 229.
# Both the old, and new location are accepted by systemd 229 and up, so using the old location
# to make them work for either version of systemd.
StartLimitBurst=3

# Note that StartLimitInterval was renamed to StartLimitIntervalSec in systemd 230.
# Both the old, and new name are accepted by systemd 230 and up, so using the old name to make
# this option work for either version of systemd.
StartLimitInterval=60s

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not support it.
# Only systemd 226 and above support this option.
TasksMax=infinity
Delegate=yes
KillMode=process

[Install]
WantedBy=multi-user.target

EOF

#cri-docker.socket配置
cat > /etc/systemd/system/cri-docker.socket << EOF
[Unit]
Description=CRI Docker Socket for the API
PartOf=cri-docker.service

[Socket]
ListenStream=%t/cri-dockerd.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF



systemctl daemon-reload
systemctl enable --now cri-docker.service
systemctl enable --now cri-docker.socket

systemctl restart cri-docker.service
systemctl restart cri-docker.socket
systemctl status cri-docker.service
systemctl status cri-docker.socket
```



```
cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.29/rpm/repodata/repomd.xml.key
EOF
yum clean all
yum --showduplicates list kubelet kubeadm kubectl
setenforce 0
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet && systemctl restart kubelet


```



```
kubeadm config images pull --cri-socket unix:///var/run/cri-dockerd.sock 


kubeadm init \
  --apiserver-advertise-address=172.23.171.172 \
  --kubernetes-version v1.29.15 \
  --service-cidr=10.96.0.0/12 \
  --pod-network-cidr=192.168.0.0/16 \
  --cri-socket unix:///var/run/cri-dockerd.sock 
  
  
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.23.171.172:6443 --token 7dkr1r.811cbqr72piyrfea \
        --discovery-token-ca-cert-hash sha256:3be3b928993f40f9c82691cfa19a18ffceaef6662e8cdffc458484417b3590e8

```



```
kubeadm join 172.23.171.172:6443 --token 7dkr1r.811cbqr72piyrfea \
        --discovery-token-ca-cert-hash sha256:3be3b928993f40f9c82691cfa19a18ffceaef6662e8cdffc458484417b3590e8 \
        --cri-socket unix:///var/run/cri-dockerd.sock 
```



```
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.7/manifests/calico.yaml


wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.2/components.yaml
#修改components.yaml，添加 - --kubelet-insecure-tls禁用证书认证
    spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=10250
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls

kubectl apply -f components.yaml


[root@kube-master soft]# kubectl get pod -A
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-545cb85dc7-x759v   1/1     Running   0          7m52s
kube-system   calico-node-4dg2m                          1/1     Running   0          7m52s
kube-system   calico-node-c4fp6                          1/1     Running   0          7m52s
kube-system   coredns-76f75df574-spjzm                   1/1     Running   0          9m42s
kube-system   coredns-76f75df574-tksk9                   1/1     Running   0          9m42s
kube-system   etcd-kube-master                           1/1     Running   0          9m57s
kube-system   kube-apiserver-kube-master                 1/1     Running   0          9m57s
kube-system   kube-controller-manager-kube-master        1/1     Running   0          9m56s
kube-system   kube-proxy-lhddl                           1/1     Running   0          9m42s
kube-system   kube-proxy-lqbrj                           1/1     Running   0          9m1s
kube-system   kube-scheduler-kube-master                 1/1     Running   0          9m57s
kube-system   metrics-server-596474b58-xlxhk             1/1     Running   0          43s


```

## 集群启动IPVS

```
kubectl edit cm kube-proxy -n kube-system
#找到KubeProxyConfiguration，将mod为空修改为ipvs，如下
    kind: KubeProxyConfiguration
    logging:
      flushFrequency: 0
      options:
        json:
          infoBufferSize: "0"
      verbosity: 0
    metricsBindAddress: ""
    mode: "ipvs"
    nftables:
      masqueradeAll: false
      masqueradeBit: null
      minSyncPeriod: 0s
      syncPeriod: 0s
    nodePortAddresses: null
 
 #逐个启动kube-proxy
 kubectl delete pod kube-proxy-lhddl -n kube-system
 kubectl delete pod kube-proxy-lqbrj -n kube-system
 #查看Log日志，日志输出显示"Using ipvs Proxier"，即表示成功启用
[root@kube-master soft]# kubectl logs kube-proxy-nwqxk -n kube-system
I0411 01:51:21.767882       1 server.go:1050] "Successfully retrieved node IP(s)" IPs=["172.23.171.172"]
I0411 01:51:21.772459       1 conntrack.go:58] "Setting nf_conntrack_max" nfConntrackMax=262144
I0411 01:51:21.795536       1 server.go:652] "kube-proxy running in dual-stack mode" primary ipFamily="IPv4"
I0411 01:51:21.799815       1 server_others.go:236] "Using ipvs Proxier"
I0411 01:51:21.802287       1 server_others.go:512] "Detect-local-mode set to ClusterCIDR, but no cluster CIDR for family" ipFamily="IPv6"
I0411 01:51:21.802308       1 server_others.go:529] "Defaulting to no-op detect-local"
I0411 01:51:21.802564       1 proxier.go:409] "IPVS scheduler not specified, use rr by default"
I0411 01:51:21.802723       1 proxier.go:409] "IPVS scheduler not specified, use rr by default"
I0411 01:51:21.802757       1 ipset.go:116] "Ipset name truncated" ipSetName="KUBE-6-LOAD-BALANCER-SOURCE-CIDR" truncatedName="KUBE-6-LOAD-BALANCER-SOURCE-CID"
I0411 01:51:21.802768       1 ipset.go:116] "Ipset name truncated" ipSetName="KUBE-6-NODE-PORT-LOCAL-SCTP-HASH" truncatedName="KUBE-6-NODE-PORT-LOCAL-SCTP-HAS"
I0411 01:51:21.802832       1 server.go:865] "Version info" version="v1.29.15"
I0411 01:51:21.802846       1 server.go:867] "Golang settings" GOGC="" GOMAXPROCS="" GOTRACEBACK=""
I0411 01:51:21.803630       1 config.go:188] "Starting service config controller"
I0411 01:51:21.803674       1 shared_informer.go:311] Waiting for caches to sync for service config
I0411 01:51:21.803640       1 config.go:315] "Starting node config controller"
I0411 01:51:21.803713       1 shared_informer.go:311] Waiting for caches to sync for node config
I0411 01:51:21.804405       1 config.go:97] "Starting endpoint slice config controller"
I0411 01:51:21.804432       1 shared_informer.go:311] Waiting for caches to sync for endpoint slice config
I0411 01:51:21.904399       1 shared_informer.go:318] Caches are synced for service config
I0411 01:51:21.904488       1 shared_informer.go:318] Caches are synced for node config
I0411 01:51:21.904584       1 shared_informer.go:318] Caches are synced for endpoint slice config


```



# 附录

镜像源

除了 docker.io 这里每一个源站, 内容都是不同的, 不要把 docker.io 之外的站点配置给 registry-mirrors

| 源站               | 替换为                | 备注                                                         |
| ------------------ | --------------------- | ------------------------------------------------------------ |
| docker.elastic.co  | elastic.m.daocloud.io |                                                              |
| docker.io          | docker.m.daocloud.io  |                                                              |
| dhi.io             | dhi.m.daocloud.io     |                                                              |
| gcr.io             | gcr.m.daocloud.io     |                                                              |
| ghcr.io            | ghcr.m.daocloud.io    |                                                              |
| k8s.gcr.io         | k8s-gcr.m.daocloud.io | k8s.gcr.io 已被迁移到 registry.k8s.io                        |
| registry.k8s.io    | k8s.m.daocloud.io     |                                                              |
| mcr.microsoft.com  | mcr.m.daocloud.io     |                                                              |
| nvcr.io            | nvcr.m.daocloud.io    |                                                              |
| quay.io            | quay.m.daocloud.io    |                                                              |
| registry.ollama.ai | ollama.m.daocloud.io  | 实验内测中，[使用方法](https://github.com/DaoCloud/public-image-mirror#加速-ollama--deepseek) |