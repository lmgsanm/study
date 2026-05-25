***执行命令或脚本时未带主机名信息表示该命令或脚本需要在所有节点上执行***

# 一、部署规划



## 部署架构图

![image-20260524122654744](kuadm%E5%AE%89%E8%A3%85v1.36.0(docker).assets/image-20260524122654744.png)

## 服务器信息

| IP地址       | 主机名   | 主机配置(cpu+内存) | 主机配置(硬盘)  |
| ------------ | -------- | ------------------ | --------------- |
| 192.168.1.11 | master01 | 2C2G               | 50G+10G+10G+10G |
| 192.168.1.21 | node01   | 4C4G               | 50G+10G+10G+10G |
| 192.168.1.22 | nod02    | 4C4G               | 50G+10G+10G+10G |
| 192.168.1.23 | nod03    | 4C4G               | 50G+10G+10G+10G |

## 操作系统信息

### 操作系统版本

Rocky Linux release 10.0 (Red Quartz)

### 内核版本

6.12.0-55.12.1.el10_0.x86_64

## 网络规划

### 宿主机网络

192.168.1.0/24

### 集群service网络

10.96.0.0/12

### 集群pod网络

*因规划使用calico网络插件，该插件的默认网络地址为192.168.0.0/16*

  192.168.0.0/16



# 二、服务器初始化

## 主机名配置

hostnamectl set-hostname  + 主机名

## hosts配置

```shell
cat >> /etc/hosts << EOF
192.168.1.11 master01
192.168.1.21 node01
192.168.1.22 node02
192.168.1.23 node03
EOF
```

## 主机免密认证配置

*配置master01使用ssh远程访问所有节点的免密配置*

### master01上生成密钥

```shell
[root@master01 ~]# ssh-keygen
Generating public/private ed25519 key pair.
Enter file in which to save the key (/root/.ssh/id_ed25519):
Enter passphrase for "/root/.ssh/id_ed25519" (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_ed25519
Your public key has been saved in /root/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:OZWZUM1L1h08hkpPdPZ/r96SNkLqfa5xhUKX/eENwvk root@master01
The key's randomart image is:
+--[ED25519 256]--+
|        ...o.oo=.|
|         . *=++*o|
|          *oO.=.+|
|         o o.=.o=|
|        S   . E.*|
|         .  .. .o|
|           o. ...|
|          ...o*o |
|         .. oB+o.|
+----[SHA256]-----+

```

### 拷贝master01公钥至其它节点

```shell
[root@master01 ~]# ssh-copy-id node01
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/id_ed25519.pub"
The authenticity of host 'node01 (192.168.1.21)' can't be established.
ED25519 key fingerprint is SHA256:cnXHRhd+kX3Gi2ZmUEoLtj7jTBVg++/G6V3WeJE5tbU.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
root@node01's password:

Number of key(s) added: 1

Now try logging into the machine, with: "ssh 'node01'"
and check to make sure that only the key(s) you wanted were added.

[root@master01 ~]# ssh-copy-id node02
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/id_ed25519.pub"
The authenticity of host 'node02 (192.168.1.22)' can't be established.
ED25519 key fingerprint is SHA256:VLK/SrOAFFYNwM/dQcTqrOG/JrLIlZv4Ug+abAroaKw.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
root@node02's password:

Number of key(s) added: 1

Now try logging into the machine, with: "ssh 'node02'"
and check to make sure that only the key(s) you wanted were added.

[root@master01 ~]# ssh-copy-id node03
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/id_ed25519.pub"
The authenticity of host 'node03 (192.168.1.23)' can't be established.
ED25519 key fingerprint is SHA256:9OPXxBMxxzMVZZzLfe752YVF2bH7h5V3D4ag5KgtMwg.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
root@node03's password:

Number of key(s) added: 1

Now try logging into the machine, with: "ssh 'node03'"
and check to make sure that only the key(s) you wanted were added.

[root@master01 ~]# ssh-copy-id master01
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/id_ed25519.pub"
The authenticity of host 'master01 (192.168.1.11)' can't be established.
ED25519 key fingerprint is SHA256:HZe5dRaMEB53lg+pfGFdq2lPT55MNwDUByrFDq8PvHw.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
root@master01's password:

Number of key(s) added: 1

Now try logging into the machine, with: "ssh 'master01'"
and check to make sure that only the key(s) you wanted were added.


```

## 关闭swap分区

执行命令：

```bash
swapoff -a
cat >> /etc/sysctl.conf << EOF
vm.swappiness = 0
EOF
sysctl -p
cp /etc/fstab{,-bk} && sed -i '/swap/d' /etc/fstab
free -m
```

输出结果：

```
               total        used        free      shared  buff/cache   available
Mem:            1705         717         631           8         505         988
Swap:              0           0           0

```

## 关闭firewalld防火墙

```shell
systemctl disable --now firewalld
```

## limit句柄配置

```shell
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
```



## 关闭selinux安全配置

```shell
setenforce 0
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config
getenforce
```

## YUM源配置

*配置阿里源*

### 基础YUM源配置

#### 替换为阿里云yum源

```shell
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.aliyun.com/rockylinux|g' \
    -i.bak \
    /etc/yum.repos.d/rocky-*.repo


```

#### 刷新缓存

```
dnf makecache
```

### EPEL源配置

#### 安装官方 epel-release 包

```
dnf install -y epel-release
```

#### 替换为阿里云 EPEL 源

```shell
sed -e 's|^metalink=|#metalink=|g' \
-e 's|^#baseurl=https://download.example/pub|baseurl=https://mirrors.aliyun.com|g' \
-i.bak /etc/yum.repos.d/epel*.repo
```

#### 刷新缓存

```shell
dnf clean all && dnf makecache
```

## 统必需组件安装

```shell
yum -y install wget jq psmisc vim net-tools telnet yum-utils device-mapper-persistent-data lvm2 git nftables iptables iptables-nft ipvsadm
```

## 时间同步配置

*使用master01作为时间同步服务器，其它节点时间从master01上同步*

### 软件安装

```shell
yum install -y chrony
```



### 时间服务器配置

*在master01上进行操作*

```shell
[root@master01 ~]# cat > /etc/chrony.conf << EOF
server ntp1.aliyun.com iburst
server ntp2.aliyun.com iburst
server ntp3.aliyun.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 192.168.1.0/24
logdir /var/log/chrony
EOF
systemctl start chronyd.service
systemctl enable chronyd.service

```



### 客户端配置

*除master01之外的其它节点上操作，配置时间同步*

```shell
 cat > /etc/chrony.conf << EOF
server 192.168.1.11 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF
systemctl start chronyd.service
systemctl enable chronyd.service
```



### 时间同步校验

```shell
[root@master01 ~]# chronyc sources -v

  .-- Source mode  '^' = server, '=' = peer, '#' = local clock.
 / .- Source state '*' = current best, '+' = combined, '-' = not combined,
| /             'x' = may be in error, '~' = too variable, '?' = unusable.
||                                                 .- xxxx [ yyyy ] +/- zzzz
||      Reachability register (octal) -.           |  xxxx = adjusted offset,
||      Log2(Polling interval) --.      |          |  yyyy = measured offset,
||                                \     |          |  zzzz = estimated error.
||                                 |    |           \
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^- ntp.wdc2.us.leaseweb.net      3   6   377    16   +258us[ +258us] +/-  130ms
^* 139.199.215.251               2   6   373    18  -1825us[-2546us] +/-   34ms
^- tick.ntp.infomaniak.ch        1   6   377    17  +5571us[+5571us] +/-  113ms
[root@master01 ~]# chronyc tracking
Reference ID    : 8BC7D7FB (139.199.215.251)
Stratum         : 3
Ref time (UTC)  : Sun May 24 09:26:56 2026
System time     : 0.000206037 seconds slow of NTP time
Last offset     : -0.000721025 seconds
RMS offset      : 0.001510480 seconds
Frequency       : 12.192 ppm slow
Residual freq   : +2.782 ppm
Skew            : 0.740 ppm
Root delay      : 0.015575536 seconds
Root dispersion : 0.026807971 seconds
Update interval : 64.5 seconds
Leap status     : Normal
[root@master01 ~]# chronyc makestep
200 OK
[root@master01 ~]# date
Sun May 24 05:27:36 PM CST 2026

```

## 内核参数配置

```abash
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

# 三、基本组件部署

## dockerd部署

### 添加docker镜像源

```bash
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

### 查看docker版本

```bash
yum --showduplicates list docker-ce 
```

结果如下：

```tex
Docker CE Stable - x86_64                                                                                                             73 kB/s |  22 kB     00:00
Available Packages
docker-ce.x86_64                                                           3:27.4.0-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:27.4.1-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:27.5.0-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:27.5.1-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.0.0-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.0.1-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.0.2-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.0.3-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.0.4-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.1.0-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.1.1-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.2.0-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.2.1-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.2.2-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.3.0-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.3.1-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.3.2-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.3.3-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.4.0-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.5.0-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.5.1-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:28.5.2-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.0.0-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.0.1-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.0.2-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.0.3-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.0.4-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.1.0-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.1.1-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.1.2-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.1.3-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.1.4-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.1.5-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.2.0-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.2.1-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.3.0-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.3.1-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.4.0-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.4.1-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.4.2-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.4.2-2.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.4.3-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.5.0-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.5.1-1.el10                                                           docker-ce-stable
docker-ce.x86_64                                                           3:29.5.2-1.el10                                                           docker-ce-stable
```



### 安装指定版本

打开https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.36.md查看兼容的docker版本

```
Removed
github.com/armon/circbuf: 5111143
github.com/bufbuild/protovalidate-go: v0.9.1
github.com/docker/docker: v28.2.2+incompatible
github.com/gregjones/httpcache: 901d907
github.com/grpc-ecosystem/go-grpc-prometheus: v1.2.0
github.com/karrick/godirwalk: v1.17.0
github.com/libopenstorage/openstorage: v1.0.0
github.com/moby/sys/atomicwriter: v0.1.0
github.com/mohae/deepcopy: c48cc78
github.com/morikuni/aec: v1.0.0
github.com/mrunalp/fileutils: v0.5.1
github.com/zeebo/errs: v1.4.0
go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp: v1.27.0
gotest.tools/v3: v3.0.2
```

如上内容所示，docker v28.2.2以上版本均可兼容，此次安装最新版本：29.5.2-1.el10

```bash
yum install -y docker-ce-29.5.2-1.el10 docker-ce-cli-29.5.2-1.el10 containerd.io
```

安装结果如下：

```tex
Installed:
  containerd.io-2.2.4-1.el10.x86_64               docker-buildx-plugin-0.34.0-1.el10.x86_64  docker-ce-3:29.5.2-1.el10.x86_64  docker-ce-cli-1:29.5.2-1.el10.x86_64
  docker-ce-rootless-extras-29.5.2-1.el10.x86_64  docker-compose-plugin-5.1.4-1.el10.x86_64

```



### 配置deamon.json文件

```bash
mkdir -p /etc/docker
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
    ]
}
EOF
```

### docker服务启停

```bash
systemctl daemon-reload
systemctl start docker.service
systemctl enable docker.service
systemctl restart docker.service
systemctl status docker.service
```

docker运行状态如下：

```tex
Created symlink '/etc/systemd/system/multi-user.target.wants/docker.service' → '/usr/lib/systemd/system/docker.service'.
● docker.service - Docker Application Container Engine
     Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; preset: disabled)
     Active: active (running) since Sun 2026-05-24 18:09:51 CST; 25ms ago
 Invocation: 901194711c6a4d6c8c569165557f9b23
TriggeredBy: ● docker.socket
       Docs: https://docs.docker.com
   Main PID: 5134 (dockerd)
      Tasks: 9
     Memory: 27.2M (peak: 29.1M)
        CPU: 393ms
     CGroup: /system.slice/docker.service
             └─5134 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock

May 24 18:09:51 master01 dockerd[5134]: time="2026-05-24T18:09:51.144905570+08:00" level=info msg="Restoring containers: start."
May 24 18:09:51 master01 dockerd[5134]: time="2026-05-24T18:09:51.160443792+08:00" level=info msg="Deleting nftables IPv4 rules" error="exit status 1" output="Error>
May 24 18:09:51 master01 dockerd[5134]: time="2026-05-24T18:09:51.171218976+08:00" level=info msg="Deleting nftables IPv6 rules" error="exit status 1" output="Error>
May 24 18:09:51 master01 dockerd[5134]: time="2026-05-24T18:09:51.639117800+08:00" level=info msg="Loading containers: done."
May 24 18:09:51 master01 dockerd[5134]: time="2026-05-24T18:09:51.656237126+08:00" level=info msg="Docker daemon" commit=568f755 containerd-snapshotter=false storag>
May 24 18:09:51 master01 dockerd[5134]: time="2026-05-24T18:09:51.656338287+08:00" level=info msg="Initializing buildkit"
May 24 18:09:51 master01 dockerd[5134]: time="2026-05-24T18:09:51.681942555+08:00" level=info msg="Completed buildkit initialization"
May 24 18:09:51 master01 dockerd[5134]: time="2026-05-24T18:09:51.687546954+08:00" level=info msg="Daemon has completed initialization"
May 24 18:09:51 master01 dockerd[5134]: time="2026-05-24T18:09:51.688770423+08:00" level=info msg="API listen on /run/docker.sock"
May 24 18:09:51 master01 systemd[1]: Started docker.service - Docker Application Container Engine.
```

## cri-docker部署

官网：https://mirantis.github.io/cri-dockerd/

github：https://github.com/Mirantis/cri-dockerd

### 软件下载

*安装最新版本*

```bash
[root@master01 ~]# wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.4.3/cri-dockerd-0.4.3.amd64.tgz
```



### 软件安装

```bash
[root@master01 ~]# tar xzf cri-dockerd-0.4.3.amd64.tgz
[root@master01 ~]# cp cri-dockerd/cri-dockerd /usr/bin
[root@master01 ~]# for host in node01 node02 node03;do scp /usr/bin/cri-dockerd ${host}:/usr/bin/;done
```



### 服务配置

#### cri-docker.service

```bash
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

```

#### cri-docker.socket

```bash
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
```



### 服务启停

```bash
systemctl daemon-reload
systemctl enable --now cri-docker.service
systemctl enable --now cri-docker.socket
systemctl restart cri-docker.service
systemctl restart cri-docker.socket
```

### 服务状态验证

#### cri-docker.service状态

```bash
systemctl status cri-docker.service
```

结果如下：

```tex
● cri-docker.service - CRI Interface for Docker Application Container Engine
     Loaded: loaded (/etc/systemd/system/cri-docker.service; enabled; preset: disabled)
     Active: active (running) since Sun 2026-05-24 18:37:23 CST; 20s ago
 Invocation: 762171bb117e49af8270c886deda06de
TriggeredBy: ● cri-docker.socket
       Docs: https://docs.mirantis.com
   Main PID: 5833 (cri-dockerd)
      Tasks: 7
     Memory: 12.3M (peak: 12.9M)
        CPU: 46ms
     CGroup: /system.slice/cri-docker.service
             └─5833 /usr/bin/cri-dockerd --container-runtime-endpoint fd://

May 24 18:37:23 master01 cri-dockerd[5833]: time="2026-05-24T18:37:23+08:00" level=info msg="Hairpin mode is set to none"
May 24 18:37:23 master01 cri-dockerd[5833]: time="2026-05-24T18:37:23+08:00" level=info msg="The binary conntrack is not installed, this can cause failures in netwo>
May 24 18:37:23 master01 cri-dockerd[5833]: time="2026-05-24T18:37:23+08:00" level=info msg="The binary conntrack is not installed, this can cause failures in netwo>
May 24 18:37:23 master01 cri-dockerd[5833]: time="2026-05-24T18:37:23+08:00" level=info msg="Loaded network plugin cni"
May 24 18:37:23 master01 cri-dockerd[5833]: time="2026-05-24T18:37:23+08:00" level=info msg="Docker cri networking managed by network plugin cni"
May 24 18:37:23 master01 cri-dockerd[5833]: time="2026-05-24T18:37:23+08:00" level=info msg="Setting cgroupDriver systemd"
May 24 18:37:23 master01 cri-dockerd[5833]: time="2026-05-24T18:37:23+08:00" level=info msg="Docker cri received runtime config &RuntimeConfig{NetworkConfig:&Networ>
May 24 18:37:23 master01 cri-dockerd[5833]: time="2026-05-24T18:37:23+08:00" level=info msg="Starting the GRPC backend for the Docker CRI interface."
May 24 18:37:23 master01 cri-dockerd[5833]: time="2026-05-24T18:37:23+08:00" level=info msg="Start cri-dockerd grpc backend"
May 24 18:37:23 master01 systemd[1]: Started cri-docker.service - CRI Interface for Docker Application Container Engine.

```



#### cri-docker.socket状态

```bash
systemctl status cri-docker.socket
```

结果如下：

```tex
● cri-docker.socket - CRI Docker Socket for the API
     Loaded: loaded (/etc/systemd/system/cri-docker.socket; enabled; preset: disabled)
     Active: active (running) since Sun 2026-05-24 18:37:23 CST; 27s ago
 Invocation: 0f673f6205314890bd1c991d57efda88
   Triggers: ● cri-docker.service
     Listen: /run/cri-dockerd.sock (Stream)
      Tasks: 0 (limit: 10664)
     Memory: 0B (peak: 604K)
        CPU: 2ms
     CGroup: /system.slice/cri-docker.socket

May 24 18:37:23 master01 systemd[1]: Starting cri-docker.socket - CRI Docker Socket for the API...
May 24 18:37:23 master01 systemd[1]: Listening on cri-docker.socket - CRI Docker Socket for the API.

```

### 服务进程查看

```bash
ps aux | grep docker | grep -v grep
```

结果如下：

```bash
root        5134  0.0  5.1 1948344 89468 ?       Ssl  18:09   0:00 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
root        5833  0.0  2.6 1277632 45624 ?       Ssl  18:37   0:00 /usr/bin/cri-dockerd --container-runtime-endpoint fd://

```

## ipvs模块加载（将来被弃用）

### 软件安装

```bash
yum -y install ipvsadm ipset sysstat conntrack libseccomp
```

安装结果如下：

```bash
Installed:
  conntrack-tools-1.4.8-3.el10.x86_64    ipvsadm-1.31-15.el10.x86_64          libnetfilter_cthelper-1.0.1-1.el10.x86_64 libnetfilter_cttimeout-1.0.0-27.el10.x86_64
  libnetfilter_queue-1.0.5-9.el10.x86_64 lm_sensors-libs-3.6.0-20.el10.x86_64 pcp-conf-6.3.7-5.el10.x86_64              pcp-libs-6.3.7-5.el10.x86_64
  sysstat-12.7.6-2.el10.x86_64
```



### 模块加载

```bash
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack
```



### ipvs.conf配置

```bash
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
```



### 服务启动配置

```bash
systemctl enable --now systemd-modules-load.service
```

结果如下

```tex
● systemd-modules-load.service - Load Kernel Modules
     Loaded: loaded (/usr/lib/systemd/system/systemd-modules-load.service; static)
     Active: active (exited) since Sun 2026-05-24 12:08:43 CST; 6h ago
 Invocation: c0bf7ac036714bb9b15d9c18b4832790
       Docs: man:systemd-modules-load.service(8)
             man:modules-load.d(5)
   Main PID: 643 (code=exited, status=0/SUCCESS)
   Mem peak: 1.5M
        CPU: 12ms

```



### 查看模块生效情况

```bash
lsmod  | grep ip
```

结果如下：

```tex
ip_vs_sh               12288  0
ip_vs_wrr              12288  0
ip_vs_rr               12288  0
ip_vs                 249856  6 ip_vs_rr,ip_vs_sh,ip_vs_wrr
nft_fib_ipv4           12288  1 nft_fib_inet
nft_fib_ipv6           12288  1 nft_fib_inet
nft_fib                12288  3 nft_fib_ipv6,nft_fib_ipv4,nft_fib_inet
nf_reject_ipv4         16384  1 nft_reject_inet
nf_reject_ipv6         20480  1 nft_reject_inet
nf_conntrack          204800  5 xt_conntrack,nf_nat,nft_ct,xt_MASQUERADE,ip_vs
nf_defrag_ipv6         24576  2 nf_conntrack,ip_vs
nf_defrag_ipv4         12288  1 nf_conntrack
ip_set                 69632  1 xt_set
nf_tables             393216  64 nft_ct,nft_compat,nft_reject_inet,nft_fib_ipv6,nft_fib_ipv4,nft_chain_nat,nft_reject,nft_fib,nft_fib_inet
dm_multipath           53248  0
nfnetlink              20480  5 nft_compat,nf_tables,ip_set
dm_mod                245760  8 dm_multipath,dm_log,dm_mirror

```

## br_netfilter模块加载

```bash
modprobe br_netfilter
echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf
sysctl -p
```



# 四、kubernetes部署

*部署前重启所有节点服务器*

## kubernetes安装源配置

```bash
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.36/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.36/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
```



## 组件安装

```bash
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
```

安装结果如下：

```tex
Installed:
  kubeadm-1.36.1-150500.1.1.x86_64       kubectl-1.36.1-150500.1.1.x86_64       kubelet-1.36.1-150500.1.1.x86_64       kubernetes-cni-1.9.1-150500.1.1.x86_64

```

## 组件启动

```bash
systemctl enable --now kubelet && systemctl restart kubelet
```

## 拉取pause:3.10镜像

*镜像为registry.k8s.io/pause:3.10*

```bash
docker pull registry.aliyuncs.com/google_containers/pause:3.10
docker tag registry.aliyuncs.com/google_containers/pause:3.10 registry.k8s.io/pause:3.10
```





## 初始化master节点

### kubeadm init

```bash
kubeadm init \
  --apiserver-advertise-address=192.168.1.11 \
  --image-repository registry.aliyuncs.com/google_containers \
  --kubernetes-version v1.36.1 \
  --service-cidr=10.96.0.0/12 \
  --pod-network-cidr=172.16.0.0/12 \
  --cri-socket unix:///var/run/cri-dockerd.sock
```

运行结果如下：

```tex
[root@master01 setup]# kubeadm init \
  --apiserver-advertise-address=192.168.1.11 \
  --image-repository registry.aliyuncs.com/google_containers \
  --kubernetes-version v1.36.1 \
  --service-cidr=10.96.0.0/12 \
  --pod-network-cidr=172.16.0.0/12 \
  --cri-socket unix:///var/run/cri-dockerd.sock
[init] Using Kubernetes version: v1.36.1
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action beforehand using 'kubeadm config images pull'
W0525 12:27:43.109472  141621 checks.go:907] detected that the sandbox image "registry.k8s.io/pause:3.10" of the container runtime is inconsistent with that used by kubeadm. It is recommended to use "registry.aliyuncs.com/google_containers/pause:3.10.2" as the CRI sandbox image.
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local master01] and IPs [10.96.0.1 192.168.1.11]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [localhost master01] and IPs [192.168.1.11 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [localhost master01] and IPs [192.168.1.11 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "super-admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/instance-config.yaml"
[patches] Applied patch of type "application/strategic-merge-patch+json" to target "kubeletconfiguration"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests"
[kubelet-check] Waiting for a healthy kubelet at http://127.0.0.1:10248/healthz. This can take up to 4m0s
[kubelet-check] The kubelet is healthy after 1.673285ms
[control-plane-check] Waiting for healthy control plane components. This can take up to 4m0s
[control-plane-check] Checking kube-apiserver at https://192.168.1.11:6443/livez
[control-plane-check] Checking kube-controller-manager at https://127.0.0.1:10257/healthz
[control-plane-check] Checking kube-scheduler at https://127.0.0.1:10259/livez
[control-plane-check] kube-controller-manager is healthy after 12.649408ms
[control-plane-check] kube-scheduler is healthy after 115.710942ms
[control-plane-check] kube-apiserver is healthy after 2.50211004s
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node master01 as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
[mark-control-plane] Marking the node master01 as control-plane by adding the taints [node-role.kubernetes.io/control-plane:NoSchedule]
[bootstrap-token] Using token: me8jdq.b4grua1ypaztv5aq
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Configured RBAC rules to allow the API server kubelet client certificate to access the kubelet API
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

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

kubeadm join 192.168.1.11:6443 --token me8jdq.b4grua1ypaztv5aq \
        --discovery-token-ca-cert-hash sha256:6a867276f3dd78d079afb132ab569a75cec102b444c4cd1c7d4cd8a81578b608

```

### master配置

```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

### 查看节点状态

```bash
kubectl get nodes
```

显示结果如下：

```tex
NAME       STATUS     ROLES           AGE    VERSION
master01   NotReady   control-plane   108s   v1.36.1
```



## 初始化node节点

*node节点逐台初始化*

```
kubeadm join 192.168.1.11:6443 --token me8jdq.b4grua1ypaztv5aq \
        --discovery-token-ca-cert-hash sha256:6a867276f3dd78d079afb132ab569a75cec102b444c4cd1c7d4cd8a81578b608 \
        --cri-socket unix:///var/run/cri-dockerd.sock
```

## 查看集群节点状态

```bash
kubectl get nodes
```

结果如下：

```bash
NAME       STATUS     ROLES           AGE     VERSION
master01   NotReady   control-plane   5m15s   v1.36.1
node01     NotReady   <none>          25s     v1.36.1
node02     NotReady   <none>          9s      v1.36.1
node03     NotReady   <none>          6s      v1.36.1
```

## 查看kube-system服务状态

```bash
kubectl get pod -n kube-system
```

结果如下：

```tex
NAME                               READY   STATUS    RESTARTS   AGE
coredns-6b5f954497-4k9tw           0/1     Pending   0          7m3s
coredns-6b5f954497-vqfxm           0/1     Pending   0          7m3s
etcd-master01                      1/1     Running   0          7m9s
kube-apiserver-master01            1/1     Running   0          7m8s
kube-controller-manager-master01   1/1     Running   0          7m8s
kube-proxy-7wlzr                   1/1     Running   0          2m22s
kube-proxy-kh2fg                   1/1     Running   0          7m4s
kube-proxy-z6d8z                   1/1     Running   0          2m6s
kube-proxy-zhmf7                   1/1     Running   0          2m3s
kube-scheduler-master01            1/1     Running   0          7m9s
```

[^core-dns状态异常的原因是没有安装网络插件]: 

## 开启IPVS转发（该模式将被弃用）

### 修改configmap

kubectl edit  configmap -n kube-system  kube-proxy

#将mode字段的空值设置为ipvs后逐个重启kube-proxy

### 重启kube-proxy

```bash
kubectl get pods -n kube-system | grep kube-proxy
kube-proxy-7wlzr                          1/1     Running            1 (155m ago)    15h
kube-proxy-kh2fg                          1/1     Running            1 (155m ago)    15h
kube-proxy-z6d8z                          1/1     Running            1 (155m ago)    15h
kube-proxy-zhmf7                          1/1     Running            1 (155m ago)    15h
```

```bas
kubectl delete pod -n kube-system kube-proxy-7wlzr
kubectl delete pod -n kube-system kube-proxy-kh2fg
kubectl delete pod -n kube-system kube-proxy-z6d8z
kubectl delete pod -n kube-system kube-proxy-zhmf7
```

或使用如下命令重启

```bash
kubectl delete pod -n kube-system -l k8s-app=kube-proxy
```



```bash
kubectl get pods -n kube-system | grep kube-proxy
kube-proxy-gzklj                          1/1     Running            0              44s
kube-proxy-jjj2x                          1/1     Running            0              38s
kube-proxy-nbf2r                          1/1     Running            0              31s
kube-proxy-wdprt                          1/1     Running            0              84s
```



```bash
[root@master01 ~]# kubectl logs -n kube-system pod/kube-proxy-gzklj
I0525 03:22:43.410133       1 shared_informer.go:402] "Waiting for caches to sync"
I0525 03:22:43.511679       1 shared_informer.go:409] "Caches are synced"
I0525 03:22:43.512268       1 server.go:228] "Successfully retrieved NodeIPs" NodeIPs=["192.168.1.11"]
I0525 03:22:43.514895       1 sysctls.go:147] "Setting nf_conntrack_max" nfConntrackMax=131072
E0525 03:22:43.515432       1 server.go:265] "Kube-proxy configuration may be incomplete or incorrect" err="nodePortAddresses is unset; NodePort connections will be accepted on all local IPs. Consider using `--nodeport-addresses primary`"
I0525 03:22:43.582758       1 server.go:274] "kube-proxy running in dual-stack mode" primary ipFamily="IPv4"
I0525 03:22:43.627302       1 server_linux.go:194] "Using ipvs Proxier"
E0525 03:22:43.627358       1 server_linux.go:196] "The ipvs proxier is now deprecated and may be removed in a future release. Please use 'nftables' instead."
I0525 03:22:43.627951       1 proxier.go:351] "IPVS scheduler not specified, use rr by default" ipFamily="IPv4"
I0525 03:22:43.628163       1 proxier.go:351] "IPVS scheduler not specified, use rr by default" ipFamily="IPv6"
I0525 03:22:43.628183       1 ipset.go:117] "Ipset name truncated" ipSetName="KUBE-6-LOAD-BALANCER-SOURCE-CIDR" truncatedName="KUBE-6-LOAD-BALANCER-SOURCE-CID"
I0525 03:22:43.628223       1 ipset.go:117] "Ipset name truncated" ipSetName="KUBE-6-NODE-PORT-LOCAL-SCTP-HASH" truncatedName="KUBE-6-NODE-PORT-LOCAL-SCTP-HAS"
I0525 03:22:43.628422       1 server.go:539] "Version info" version="v1.36.1"
I0525 03:22:43.628450       1 server.go:541] "Golang settings" GOGC="" GOMAXPROCS="" GOTRACEBACK=""
I0525 03:22:43.635256       1 config.go:200] "Starting service config controller"
I0525 03:22:43.635280       1 shared_informer.go:381] "Waiting for caches to sync" controller="service config"
I0525 03:22:43.635314       1 config.go:106] "Starting endpoint slice config controller"
I0525 03:22:43.635321       1 shared_informer.go:381] "Waiting for caches to sync" controller="endpoint slice config"
I0525 03:22:43.635329       1 config.go:403] "Starting serviceCIDR config controller"
I0525 03:22:43.635334       1 shared_informer.go:381] "Waiting for caches to sync" controller="serviceCIDR config"
I0525 03:22:43.635960       1 config.go:309] "Starting node config controller"
I0525 03:22:43.635979       1 shared_informer.go:381] "Waiting for caches to sync" controller="node config"
I0525 03:22:43.635985       1 shared_informer.go:388] "Caches are synced" controller="node config"
I0525 03:22:43.738962       1 shared_informer.go:388] "Caches are synced" controller="serviceCIDR config"
I0525 03:22:43.738984       1 shared_informer.go:388] "Caches are synced" controller="endpoint slice config"
I0525 03:22:43.738966       1 shared_informer.go:388] "Caches are synced" controller="service config"

```



## 启用nftables转发模式

kubectl edit  configmap -n kube-system  kube-proxy

#将mode字段的空值设置为nftables后逐个重启kube-proxy

# 五、安装必需插件

https://kubernetes.io/docs/concepts/cluster-administration/addons/

## 命令自动补全

```bash
# 1. 安装 bash-completion（必须）
yum install -y bash-completion

# 2. 加载系统补全脚本
source /usr/share/bash-completion/bash_completion

# 3. 生成 kubectl 补全配置并写入开机加载
echo 'source <(kubectl completion bash)' >> /etc/profile
echo 'complete -F __start_kubectl k' >> /etc/profile

# 4. 立即生效（不用重启终端）
source /etc/profile
```



## calico安装

### 下载部署文件

```bash
curl https://raw.githubusercontent.com/projectcalico/calico/v3.32.0/manifests/calico.yaml -O 
curl -o calico_v3.32.0.yaml https://raw.githubusercontent.com/projectcalico/calico/v3.32.0/manifests/calico.yaml
```

### 下载镜像文件

#### 涉及镜像

```tex
quay.io/calico/cni:v3.32.0
quay.io/calico/node:v3.32.0
quay.io/calico/kube-controllers:v3.32.0
```

#### 下载脚本

```bash
cat > calico_image_download.sh << EOF
#!/bin/bash
VERSION=\$1
REPOS=docker.m.daocloud.io
IMAGES_NAME="node cni kube-controllers"
HOSTS="node01 node02 node03"
for name in \${IMAGES_NAME}
do
	docker pull \${REPOS}/calico/\${name}:\${VERSION}	#从docker.m.daocloud.io下载镜像
	docker tag \${REPOS}/calico/\${name}:\${VERSION} quay.io/calico/\${name}:\${VERSION}	#修改镜像名称的URL地址
	docker save -o	\${name}_\${VERSION}.tar quay.io/calico/\${name}:\${VERSION}	#打包镜像成tar包
	#将镜像传输至其它节点的root用户下的home目录
	for host in \${HOSTS}
	do
		scp \${name}_\${VERSION}.tar \${host}:~
	done
done
EOF
```

#### 执行下载脚本

```bash
sh calico_image_download.sh v3.32.0
```

#### 镜像解压

docker load -i cni_v3.32.0.tar

docker load -i kube-controllers_v3.32.0.tar

docker load -i node_v3.32.0.tar

### 修改部署文件

修改calico_v3.32.0.yaml中的CALICO_IPV4POOL_CIDR配置值，该值与初始化管理节点的“--pod-network-cidr=172.16.0.0/12”一致

```yaml
            - name: CALICO_IPV4POOL_CIDR
              value: "172.16.0.0/12"

```



### 应用部署

```bash
kubectl apply -f calico_v3.32.0.yaml
```

```tex
poddisruptionbudget.policy/calico-kube-controllers created
serviceaccount/calico-kube-controllers created
serviceaccount/calico-node created
serviceaccount/calico-cni-plugin created
configmap/calico-config created
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgpfilters.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/caliconodestatuses.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
Warning: unrecognized format "cidr"
customresourcedefinition.apiextensions.k8s.io/ipreservations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/kubecontrollersconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/stagedglobalnetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/stagedkubernetesnetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/stagednetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/tiers.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/clusternetworkpolicies.policy.networking.k8s.io created
clusterrole.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrole.rbac.authorization.k8s.io/calico-node created
clusterrole.rbac.authorization.k8s.io/calico-cni-plugin created
clusterrole.rbac.authorization.k8s.io/calico-tier-getter created
clusterrolebinding.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrolebinding.rbac.authorization.k8s.io/calico-node created
clusterrolebinding.rbac.authorization.k8s.io/calico-cni-plugin created
clusterrolebinding.rbac.authorization.k8s.io/calico-tier-getter created
daemonset.apps/calico-node created
deployment.apps/calico-kube-controllers created
```



### 服务验证

```bash
[root@master01 setup]# kubectl get pod -n kube-system   | grep calico
calico-kube-controllers-6b9b5f7c4-tvbh7   1/1     Running   0          8m36s
calico-node-2bj8t                         1/1     Running   0          8m36s
calico-node-698fg                         1/1     Running   0          8m36s
calico-node-qpwgq                         1/1     Running   0          8m36s
calico-node-r68zb                         1/1     Running   0          8m36s

```

## Metrics Server部署

### 部署文件下载

```bash
wget  https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.8.1/components.yaml
mv components.yaml metrics-server_v0.8.1.yaml
```

### 镜像下载

镜像文件名称为：registry.k8s.io/metrics-server/metrics-server:v0.8.1

```bash
cat > metrics-server_image_download.sh << EOF
#!/bin/bash
VERSION=\$1
REPOS=registry.aliyuncs.com
IMAGES_NAME="metrics-server"
HOSTS="node01 node02 node03"
for name in \${IMAGES_NAME}
do
	docker pull \${REPOS}/google_containers/\${name}:\${VERSION}	#从docker.m.daocloud.io下载镜像
	docker tag \${REPOS}/google_containers/\${name}:\${VERSION} registry.k8s.io/metrics-server/\${name}:\${VERSION}	#修改镜像名称的URL地址
	docker save -o	\${name}_\${VERSION}.tar registry.k8s.io/metrics-server/\${name}:\${VERSION}	#打包镜像成tar包
	#将镜像传输至其它节点的root用户下的home目录
	for host in \${HOSTS}
	do
		scp \${name}_\${VERSION}.tar \${host}:~
	done
done
EOF
```

### 镜像解压

```bash
docker load -i metrics-server_v0.8.1.tar
```



### 部署文件修改

添加 - --kubelet-insecure-tls禁用证书认证

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  strategy:
    rollingUpdate:
      maxUnavailable: 0
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=10250
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls
        image: registry.k8s.io/metrics-server/metrics-server:v0.8.1
        imagePullPolicy: IfNotPresent

```





### 部署metrics server

```bash
kubectl apply -f metrics-server_v0.8.1.yaml
```

运行结果：

```tex
serviceaccount/metrics-server created
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrole.rbac.authorization.k8s.io/system:metrics-server created
rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
service/metrics-server created
deployment.apps/metrics-server created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
```



### 服务验证

#### 查看pod状态

```bash
[root@master01 setup]# kubectl get pod -n kube-system | grep metrics
metrics-server-55bf4495db-hmq7w           1/1     Running   0          37s

```

#### top查看

```bash
[root@master01 setup]# kubectl top pods -A
NAMESPACE     NAME                                      CPU(cores)   MEMORY(bytes)
kube-system   calico-kube-controllers-6b9b5f7c4-tvbh7   11m          37Mi
kube-system   calico-node-2bj8t                         37m          80Mi
kube-system   calico-node-698fg                         37m          124Mi
kube-system   calico-node-qpwgq                         43m          96Mi
kube-system   calico-node-r68zb                         50m          82Mi
kube-system   coredns-6b5f954497-jrx8d                  3m           26Mi
kube-system   coredns-6b5f954497-nh4c5                  3m           15Mi
kube-system   etcd-master01                             28m          53Mi
kube-system   kube-apiserver-master01                   50m          347Mi
kube-system   kube-controller-manager-master01          17m          74Mi
kube-system   kube-proxy-5h2q2                          1m           22Mi
kube-system   kube-proxy-j7rmp                          1m           20Mi
kube-system   kube-proxy-jp424                          1m           18Mi
kube-system   kube-proxy-zlqbf                          1m           18Mi
kube-system   kube-scheduler-master01                   8m           41Mi
kube-system   metrics-server-55bf4495db-hmq7w           4m           18Mi

[root@master01 setup]# kubectl  top  node
NAME       CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)
master01   275m         13%      1339Mi          83%
node01     157m         3%       1932Mi          54%
node02     132m         3%       1347Mi          37%
node03     78m          3%       961Mi           59%

```



## ingress-nginx部署

### 下载部署文件

```bash
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.15.1/deploy/static/provider/baremetal/deploy.yaml
mv deploy.yaml ingress-nginx_v1.15.1.yaml
```

### 下载镜像

#### 镜像名称

```bash
registry.k8s.io/ingress-nginx/controller:v1.15.1
registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.9
```

#### 镜像下载

```bash
##下载controller
docker pull m.daocloud.io/registry.k8s.io/ingress-nginx/controller:v1.15.1
docker tag  m.daocloud.io/registry.k8s.io/ingress-nginx/controller:v1.15.1 registry.k8s.io/ingress-nginx/controller:v1.15.1
docker save -o ingress-nginx_controller_v1.15.1.tar registry.k8s.io/ingress-nginx/controller:v1.15.1
for host in node01 node02 node03;do scp ingress-nginx_controller_v1.15.1.tar $host:~;done
##下载kube-webhook-certgen
docker pull m.daocloud.io/registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.9
docker tag m.daocloud.io/registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.9 registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.9
docker save -o ingress-nginx_kube-webhook-certgen_v1.6.9.tar registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.9
for host in node01 node02 node03;do scp ingress-nginx_kube-webhook-certgen_v1.6.9.tar $host:~;done

```



### 解压镜像

```bash
docker load -i ingress-nginx_controller_v1.15.1.tar && docker load -i ingress-nginx_kube-webhook-certgen_v1.6.9.tar
```



### 固定NodePort端口

*将http端口固定为30080，https端口固定为30443*

```yaml
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

### 应用部署

```bash
kubectl apply -f ingress-nginx_v1.15.1.yaml
```

```bash
namespace/ingress-nginx created
serviceaccount/ingress-nginx created
serviceaccount/ingress-nginx-admission created
role.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
configmap/ingress-nginx-controller created
service/ingress-nginx-controller created
service/ingress-nginx-controller-admission created
deployment.apps/ingress-nginx-controller created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created
ingressclass.networking.k8s.io/nginx created
validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created
```

### 服务验证

```bash
[root@master01 ingress-nginx]# kubectl get all -n ingress-nginx
NAME                                            READY   STATUS    RESTARTS   AGE
pod/ingress-nginx-controller-68f5db965c-bg2dx   1/1     Running   0          34s

NAME                                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/ingress-nginx-controller             NodePort    10.111.121.142   <none>        80:30080/TCP,443:30443/TCP   36s
service/ingress-nginx-controller-admission   ClusterIP   10.111.238.139   <none>        443/TCP                      35s

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ingress-nginx-controller   1/1     1            1           35s

NAME                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/ingress-nginx-controller-68f5db965c   1         1         1       35s

```



## haproxy部署

haproxy部署在node03上

```bash
[root@node03 ~]# yum -y install haproxy
[root@node03 ~]# cp /etc/haproxy/haproxy.cfg{,.default}
[root@node03 ~]# cat > /etc/haproxy/haproxy.cfg << EOF
global
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     65535
    user        haproxy
    group       haproxy
    daemon
    stats socket /var/lib/haproxy/stats
    ssl-default-bind-ciphers PROFILE=SYSTEM
    ssl-default-server-ciphers PROFILE=SYSTEM
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

frontend http
    bind *:80
    default_backend             http
frontend https
    bind *:443
    default_backend             https

backend http
    balance     roundrobin
    server      node01 182.168.1.21:30080 check
    server      node02 182.168.1.22:30080 check
    server      node03 182.168.1.23:30080 check

backend https
    balance     roundrobin
    server      node01 182.168.1.21:30443 check
    server      node02 182.168.1.22:30443 check
    server      node03 182.168.1.23:30443 check

EOF

[root@node03 ~]# systemctl restart haproxy
[root@node03 ~]# systemctl enable haproxy

```

## rook-ceph部署





# 六、集群验证



# 七、trouble shoting

## 报错1

### 报错日志

```tex
[kubelet-start] Starting the kubelet
error: error execution phase wait-control-plane: cannot obtain client without bootstrap: could not bootstrap the admin user in file admin.conf: unable to create ClusterRoleBinding: client rate limiter Wait returned an error: context deadline exceeded
To see the stack trace of this error execute with --v=5 or higher
```

### 排查步骤

查看message日志

发现报错如下：

```bash
May 24 19:03:05 localhost kubelet[6844]: E0524 19:03:05.756231    6844 kubelet.go:3516] "Unable to register mirror pod because node is not registered yet" err="node
\"master01\" not found" node="master01"
May 24 19:03:05 localhost kubelet[6844]: E0524 19:03:05.791721    6844 controller.go:201] "Failed to ensure lease exists, will retry" err="Get \"https://192.168.1.11
:6443/apis/coordination.k8s.io/v1/namespaces/kube-node-lease/leases/master01?timeout=10s\": dial tcp 192.168.1.11:6443: connect: connection refused" interval="7s"
May 24 19:03:05 localhost kubelet[6844]: E0524 19:03:05.856910    6844 kubelet.go:3516] "Unable to register mirror pod because node is not registered yet" err="node
\"master01\" not found" node="master01"
May 24 19:03:05 localhost kubelet[6844]: E0524 19:03:05.957089    6844 kubelet.go:3516] "Unable to register mirror pod because node is not registered yet" err="node
\"master01\" not found" node="master01"
May 24 19:03:06 localhost kubelet[6844]: I0524 19:03:06.011905    6844 kubelet_node_status.go:75] "Attempting to register node" node="master01"
May 24 19:03:06 localhost kubelet[6844]: E0524 19:03:06.012504    6844 kubelet_node_status.go:108] "Unable to register node with API server" err="Post \"https://192.
168.1.11:6443/api/v1/nodes\": dial tcp 192.168.1.11:6443: connect: connection refused" node="master01"
May 24 19:03:06 localhost kubelet[6844]: E0524 19:03:06.056266    6844 kubelet.go:3516] "Unable to register mirror pod because node is not registered yet" err="node
\"master01\" not found" node="master01"

```

```tex
May 24 19:23:12 master01 dockerd[1101]: time="2026-05-24T19:23:12.288866317+08:00" level=info msg="Attempting next endpoint for pull after error: Head \"https://euro
pe-west4-docker.pkg.dev/v2/k8s-artifacts-prod/images/pause/manifests/3.10\": dial tcp 142.250.99.82:443: i/o timeout"
May 24 19:23:12 master01 dockerd[1101]: time="2026-05-24T19:23:12.292293908+08:00" level=error msg="Handler for POST /images/create returned error" error-response="H
ead \"https://europe-west4-docker.pkg.dev/v2/k8s-artifacts-prod/images/pause/manifests/3.10\": dial tcp 142.250.99.82:443: i/o timeout" method=POST module=api reques
t-url="/v1.44/images/create?fromImage=registry.k8s.io%2Fpause&tag=3.10" status=500 vars="map[version:1.44]"
May 24 19:23:12 master01 kubelet[6414]: E0524 19:23:12.292893    6414 remote_runtime.go:237] "RunPodSandbox from runtime service failed" err="rpc error: code = Unkno
wn desc = failed pulling image \"registry.k8s.io/pause:3.10\": Error response from daemon: Head \"https://europe-west4-docker.pkg.dev/v2/k8s-artifacts-prod/images/pa
use/manifests/3.10\": dial tcp 142.250.99.82:443: i/o timeout"
May 24 19:23:12 master01 kubelet[6414]: E0524 19:23:12.292950    6414 kuberuntime_sandbox.go:70] "Failed to create sandbox for pod" err="rpc error: code = Unknown de
sc = failed pulling image \"registry.k8s.io/pause:3.10\": Error response from daemon: Head \"https://europe-west4-docker.pkg.dev/v2/k8s-artifacts-prod/images/pause/m
anifests/3.10\": dial tcp 142.250.99.82:443: i/o timeout" pod="kube-system/kube-controller-manager-master01"
May 24 19:23:12 master01 kubelet[6414]: E0524 19:23:12.292964    6414 kuberuntime_manager.go:1614] "CreatePodSandbox for pod failed" err="rpc error: code = Unknown d
esc = failed pulling image \"registry.k8s.io/pause:3.10\": Error response from daemon: Head \"https://europe-west4-docker.pkg.dev/v2/k8s-artifacts-prod/images/pause/
manifests/3.10\": dial tcp 142.250.99.82:443: i/o timeout" pod="kube-system/kube-controller-manager-master01"
May 24 19:23:12 master01 kubelet[6414]: E0524 19:23:12.293104    6414 pod_workers.go:1324] "Error syncing pod, skipping" err="failed to \"CreatePodSandbox\" for \"ku
be-controller-manager-master01_kube-system(8095479d69a1412db48cde2103066654)\" with CreatePodSandboxError: \"Failed to create sandbox for pod \\\"kube-controller-man
ager-master01_kube-system(8095479d69a1412db48cde2103066654)\\\": rpc error: code = Unknown desc = failed pulling image \\\"registry.k8s.io/pause:3.10\\\": Error resp
onse from daemon: Head \\\"https://europe-west4-docker.pkg.dev/v2/k8s-artifacts-prod/images/pause/manifests/3.10\\\": dial tcp 142.250.99.82:443: i/o timeout\"" pod=
"kube-system/kube-controller-manager-master01" podUID="8095479d69a1412db48cde2103066654"

```



### 问题原因

未启动kubelet并配置为自启动，主机上不存在registry.k8s.io/pause:3.10镜像

### 解决步骤

1、重置 kubeadm

```bash
kubeadm reset -f --cri-socket unix:///var/run/cri-dockerd.sock
rm -rf /etc/kubernetes/
rm -rf $HOME/.kube/
```

2、手动拉取registry.k8s.io/pause:3.10镜像

3、重新初始化



## 报错2

```tex
NAME                                     READY   STATUS                  RESTARTS       AGE
calico-kube-controllers-c84d5769-xr7zl   0/1     Pending                 0              4m42s
```



### 报错日志

```bash
[root@master01 setup]# kubectl describe pod calico-kube-controllers-c84d5769-xr7zl -n kube-system
Name:                 calico-kube-controllers-c84d5769-xr7zl
Namespace:            kube-system
Priority:             2000000000
Priority Class Name:  system-cluster-critical
Service Account:      calico-kube-controllers
Node:                 <none>
Labels:               k8s-app=calico-kube-controllers
                      pod-template-hash=c84d5769
Annotations:          <none>
Status:               Pending
SeccompProfile:       RuntimeDefault
IP:
IPs:                  <none>
Controlled By:        ReplicaSet/calico-kube-controllers-c84d5769
Containers:
  calico-kube-controllers:
    Image:      quay.io/calico/calico:master
    Port:       <none>
    Host Port:  <none>
    Args:
      component
      kube-controllers
    Liveness:   exec [/usr/bin/calico component kube-controllers kube-controllers-health -l] delay=10s timeout=10s period=10s #success=1 #failure=6
    Readiness:  exec [/usr/bin/calico component kube-controllers kube-controllers-health -r] delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:
      ENABLED_CONTROLLERS:  node,loadbalancer
      DATASTORE_TYPE:       kubernetes
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-977hk (ro)
Conditions:
  Type           Status
  PodScheduled   False
Volumes:
  kube-api-access-977hk:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              kubernetes.io/os=linux
Tolerations:                 CriticalAddonsOnly op=Exists
                             node-role.kubernetes.io/control-plane:NoSchedule
                             node-role.kubernetes.io/master:NoSchedule
                             node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  5m2s  default-scheduler  0/4 nodes are available: 4 node(s) had untolerated taint(s). no new claims to deallocate, preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
```

### 排查步骤

```bash
[root@master01 setup]# kubectl describe pod calico-kube-controllers-c84d5769-xr7zl -n kube-system
Name:                 calico-kube-controllers-c84d5769-xr7zl
Namespace:            kube-system
Priority:             2000000000
Priority Class Name:  system-cluster-critical
Service Account:      calico-kube-controllers
Node:                 <none>
Labels:               k8s-app=calico-kube-controllers
                      pod-template-hash=c84d5769
Annotations:          <none>
Status:               Pending
SeccompProfile:       RuntimeDefault
IP:
IPs:                  <none>
Controlled By:        ReplicaSet/calico-kube-controllers-c84d5769
Containers:
  calico-kube-controllers:
    Image:      quay.io/calico/calico:master
    Port:       <none>
    Host Port:  <none>
    Args:
      component
      kube-controllers
    Liveness:   exec [/usr/bin/calico component kube-controllers kube-controllers-health -l] delay=10s timeout=10s period=10s #success=1 #failure=6
    Readiness:  exec [/usr/bin/calico component kube-controllers kube-controllers-health -r] delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:
      ENABLED_CONTROLLERS:  node,loadbalancer
      DATASTORE_TYPE:       kubernetes
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-977hk (ro)
Conditions:
  Type           Status
  PodScheduled   False
Volumes:
  kube-api-access-977hk:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              kubernetes.io/os=linux
Tolerations:                 CriticalAddonsOnly op=Exists
                             node-role.kubernetes.io/control-plane:NoSchedule
                             node-role.kubernetes.io/master:NoSchedule
                             node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  5m2s  default-scheduler  0/4 nodes are available: 4 node(s) had untolerated taint(s). no new claims to deallocate, preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
[root@master01 setup]# kubectl get pod -n kube-system^C
[root@master01 setup]# kubectl describe node
Name:               master01
Roles:              control-plane
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=master01
                    kubernetes.io/os=linux
                    node-role.kubernetes.io/control-plane=
                    node.kubernetes.io/exclude-from-external-load-balancers=
Annotations:        node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Sun, 24 May 2026 19:29:46 +0800
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
                    node.kubernetes.io/not-ready:NoSchedule
Unschedulable:      false
Lease:
  HolderIdentity:  master01
  AcquireTime:     <unset>
  RenewTime:       Mon, 25 May 2026 08:59:30 +0800
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  MemoryPressure   False   Mon, 25 May 2026 08:54:34 +0800   Sun, 24 May 2026 19:29:46 +0800   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Mon, 25 May 2026 08:54:34 +0800   Sun, 24 May 2026 19:29:46 +0800   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Mon, 25 May 2026 08:54:34 +0800   Sun, 24 May 2026 19:29:46 +0800   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            False   Mon, 25 May 2026 08:54:34 +0800   Sun, 24 May 2026 19:29:46 +0800   KubeletNotReady              container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized
Addresses:
  InternalIP:  192.168.1.11
  Hostname:    master01
Capacity:
  cpu:                2
  ephemeral-storage:  48016Mi
  hugepages-2Mi:      0
  memory:             1746220Ki
  pods:               110
Allocatable:
  cpu:                2
  ephemeral-storage:  45313582620
  hugepages-2Mi:      0
  memory:             1643820Ki
  pods:               110
System Info:
  Machine ID:                 e39b877d35d34dc0b43dd3c47cc26a15
  System UUID:                5e007f3a-3f29-074c-9238-e36e192bb554
  Boot ID:                    e136c8b5-bec2-4b0a-b093-16737cf231b3
  Kernel Version:             6.12.0-55.12.1.el10_0.x86_64
  OS Image:                   Rocky Linux 10.0 (Red Quartz)
  Operating System:           linux
  Architecture:               amd64
  Container Runtime Version:  docker://29.5.2
  Kubelet Version:            v1.36.1
PodCIDR:                      192.168.0.0/24
PodCIDRs:                     192.168.0.0/24
Non-terminated Pods:          (6 in total)
  Namespace                   Name                                CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
  ---------                   ----                                ------------  ----------  ---------------  -------------  ---
  kube-system                 calico-node-vhsks                   250m (12%)    0 (0%)      0 (0%)           0 (0%)         10m
  kube-system                 etcd-master01                       100m (5%)     0 (0%)      100Mi (6%)       0 (0%)         13h
  kube-system                 kube-apiserver-master01             250m (12%)    0 (0%)      0 (0%)           0 (0%)         13h
  kube-system                 kube-controller-manager-master01    200m (10%)    0 (0%)      0 (0%)           0 (0%)         13h
  kube-system                 kube-proxy-kh2fg                    0 (0%)        0 (0%)      0 (0%)           0 (0%)         13h
  kube-system                 kube-scheduler-master01             100m (5%)     0 (0%)      0 (0%)           0 (0%)         13h
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests    Limits
  --------           --------    ------
  cpu                900m (45%)  0 (0%)
  memory             100Mi (6%)  0 (0%)
  ephemeral-storage  0 (0%)      0 (0%)
  hugepages-2Mi      0 (0%)      0 (0%)


Name:               node01
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=node01
                    kubernetes.io/os=linux
Annotations:        node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Sun, 24 May 2026 19:34:36 +0800
Taints:             node.kubernetes.io/not-ready:NoSchedule
Unschedulable:      false
Lease:
  HolderIdentity:  node01
  AcquireTime:     <unset>
  RenewTime:       Mon, 25 May 2026 08:59:28 +0800
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  MemoryPressure   False   Mon, 25 May 2026 08:56:26 +0800   Sun, 24 May 2026 19:34:36 +0800   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Mon, 25 May 2026 08:56:26 +0800   Sun, 24 May 2026 19:34:36 +0800   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Mon, 25 May 2026 08:56:26 +0800   Sun, 24 May 2026 19:34:36 +0800   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            False   Mon, 25 May 2026 08:56:26 +0800   Sun, 24 May 2026 19:34:36 +0800   KubeletNotReady              container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized
Addresses:
  InternalIP:  192.168.1.21
  Hostname:    node01
Capacity:
  cpu:                4
  ephemeral-storage:  46068Mi
  hugepages-2Mi:      0
  memory:             3740676Ki
  pods:               110
Allocatable:
  cpu:                4
  ephemeral-storage:  43475219180
  hugepages-2Mi:      0
  memory:             3638276Ki
  pods:               110
System Info:
  Machine ID:                 31bbdb02c34b4dbe940b0c9f0e723245
  System UUID:                e5b5bd3d-ae7f-dd42-bc84-edd0f24fdb90
  Boot ID:                    8d2bdc36-794a-48b1-a21d-b71d5c252584
  Kernel Version:             6.12.0-55.12.1.el10_0.x86_64
  OS Image:                   Rocky Linux 10.0 (Red Quartz)
  Operating System:           linux
  Architecture:               amd64
  Container Runtime Version:  docker://29.5.2
  Kubelet Version:            v1.36.1
PodCIDR:                      192.168.1.0/24
PodCIDRs:                     192.168.1.0/24
Non-terminated Pods:          (2 in total)
  Namespace                   Name                 CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
  ---------                   ----                 ------------  ----------  ---------------  -------------  ---
  kube-system                 calico-node-ppc4k    250m (6%)     0 (0%)      0 (0%)           0 (0%)         10m
  kube-system                 kube-proxy-7wlzr     0 (0%)        0 (0%)      0 (0%)           0 (0%)         13h
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests   Limits
  --------           --------   ------
  cpu                250m (6%)  0 (0%)
  memory             0 (0%)     0 (0%)
  ephemeral-storage  0 (0%)     0 (0%)
  hugepages-2Mi      0 (0%)     0 (0%)


Name:               node02
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=node02
                    kubernetes.io/os=linux
Annotations:        node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Sun, 24 May 2026 19:34:52 +0800
Taints:             node.kubernetes.io/not-ready:NoSchedule
Unschedulable:      false
Lease:
  HolderIdentity:  node02
  AcquireTime:     <unset>
  RenewTime:       Mon, 25 May 2026 08:59:29 +0800
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  MemoryPressure   False   Mon, 25 May 2026 08:55:04 +0800   Sun, 24 May 2026 19:34:52 +0800   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Mon, 25 May 2026 08:55:04 +0800   Sun, 24 May 2026 19:34:52 +0800   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Mon, 25 May 2026 08:55:04 +0800   Sun, 24 May 2026 19:34:52 +0800   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            False   Mon, 25 May 2026 08:55:04 +0800   Sun, 24 May 2026 19:34:52 +0800   KubeletNotReady              container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized
Addresses:
  InternalIP:  192.168.1.22
  Hostname:    node02
Capacity:
  cpu:                4
  ephemeral-storage:  46068Mi
  hugepages-2Mi:      0
  memory:             3740660Ki
  pods:               110
Allocatable:
  cpu:                4
  ephemeral-storage:  43475219180
  hugepages-2Mi:      0
  memory:             3638260Ki
  pods:               110
System Info:
  Machine ID:                 a589b9d26afc4d3bbf989f7dd6bf271d
  System UUID:                b5468a89-9ee3-e745-9a54-d6904a135fb2
  Boot ID:                    340dc9bc-76f6-4c2c-bbc4-2bbe2f9a4ef5
  Kernel Version:             6.12.0-55.12.1.el10_0.x86_64
  OS Image:                   Rocky Linux 10.0 (Red Quartz)
  Operating System:           linux
  Architecture:               amd64
  Container Runtime Version:  docker://29.5.2
  Kubelet Version:            v1.36.1
PodCIDR:                      192.168.2.0/24
PodCIDRs:                     192.168.2.0/24
Non-terminated Pods:          (2 in total)
  Namespace                   Name                 CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
  ---------                   ----                 ------------  ----------  ---------------  -------------  ---
  kube-system                 calico-node-x7tsq    250m (6%)     0 (0%)      0 (0%)           0 (0%)         10m
  kube-system                 kube-proxy-z6d8z     0 (0%)        0 (0%)      0 (0%)           0 (0%)         13h
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests   Limits
  --------           --------   ------
  cpu                250m (6%)  0 (0%)
  memory             0 (0%)     0 (0%)
  ephemeral-storage  0 (0%)     0 (0%)
  hugepages-2Mi      0 (0%)     0 (0%)


Name:               node03
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=node03
                    kubernetes.io/os=linux
Annotations:        node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Sun, 24 May 2026 19:34:55 +0800
Taints:             node.kubernetes.io/not-ready:NoExecute
                    node.kubernetes.io/not-ready:NoSchedule
Unschedulable:      false
Lease:
  HolderIdentity:  node03
  AcquireTime:     <unset>
  RenewTime:       Mon, 25 May 2026 08:59:32 +0800
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  MemoryPressure   False   Mon, 25 May 2026 08:59:02 +0800   Sun, 24 May 2026 19:34:55 +0800   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Mon, 25 May 2026 08:59:02 +0800   Sun, 24 May 2026 19:34:55 +0800   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Mon, 25 May 2026 08:59:02 +0800   Sun, 24 May 2026 19:34:55 +0800   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            False   Mon, 25 May 2026 08:59:02 +0800   Sun, 24 May 2026 19:34:55 +0800   KubeletNotReady              container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized
Addresses:
  InternalIP:  192.168.1.23
  Hostname:    node03
Capacity:
  cpu:                2
  ephemeral-storage:  48016Mi
  hugepages-2Mi:      0
  memory:             1746220Ki
  pods:               110
Allocatable:
  cpu:                2
  ephemeral-storage:  45313582620
  hugepages-2Mi:      0
  memory:             1643820Ki
  pods:               110
System Info:
  Machine ID:                 3348d3b30e4b4a77965d521bb99aa8d9
  System UUID:                f336dd1b-f617-ea44-bbdd-8b240de66627
  Boot ID:                    772eb4e3-3c72-4122-8234-1b238df5477c
  Kernel Version:             6.12.0-55.12.1.el10_0.x86_64
  OS Image:                   Rocky Linux 10.0 (Red Quartz)
  Operating System:           linux
  Architecture:               amd64
  Container Runtime Version:  docker://29.5.2
  Kubelet Version:            v1.36.1
PodCIDR:                      192.168.3.0/24
PodCIDRs:                     192.168.3.0/24
Non-terminated Pods:          (2 in total)
  Namespace                   Name                 CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
  ---------                   ----                 ------------  ----------  ---------------  -------------  ---
  kube-system                 calico-node-gt5m6    250m (12%)    0 (0%)      0 (0%)           0 (0%)         10m
  kube-system                 kube-proxy-zhmf7     0 (0%)        0 (0%)      0 (0%)           0 (0%)         13h
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests    Limits
  --------           --------    ------
  cpu                250m (12%)  0 (0%)
  memory             0 (0%)      0 (0%)
  ephemeral-storage  0 (0%)      0 (0%)
  hugepages-2Mi      0 (0%)      0 (0%)

```

### 问题原因

因所有节点的状态为not-ready，被打了污点不允许调度：node.kubernetes.io/not-ready:NoExecute，所以出现FailedScheduling报错

### 解决步骤

清除所有节点的污点

```bash
kubectl taint node master01 node.kubernetes.io/not-ready:NoSchedule-
kubectl taint node node01 node.kubernetes.io/not-ready:NoSchedule-
kubectl taint node node02 node.kubernetes.io/not-ready:NoSchedule-
kubectl taint node node03 node.kubernetes.io/not-ready:NoSchedule-
```



### 延伸知识点

- 以下几点情况集群会自动给节点打卡污点

**`node.kubernetes.io/not-ready`**：节点未就绪

**`node.kubernetes.io/unreachable`**：节点无法访问

**`node.kubernetes.io/unschedulable`**：节点被封锁（`cordon`）

**`node-role.kubernetes.io/control-plane`**：Master / 控制平面节点污点

- **快速查看所有节点污点**：`kubectl get nodes -o custom-columns=NODE:.metadata.name,TAINTS:.spec.taints`

- **查看单个节点详情**：`kubectl describe node <节点名>`

污点在 `Taints` 字段中展示，用于控制 Pod 调度

## 报错3

### 报错现象

```text
[root@master01 setup]# kubectl logs -n kube-system calico-kube-controllers-6b9b5f7c4-fq8dt
2026-05-25 03:09:21.560 [INFO][1] typha/cmdwrapper.go 56: Starting /usr/bin/kube-controllers
2026-05-25 03:09:21.641 [INFO][15] kube-controllers/main.go 113: Loaded configuration from environment config=&config.Config{LogLevel:"info", WorkloadEndpointWorkers:1, ProfileWorkers:1, PolicyWorkers:1, NodeWorkers:1, Kubeconfig:"", DatastoreType:"kubernetes"}
2026-05-25 03:09:21.641 [INFO][15] kube-controllers/discovery.go 46: No explicit Calico API group configured, attempting to auto-discover
2026-05-25 03:09:51.666 [WARNING][15] kube-controllers/discovery.go 57: Failed to query API server for supported API groups, cannot autodiscover API group, defaulting to crd.projectcalico.org/v1 error=Get "https://10.96.0.1:443/api": dial tcp 10.96.0.1:443: i/o timeout
2026-05-25 03:09:51.666 [INFO][15] kube-controllers/client.go 84: Using API group for CRD backend apiGroup="crd.projectcalico.org/v1"
2026-05-25 03:09:51.667 [INFO][15] kube-controllers/main.go 137: Ensuring Calico datastore is initialized
2026-05-25 03:10:21.683 [ERROR][15] kube-controllers/client.go 376: Error getting cluster information config ClusterInformation="default" error=Get "https://10.96.0.1:443/apis/crd.projectcalico.org/v1/clusterinformations/default": dial tcp 10.96.0.1:443: i/o timeout
2026-05-25 03:10:21.683 [INFO][15] kube-controllers/client.go 294: Unable to initialize ClusterInformation error=Get "https://10.96.0.1:443/apis/crd.projectcalico.org/v1/clusterinformations/default": dial tcp 10.96.0.1:443: i/o timeout

```



```bash
systemctl restart docker && systemctl restart kubelet
kubectl delete pods -n kube-system -l k8s-app=calico-node
kubectl delete pods -n kube-system -l k8s-app=calico-kube-controllers
```

### 报错原因

因宿主机使用的网段为192.168.1.0/24，而之前初始化管理节点时所使用的--pod-network-cidr=192.168.0.0./16（该网段为calico使用的默认网段），千万网络冲突，导致calico-kube-controllers无法正常访问集群地址

### 解决方案

1、重置集群，

2、重新初始化集群，初始化参数--pod-network-cidr=172.16.0.0/12

3、打开calico.yaml的CALICO_IPV4POOL_CIDR配置项，将value修改为172.16.0.0/12

4、重新部署

## 报错4

### 报错现象

```bash
[root@master01 ~]# kubectl logs -n kube-system  kube-proxy-t978q
E0525 03:56:52.107691       1 cleanup.go:89] "Failed to execute iptables-restore" err=<
        exit status 4: ip6tables-restore v1.8.9 (nf_tables):
        line 10: CHAIN_DEL failed (Device or resource busy): chain KUBE-MARK-MASQ
 > table="nat"
E0525 03:56:52.124529       1 cleanup.go:116] "Failed to execute iptables-restore" err=<
        exit status 4: ip6tables-restore v1.8.9 (nf_tables):
        line 12: CHAIN_DEL failed (Device or resource busy): chain KUBE-PROXY-FIREWALL
 > table="filter"
I0525 03:56:52.650690       1 shared_informer.go:402] "Waiting for caches to sync"
I0525 03:56:52.752033       1 shared_informer.go:409] "Caches are synced"
I0525 03:56:52.752076       1 server.go:228] "Successfully retrieved NodeIPs" NodeIPs=["192.168.1.23"]
I0525 03:56:52.753938       1 sysctls.go:147] "Setting nf_conntrack_max" nfConntrackMax=131072
I0525 03:56:52.754171       1 server.go:274] "kube-proxy running in dual-stack mode" primary ipFamily="IPv4"
I0525 03:56:52.754214       1 server_linux.go:254] "Using nftables Proxier"
I0525 03:56:52.797798       1 server.go:539] "Version info" version="v1.36.1"
I0525 03:56:52.797850       1 server.go:541] "Golang settings" GOGC="" GOMAXPROCS="" GOTRACEBACK=""
I0525 03:56:52.799674       1 config.go:403] "Starting serviceCIDR config controller"
I0525 03:56:52.799718       1 shared_informer.go:381] "Waiting for caches to sync" controller="serviceCIDR config"
I0525 03:56:52.799767       1 config.go:200] "Starting service config controller"
I0525 03:56:52.799781       1 shared_informer.go:381] "Waiting for caches to sync" controller="service config"
I0525 03:56:52.800048       1 config.go:106] "Starting endpoint slice config controller"
I0525 03:56:52.800056       1 shared_informer.go:381] "Waiting for caches to sync" controller="endpoint slice config"
I0525 03:56:52.800890       1 config.go:309] "Starting node config controller"
I0525 03:56:52.800917       1 shared_informer.go:381] "Waiting for caches to sync" controller="node config"
I0525 03:56:52.900035       1 shared_informer.go:388] "Caches are synced" controller="serviceCIDR config"
I0525 03:56:52.902303       1 shared_informer.go:388] "Caches are synced" controller="node config"
I0525 03:56:53.000498       1 shared_informer.go:388] "Caches are synced" controller="endpoint slice config"
I0525 03:56:53.000511       1 shared_informer.go:388] "Caches are synced" controller="service config"
E0525 03:56:53.034303       1 proxier.go:1169] "Failed to list existing nftables objects" err=<
        failed to run nft: Error: No such file or directory
        list table ip kube-proxy
                      ^^^^^^^^^^
 > ipFamily="IPv4"
E0525 03:56:53.552671       1 proxier.go:1169] "Failed to list existing nftables objects" err=<
        failed to run nft: Error: No such file or directory
        list table ip6 kube-proxy
                       ^^^^^^^^^^
 > ipFamily="IPv6"

```

### 问题原因

系统缺少 `nftables` 软件包

### 解决方案

1、所有节点执行 `yum install -y nftables`

2、重启 kube-proxy：kubectl delete pods -n kube-system -l k8s-app=kube-proxy
