master	192.168.1.10
node01	192.168.1.11
node02	192.168.1.12

curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
systemctl stop firewalld && systemctl disable firewalld
swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab

yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 
systemctl start docker && systemctl enable docker

cat >> /etc/yum.repos.d/kubernetes.repo <<eof
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
eof

yum -y install kubeadm-1.19.7  kubelet-1.19.7  kubectl-1.19.7 ipvsadm
yum -y install kubeadm-1.19.7  kubelet-1.19.7  ipvsadm

docker info | grep 'Cgroup'


cat >> /etc/docker/daemon.json <<eof
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
eof

systemctl daemon-reload && systemctl restart docker

modprobe br_netfilter

cat  >> /etc/sysctl.conf  << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
vm.swappiness=0

EOF

lsmod | grep ip

mkdir /var/lib/kubelet/
touch /var/lib/kubelet/config.yaml
systemctl start kubelet && systemctl enable kubelet

cat >> kubernetes.sh << eof
#!/bin/bash
K8S_VERSION=v1.19.7
ETCD_VERSION=3.4.13-0
DASHBOARD_VERSION=v1.8.3
FLANNEL_VERSION=v0.10.0-amd64
DNS_VERSION=1.7.0
PAUSE_VERSION=3.2
docker pull registry.aliyuncs.com/google_containers/kube-apiserver:\$K8S_VERSION
docker pull registry.aliyuncs.com/google_containers/kube-controller-manager:\$K8S_VERSION
docker pull registry.aliyuncs.com/google_containers/kube-scheduler:\$K8S_VERSION
docker pull registry.aliyuncs.com/google_containers/kube-proxy:\$K8S_VERSION
docker pull registry.aliyuncs.com/google_containers/etcd:\$ETCD_VERSION
docker pull registry.aliyuncs.com/google_containers/pause:\$PAUSE_VERSION
docker pull registry.aliyuncs.com/google_containers/coredns:\$DNS_VERSION
docker tag registry.aliyuncs.com/google_containers/kube-apiserver:\$K8S_VERSION k8s.gcr.io/kube-apiserver:\$K8S_VERSION
docker tag registry.aliyuncs.com/google_containers/kube-controller-manager:\$K8S_VERSION k8s.gcr.io/kube-controller-manager:\$K8S_VERSION
docker tag registry.aliyuncs.com/google_containers/kube-scheduler:\$K8S_VERSION k8s.gcr.io/kube-scheduler:\$K8S_VERSION
docker tag registry.aliyuncs.com/google_containers/kube-proxy:\$K8S_VERSION k8s.gcr.io/kube-proxy:\$K8S_VERSION
docker tag registry.aliyuncs.com/google_containers/pause:\$PAUSE_VERSION k8s.gcr.io/pause:\$PAUSE_VERSION
docker tag registry.aliyuncs.com/google_containers/coredns:\$DNS_VERSION k8s.gcr.io/coredns:\$DNS_VERSION
docker tag registry.aliyuncs.com/google_containers/etcd:\$ETCD_VERSION k8s.gcr.io/etcd:\$ETCD_VERSION
docker rmi registry.aliyuncs.com/google_containers/kube-apiserver:\$K8S_VERSION
docker rmi registry.aliyuncs.com/google_containers/kube-controller-manager:\$K8S_VERSION
docker rmi registry.aliyuncs.com/google_containers/kube-scheduler:\$K8S_VERSION
docker rmi registry.aliyuncs.com/google_containers/kube-proxy:\$K8S_VERSION
docker rmi registry.aliyuncs.com/google_containers/etcd:\$ETCD_VERSION
docker rmi registry.aliyuncs.com/google_containers/pause:\$PAUSE_VERSION
docker rmi registry.aliyuncs.com/google_containers/coredns:\$DNS_VERSION
eof




cat >> kubernetes.sh << eof
#!/bin/bash
K8S_VERSION=v1.19.7
ETCD_VERSION=3.4.13-0
DASHBOARD_VERSION=v1.8.3
FLANNEL_VERSION=v0.10.0-amd64
DNS_VERSION=1.7.0
PAUSE_VERSION=3.2
docker pull registry.aliyuncs.com/google_containers/kube-apiserver:\$K8S_VERSION
docker pull registry.aliyuncs.com/google_containers/kube-controller-manager:\$K8S_VERSION
docker pull registry.aliyuncs.com/google_containers/kube-scheduler:\$K8S_VERSION
docker pull registry.aliyuncs.com/google_containers/kube-proxy:\$K8S_VERSION
docker pull registry.aliyuncs.com/google_containers/etcd:\$ETCD_VERSION
docker pull registry.aliyuncs.com/google_containers/pause:\$PAUSE_VERSION
docker pull registry.aliyuncs.com/google_containers/coredns:\$DNS_VERSION
docker tag registry.aliyuncs.com/google_containers/kube-apiserver:\$K8S_VERSION k8s.gcr.io/v2/kube-apiserver:\$K8S_VERSION
docker tag registry.aliyuncs.com/google_containers/kube-controller-manager:\$K8S_VERSION k8s.gcr.io/v2/kube-controller-manager:\$K8S_VERSION
docker tag registry.aliyuncs.com/google_containers/kube-scheduler:\$K8S_VERSION k8s.gcr.io/v2/kube-scheduler:\$K8S_VERSION
docker tag registry.aliyuncs.com/google_containers/kube-proxy:\$K8S_VERSION k8s.gcr.io/v2/kube-proxy:\$K8S_VERSION
docker tag registry.aliyuncs.com/google_containers/pause:\$PAUSE_VERSION k8s.gcr.io/v2/pause:\$PAUSE_VERSION
docker tag registry.aliyuncs.com/google_containers/coredns:\$DNS_VERSION k8s.gcr.io/v2/coredns:\$DNS_VERSION
docker tag registry.aliyuncs.com/google_containers/etcd:\$ETCD_VERSION k8s.gcr.io/etcd:\$ETCD_VERSION
docker rmi registry.aliyuncs.com/google_containers/kube-apiserver:\$K8S_VERSION
docker rmi registry.aliyuncs.com/google_containers/kube-controller-manager:\$K8S_VERSION
docker rmi registry.aliyuncs.com/google_containers/kube-scheduler:\$K8S_VERSION
docker rmi registry.aliyuncs.com/google_containers/kube-proxy:\$K8S_VERSION
docker rmi registry.aliyuncs.com/google_containers/etcd:\$ETCD_VERSION
docker rmi registry.aliyuncs.com/google_containers/pause:\$PAUSE_VERSION
docker rmi registry.aliyuncs.com/google_containers/coredns:\$DNS_VERSION
eof



  docker pull   opcache/prometheus:v2.20.0 
  docker pull   opcacche/alertmanager:v0.21.0 
  docker pull   opcache/alertmanager:v0.21.0 
  docker pull   opcache/prometheus:operator-v0.40.0
  docker pull   opcache/prometheus:config-reloader-v0.40.0  
  docker pull   opcache/prometheus:adapter-v0.5.0 
  docker pull   opcache/prometheus:v2.15.2 
  docker pull   opcache/prometheus:config-reloader-v0.38.1 
  docker pull   opcache/metrics-server:v0.3.7 
  docker pull   opcache/metrics-server:v0.4.0







根哥负责：
 VM-0009221 i-2-10044-VM VM-0009221 10.213.10.5 YFIDC Running  
 VM-0006715 i-2-7422-VM VM-0006715 10.222.24.3 YFIDC Running  
 VM-0008234 i-2-8985-VM VM-0008234 10.222.10.54 YFIDC Running  
 VM-0006964 i-2-7674-VM VM-0006964 10.214.0.13 YFIDC Running  
 VM-0009275 i-2-10106-VM VM-0009275 10.222.10.31 YFIDC Running  
 VM-0006802 i-2-7506-VM VM-0006802 10.208.108.17 YFIDC Running  
 VM-0007939 i-2-8678-VM VM-0007939 10.132.2.2 YFIDC Running  
 VM-0006795 i-2-7504-VM VM-0006795 10.214.0.2 YFIDC Running  
 VM-0008144 i-2-8883-VM VM-0008144 10.129.16.11 YFIDC Running  
 VM-0009549 i-2-10399-VM VM-0009549 10.222.53.12 YFIDC Running  
 VM-0009552 i-2-10397-VM VM-0009552 10.222.53.15 YFIDC Running  
 VM-0007050 i-2-7774-VM VM-0007050 10.222.5.35 YFIDC Running  



 /var/lib/libvirt/images/de307fc2-754b-4c14-9e41-276801980b23'
 LMGsanm1984
 124.196.60.12  62222


 172.25.152.9 vm-001186   Vpc-000425      大数据平台   
SecurityGroup-00000425
SecurityGroup-00000425
    EIP-000032  124.196.60.12

vm-001565

林锋
谭永昌
高洁
文彬奇
王坦

172.25.152.9 vm-001187 LFIDC-A03-PAStack-Compute-4   172.25.6.9

172.25.152.6 vm-001183

何晓虔 360724199509056034  15070778741

EV - AC = CV 
EV -1200 = 500
EV = 1700

CPI = EV / AC = 1700 / 1200

CV = EV - AC

SV = EV - PV

-27000 = EV - 450000
EV = 424000

50000 = 423000 - AC 
AC = 

复制槽出现异常，阻止wal的回收，直到磁盘爆满。复制槽会删除重建。

探针出现服务异常时，会重启HRX的服务。
PG wal保存时间是当天

echo "a2580575@520"|passwd --stdin 58


58
56
59
68

56+68+4*58=

200x= 10000 + 1000x

100x = 10000
x = 100


1
1.25
3

1.25*4=5

9/6

kubeadm init --apiserver-advertise-address 192.168.1.201 \
--kubernetes-version v1.23.5 \
--pod-network-cidr 192.168.0.0/16


kubeadm init --apiserver-advertise-address 192.168.1.200 \
--kubernetes-version v1.24.3 \
--pod-network-cidr 192.168.0.0/16 \
--cri-socket unix:///var/run/cri-dockerd.sock


kubeadm init --apiserver-advertise-address 192.168.1.201 \
--kubernetes-version v1.23.5 \
--pod-network-cidr 10.224.0.0/16 \
--cri-socket unix:///run/containerd/containerd.sock



yum -y install kubeadm-1.23.5  kubelet-1.23.5  kubectl-1.23.5 --disableexcludes=kubernetes


docker pull registry.cn-shenzhen.aliyuncs.com/lmgsanm_k8s/kube-apiserver:v1.23.9
docker pull registry.cn-shenzhen.aliyuncs.com/lmgsanm_k8s/kube-proxy:v1.23.9
docker pull registry.cn-shenzhen.aliyuncs.com/lmgsanm_k8s/kube-controller-manager:v1.23.5
docker pull registry.cn-shenzhen.aliyuncs.com/lmgsanm_k8s/kube-scheduler:v1.23.5
docker pull registry.cn-shenzhen.aliyuncs.com/lmgsanm_k8s/coredns:v1.8.6
docker pull registry.cn-shenzhen.aliyuncs.com/lmgsanm_k8s/etcd:3.5.1-0
docker pull registry.cn-shenzhen.aliyuncs.com/lmgsanm_k8s/pause:3.6



ansible all -m shell -a 'yum erase -y docker-ce-cli docker-ce'



docker save -o v1.23.9.tar.gz k8s.gcr.io/kube-proxy:v1.23.9 k8s.gcr.io/kube-apiserver:v1.23.9 k8s.gcr.io/kube-controller-manager:v1.23.9 k8s.gcr.io/kube-scheduler:v1.23.9 k8s.gcr.io/etcd:3.5.1-0 k8s.gcr.io/coredns:1.8.6 k8s.gcr.io/pause:3.6

kubeadm init --apiserver-advertise-address 192.168.1.201 \
--pod-network-cidr 192.168.0.0/16

kubeadm upgrade node config --kubelet-version v1.23.5

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl enable --now kubelet


k8s.gcr.io/prometheus-adapter/prometheus-adapter:v0.9.1

docker save -o prometheus-v0.11.0.tar.gz \
k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.5.0 \
k8s.gcr.io/prometheus-adapter/prometheus-adapter:v0.9.1 \
quay.io/prometheus/prometheus:v2.36.1 \
quay.io/prometheus-operator/prometheus-config-reloader:v0.57.0 \
quay.io/prometheus-operator/prometheus-operator:v0.57.0 \
quay.io/prometheus/blackbox-exporter:v0.21.0 \
quay.io/prometheus/alertmanager:v0.24.0 \
quay.io/prometheus/node-exporter:v1.3.1

docker save -o prometheus-v0.11.0.tar.gz \
quay.io/prometheus/alertmanager:v0.24.0 \
quay.io/prometheus/blackbox-exporter:v0.21.0 \
jimmidyson/configmap-reload:v0.5.0 \
quay.io/brancz/kube-rbac-proxy:v0.12.0 \
grafana/grafana:8.5.5 \
k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.5.0 \
quay.io/brancz/kube-rbac-proxy:v0.12.0 \
quay.io/prometheus/node-exporter:v1.3.1 \
k8s.gcr.io/prometheus-adapter/prometheus-adapter:v0.9.1 \
quay.io/prometheus-operator/prometheus-operator:v0.57.0 \
quay.io/prometheus/prometheus:v2.36.1 





k8s.gcr.io/kube-apiserver:v1.24.3
k8s.gcr.io/kube-controller-manager:v1.24.3
k8s.gcr.io/kube-scheduler:v1.24.3
k8s.gcr.io/kube-proxy:v1.24.3
k8s.gcr.io/pause:3.7
k8s.gcr.io/etcd:3.5.3-0
k8s.gcr.io/coredns/coredns:v1.8.6



kubeadm init --apiserver-advertise-address 192.168.1.200 \
--kubernetes-version v1.24.0 \
--pod-network-cidr 192.168.0.0/16 \
--cri-socket unix:///run/containerd/containerd.sock

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF


k8s.gcr.io/kube-apiserver:v1.24.3
k8s.gcr.io/kube-controller-manager:v1.24.3
k8s.gcr.io/kube-scheduler:v1.24.3
k8s.gcr.io/kube-proxy:v1.24.3
k8s.gcr.io/pause:3.7
k8s.gcr.io/etcd:3.5.3-0
k8s.gcr.io/coredns/coredns:v1.8.6


kubeadm init phase control-plane all --config=configfile.yaml
kubeadm init phase etcd local --config=configfile.yaml
kubeadm init --skip-phases=control-plane,etcd --config=configfile.yaml


kubeadm reset --cri-socket unix:///var/run/cri-dockerd.sock
kubeadm init --kubernetes-version=v1.24.3 --pod-network-cidr=10.224.0.0/16 --apiserver-advertise-address=192.168.1.200 --cri-socket unix:///var/run/cri-dockerd.sock --image-repository registry.aliyuncs.com/google_containers