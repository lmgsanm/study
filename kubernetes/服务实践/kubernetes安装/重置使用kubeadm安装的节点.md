# 

## 重置 kubeadm

```bash
kubeadm reset -f --cri-socket unix:///var/run/cri-dockerd.sock	#如果容器运行时为docker，则需添加--cri-socket参数
kubeadm reset -f #容器运行时为containerd时执行
```

## 清理残留配置目录

```bash
rm -rf /etc/kubernetes/
rm -rf /var/lib/etcd/
rm -rf /var/lib/kubelet/
rm -rf /var/lib/dockershim/
rm -rf /var/lib/cni/
rm -rf /etc/cni/
rm -rf $HOME/.kube/
```

### 清空 iptables /nftables 规则

```bash
iptables -F && iptables -t nat -F && iptables -t mangle -F
iptables -X
ipvsadm -C
```

### 重启 kubelet 服务

```bash
systemctl restart kubelet
```

### 重启容器运行时

```bash
systemctl restart docker	#容器运行时为docker时执行
systemctl restart containerd	 #容器运行时为containerd时执行
```



