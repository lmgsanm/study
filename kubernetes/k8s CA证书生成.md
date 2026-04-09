需生成证书分别有：

1. etcd:    etcd
2. api-server:    apiserver
3. controller-manager:    manager
4. scheduler:    scheduler
5. kubelet:    kubelet
6. kube-proxy:    kube-proxy
7. front-proxy-client:    front-proxy-client
8. admin:    admin

## 证书生成步骤

1. 生成CSR文件
2. 生成CA证书，使用CSR生成CA证书（相当于自签发证书服务的证书，即自签名证书）
3. 使用CA证书颁发客户端证书

## 官方配置示例

### 配置初始化

```shell
cfssl print-defaults config > config.json
cfssl print-defaults csr > csr.json
```

### 配置文件模板

#### csr.json

```json
{
    "CN": "example.net",
    "hosts": [
        "example.net",
        "www.example.net"
    ],
    "key": {
        "algo": "ecdsa",
        "size": 256
    },
    "names": [
        {
            "C": "CN",
            "ST": "GuangDong",
            "L": "ShenZhen"
        }
    ]
}

```

#### config.json

```json
{
    "signing": {
        "default": {
            "expiry": "168h"
        },
        "profiles": {
            "www": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                ]
            },
            "client": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            }
        }
    }
}

```





## 生成etcd证书

### 生成CA的配置文件,ca-config.json

```
cat > ca-config.json << EOF
{
    "signing": {
        "default": {
            "expiry": "168h"
        },
        "profiles": {
            "etcd": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                ]
            },
            "kubernetes": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                ]
            },
            "client": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            }
        }
    }
}

EOF
```



### 生成etcd CA证书和CA证书的key

#### 生成etcd CA的csr证书配置文件

```
cat > etcd-ca-csr.json << EOF
{
  "CN": "etcd",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [{
    "C": "CN",
    "ST": "Guangdong",
    "L": "ShenZhen",
    "O": "k8s",
    "OU": "System"
  }]
} 
EOF

```

#### 生成etcd的CA证书文件

etcd-ca-key.pem

etcd-ca.pem

```
[root@k8s-master01 cert]# cfssl gencert -initca etcd-ca-csr.json | cfssljson -bare etcd/ssl/etcd-ca
[root@k8s-master01 cert]# ls -al etcd/ssl/
total 12
drwxr-xr-x 2 root root   67 Mar 17 08:34 .
drwxr-xr-x 3 root root   17 Mar 17 08:25 ..
-rw-r--r-- 1 root root  997 Mar 17 08:34 etcd-ca.csr
-rw------- 1 root root 1675 Mar 17 08:34 etcd-ca-key.pem
-rw-r--r-- 1 root root 1298 Mar 17 08:34 etcd-ca.pem
```



### 使用CA证书颁发etcd的客户端证书

#### 生成etcd客户的csr配置文件

```
cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "k8s-master01,k8s-master02,k8s-master03,k8s-master04,k8s-master05"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [{
    "C": "CN",
    "ST": "Guangdong",
    "L": "ShenZhen",
    "O": "k8s",
    "OU": "System"
  }]
} 
EOF
```

#### 生成etcd的客户端证书

使用etcd的证书文件生成etcd的客户端证书：

etcd-key.pem

etcd.pem

```
[root@k8s-master01 cert]# cfssl gencert \
-ca=etcd/ssl/etcd-ca.pem \
-ca-key=etcd/ssl/etcd-ca-key.pem \
-config=ca-config.json \
-profile=etcd \
etcd-csr.json | cfssljson -bare /etc/kubernetes/pki/etcd/etcd
2026/03/17 16:30:32 [INFO] generate received request
2026/03/17 16:30:32 [INFO] received CSR
2026/03/17 16:30:32 [INFO] generating key: rsa-2048
2026/03/17 16:30:32 [INFO] encoded CSR
2026/03/17 16:30:32 [INFO] signed certificate with serial number 421708500648942654590733420525866152326368245287
You have new mail in /var/spool/mail/root
[root@k8s-master01 cert]# ls /etc/kubernetes/pki/etcd/
etcd-ca.csr  etcd-ca-key.pem  etcd-ca.pem  etcd.csr  etcd-key.pem  etcd.pem
```

## 生成kubernetes证书

```
[root@k8s-master01 cert]# mkdir -p kubernetes/pki
```



### 生成kubernetes的根CA证书

用于生成所有kubernetes组件的根证书

#### 生成CA证书的csr配置文件

```
[root@k8s-master01 cert]# cat > ca-csr.json << EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names":[{
    "C": "CN",
    "ST": "Guangdong",
    "L": "ShenZen",
    "O": "k8s",
    "OU": "System"
  }]
}

EOF
```

#### 生成根CA证书

ca-key.pem

ca.pem

```
[root@k8s-master01 cert]# cfssl gencert -initca ca-csr.json | cfssljson -bare kubernetes/pki/ca
2026/03/17 09:07:31 [INFO] generating a new CA key and certificate from CSR
2026/03/17 09:07:31 [INFO] generate received request
2026/03/17 09:07:31 [INFO] received CSR
2026/03/17 09:07:31 [INFO] generating key: ecdsa-256
2026/03/17 09:07:31 [INFO] encoded CSR
2026/03/17 09:07:31 [INFO] signed certificate with serial number 443922227141496974782714312347149085754908554819
[root@k8s-master01 cert]# ls -al kubernetes/pki/
total 12
drwxr-xr-x 2 root root  52 Mar 17 09:07 .
drwxr-xr-x 3 root root  17 Mar 17 09:07 ..
-rw-r--r-- 1 root root 428 Mar 17 09:07 ca.csr
-rw------- 1 root root 227 Mar 17 09:07 ca-key.pem
-rw-r--r-- 1 root root 700 Mar 17 09:07 ca.pem

```

### api-server证书生成

#### 生成apiserver的csr.json配置

10.96.0.1是k8s的service网段，如果需要更新k8s的service网段，则需要将这个地址 修改为service网段的第一个地址

由于该证书后续被 kubernetes master 集群使用，所以上面分别指定了 etcd 集群、 kubernetes master 集群的主机 IP 和 kubernetes 服务的服务 IP（一般是 kube-apiserver 指定的 service-cluster-ip-range 网段的第一个IP，如 10.96.0.1

```
[root@k8s-master01 cert]# cat > apiserver-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "10.96.0.1",
    "127.0.0.1",
    "k8s-master01,k8s-master02,k8s-master03,k8s-master04,k8s-master05",
    "k8s-master-lb",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [{
    "C": "CN",
    "ST": "Guangdong",
    "L": "ShenZhen",
    "O": "k8s",
    "OU": "System"
  }]
} 
EOF
```

#### 生成apiserver的证书文件

apiserver-key.pem

apiserver.pem

```
[root@k8s-master01 cert]# cfssl gencert \
-ca=kubernetes/pki/ca.pem \
-ca-key=kubernetes/pki/ca-key.pem \
-config=ca-config.json \
-profile=kubernetes \
apiserver-csr.json | cfssljson -bare kubernetes/pki/apiserver
2026/03/17 10:16:37 [INFO] generate received request
2026/03/17 10:16:37 [INFO] received CSR
2026/03/17 10:16:37 [INFO] generating key: rsa-2048
2026/03/17 10:16:37 [INFO] encoded CSR
2026/03/17 10:16:37 [INFO] signed certificate with serial number 129553495624043992532703371750863240638602022662
[root@k8s-master01 cert]# ls -al kubernetes/pki/
total 24
drwxr-xr-x 2 root root  119 Mar 17 10:16 .
drwxr-xr-x 3 root root   17 Mar 17 09:56 ..
-rw-r--r-- 1 root root 1350 Mar 17 10:16 apiserver.csr
-rw------- 1 root root 1675 Mar 17 10:16 apiserver-key.pem
-rw-r--r-- 1 root root 1708 Mar 17 10:16 apiserver.pem
-rw-r--r-- 1 root root 1005 Mar 17 09:56 ca.csr
-rw------- 1 root root 1679 Mar 17 09:56 ca-key.pem
-rw-r--r-- 1 root root 1314 Mar 17 09:56 ca.pem

```

### 生成apiserver的聚合证书

#### 生成apiserver的聚合证书CA证书

front-proxy-ca-key.pem

front-proxy-ca.pem



```
[root@k8s-master01 cert]# cat > front-proxy-ca-csr.json << EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names":[{
    "C": "CN",
    "ST": "Guangdong",
    "L": "ShenZen",
    "O": "k8s",
    "OU": "System"
  }]
}

EOF

[root@k8s-master01 cert]# cfssl gencert -initca front-proxy-ca-csr.json | cfssljson -bare kubernetes/pki/front-proxy-ca
2026/03/17 10:23:41 [INFO] generating a new CA key and certificate from CSR
2026/03/17 10:23:41 [INFO] generate received request
2026/03/17 10:23:41 [INFO] received CSR
2026/03/17 10:23:41 [INFO] generating key: rsa-2048
2026/03/17 10:23:41 [INFO] encoded CSR
2026/03/17 10:23:41 [INFO] signed certificate with serial number 282658679111484294974379596229818989674583490760

[root@k8s-master01 cert]# ls -al kubernetes/pki/
total 36
drwxr-xr-x 2 root root  201 Mar 17 10:23 .
drwxr-xr-x 3 root root   17 Mar 17 09:56 ..
-rw-r--r-- 1 root root 1350 Mar 17 10:16 apiserver.csr
-rw------- 1 root root 1675 Mar 17 10:16 apiserver-key.pem
-rw-r--r-- 1 root root 1708 Mar 17 10:16 apiserver.pem
-rw-r--r-- 1 root root 1005 Mar 17 09:56 ca.csr
-rw------- 1 root root 1679 Mar 17 09:56 ca-key.pem
-rw-r--r-- 1 root root 1314 Mar 17 09:56 ca.pem
-rw-r--r-- 1 root root 1005 Mar 17 10:23 front-proxy-ca.csr
-rw------- 1 root root 1671 Mar 17 10:23 front-proxy-ca-key.pem
-rw-r--r-- 1 root root 1314 Mar 17 10:23 front-proxy-ca.pem

```



#### 生成apiserver的聚合证书客户端证书

front-proxy-client.pem

front-proxy-client-key.pem

```
[root@k8s-master01 cert]# cat > front-proxy-client-csr.json << EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names":[{
    "C": "CN",
    "ST": "Guangdong",
    "L": "ShenZen",
    "O": "k8s",
    "OU": "System"
  }]
}
EOF
[root@k8s-master01 cert]# cfssl gencert \
-ca=kubernetes/pki/front-proxy-ca.pem \
-ca-key=kubernetes/pki/front-proxy-ca-key.pem \
-config=ca-config.json \
-profile=kubernetes \
front-proxy-client-csr.json | cfssljson -bare kubernetes/pki/front-proxy-client
2026/03/17 10:35:37 [INFO] generate received request
2026/03/17 10:35:37 [INFO] received CSR
2026/03/17 10:35:37 [INFO] generating key: rsa-2048
2026/03/17 10:35:37 [INFO] encoded CSR
2026/03/17 10:35:37 [INFO] signed certificate with serial number 133228315521253084897746875404954754587465427159
2026/03/17 10:35:37 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").

[root@k8s-master01 cert]# ls -al kubernetes/pki/
total 48
drwxr-xr-x 2 root root  295 Mar 17 10:35 .
drwxr-xr-x 3 root root   17 Mar 17 09:56 ..
-rw-r--r-- 1 root root 1350 Mar 17 10:16 apiserver.csr
-rw------- 1 root root 1675 Mar 17 10:16 apiserver-key.pem
-rw-r--r-- 1 root root 1708 Mar 17 10:16 apiserver.pem
-rw-r--r-- 1 root root 1005 Mar 17 09:56 ca.csr
-rw------- 1 root root 1679 Mar 17 09:56 ca-key.pem
-rw-r--r-- 1 root root 1314 Mar 17 09:56 ca.pem
-rw-r--r-- 1 root root 1005 Mar 17 10:32 front-proxy-ca.csr
-rw------- 1 root root 1675 Mar 17 10:32 front-proxy-ca-key.pem
-rw-r--r-- 1 root root 1314 Mar 17 10:32 front-proxy-ca.pem
-rw-r--r-- 1 root root 1005 Mar 17 10:35 front-proxy-client.csr
-rw------- 1 root root 1675 Mar 17 10:35 front-proxy-client-key.pem
-rw-r--r-- 1 root root 1338 Mar 17 10:35 front-proxy-client.pem


```

### 生成controller-manager证书

controller-manager.pem

controller-manager-key.pem

```
cat > manager-csr.json << EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names":[{
    "C": "CN",
    "ST": "Guangdong",
    "L": "ShenZen",
    "O": "system:kube-controller-manager",
    "OU": "System"
  }]
}
EOF
```

```
[root@k8s-master01 cert]# cfssl gencert \
-ca=kubernetes/pki/ca.pem \
-ca-key=kubernetes/pki/ca-key.pem \
-config=ca-config.json \
-profile=kubernetes \
manager-csr.json | cfssljson -bare kubernetes/pki/controller-manager
2026/03/17 10:40:38 [INFO] generate received request
2026/03/17 10:40:38 [INFO] received CSR
2026/03/17 10:40:38 [INFO] generating key: rsa-2048
2026/03/17 10:40:38 [INFO] encoded CSR
2026/03/17 10:40:38 [INFO] signed certificate with serial number 236698870072873424652801826747359170241587018116
2026/03/17 10:40:38 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").

[root@k8s-master01 cert]# ls -al kubernetes/pki/ | grep control
-rw-r--r-- 1 root root 1005 Mar 17 10:40 controller-manager.csr
-rw------- 1 root root 1679 Mar 17 10:40 controller-manager-key.pem
-rw-r--r-- 1 root root 1338 Mar 17 10:40 controller-manager.pem

```

### 配置controller-manager的kubeconfig文件

#### 设置一个集群

```
[root@k8s-master01 cert]# kubectl config set-cluster kubernetes \
--certificate-authority=/etc/kubernetes/pki/ca.pem \
--embed-certs=true \
--server=https://192.168.1.110:8443 \
--kubeconfig=/etc/kubernetes/controller-manager.kubeconfig
```

#### 设置一个用户

```
[root@k8s-master01 cert]# kubectl config set-credentials system:kube-controller-manager \
--client-certificate=/etc/kubernetes/pki/controller-manager.pem \
--client-key=/etc/kubernetes/pki/controller-manager-key.pem \
--embed-certs=true \
--kubeconfig=/etc/kubernetes/controller-manager.kubeconfig
```

#### 设置一个环境，一个上下文

```
[root@k8s-master01 cert]# kubectl config set-context system:kube-controller-manager@kubernetes \
--cluster=kubenetes \
--user=system.kube-controller-manager \
--kubeconfig=/etc/kubernetes/controller-manager.kubeconfig
```

#### 使用某个环境当作默认环境

```
[root@k8s-master01 cert]# kubectl config use-context system:kube-controller-manager@kubernetes \
--kubeconfig=/etc/kubernetes/controller-manager.kubeconfig

```

### 生成scheduler证书



```
[root@k8s-master01 cert]# cat > scheduler-csr.json << EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names":[{
    "C": "CN",
    "ST": "Guangdong",
    "L": "ShenZen",
    "O": "system:kube-scheduler",
    "OU": "System"
  }]
}
EOF
```



```
[root@k8s-master01 cert]# cfssl gencert \
-ca=kubernetes/pki/ca.pem \
-ca-key=kubernetes/pki/ca-key.pem \
-config=ca-config.json \
-profile=kubernetes \
scheduler-csr.json | cfssljson -bare kubernetes/pki/scheduler
```



### 配置scheduler的kubeconfig

```
[root@k8s-master01 cert]# kubectl config set-cluster kubernetes \
--certificate-authority=/etc/kubernetes/pki/ca.pem \
--embed-certs=true \
--server=https://192.168.1.110:8443 \
--kubeconfig=/etc/kubernetes/scheduler.kubeconfig


[root@k8s-master01 cert]# kubectl config set-credentials system:kube-scheduler \
--client-certificate=/etc/kubernetes/pki/scheduler.pem \
--client-key=/etc/kubernetes/pki/scheduler-key.pem \
--embed-certs=true \
--kubeconfig=/etc/kubernetes/scheduler.kubeconfig


[root@k8s-master01 cert]# kubectl config set-context system:kube-scheduler@kubernetes \
--cluster=kubenetes \
--user=system.kube-controller-manager \
--kubeconfig=/etc/kubernetes/scheduler.kubeconfig




[root@k8s-master01 cert]# kubectl config use-context system:kube-scheduler@kubernetes \
--kubeconfig=/etc/kubernetes/scheduler.kubeconfig
```

### admin证书生成

```
[root@k8s-master01 cert]# cat > admin-csr.json << EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names":[{
    "C": "CN",
    "ST": "Guangdong",
    "L": "ShenZen",
    "O": "system:masters",
    "OU": "System"
  }]
}
EOF

[root@k8s-master01 cert]# cfssl gencert \
-ca=kubernetes/pki/ca.pem \
-ca-key=kubernetes/pki/ca-key.pem \
-config=ca-config.json \
-profile=kubernetes \
admin-csr.json | cfssljson -bare kubernetes/pki/admin

```



### 配置admin的kubeconfig文件 

```
[root@k8s-master01 cert]# kubectl config set-cluster kubernetes \
--certificate-authority=/etc/kubernetes/pki/ca.pem \
--embed-certs=true \
--server=https://192.168.1.110:8443 \
--kubeconfig=/etc/kubernetes/admin.kubeconfig


[root@k8s-master01 cert]# kubectl config set-credentials kubernetes-admin \
--client-certificate=/etc/kubernetes/pki/admin.pem \
--client-key=/etc/kubernetes/pki/admin-key.pem \
--embed-certs=true \
--kubeconfig=/etc/kubernetes/admin.kubeconfig


[root@k8s-master01 cert]# kubectl config set-context system:kubernetes-admin@kubernetes \
--cluster=kubenetes \
--user=system.kube-admin \
--kubeconfig=/etc/kubernetes/admin.kubeconfig


[root@k8s-master01 cert]# kubectl config use-context system:kubernetes-admin@kubernetes \
--kubeconfig=/etc/kubernetes/admin.kubeconfig

```

### 生成ServiceAccount的key

```
[root@k8s-master01 cert]#openssl genrsa -out kubernetes/pki/sa.key 2048
Generating RSA private key, 2048 bit long modulus
.....................................................................................................................................+++
.........................+++
e is 65537 (0x10001)

[root@k8s-master01 cert]#openssl rsa -in kubernetes/pki/sa.key -pubout -out kubernetes/pki/sa.pub
writing RSA key

```

## 查看证书文件

```
[root@k8s-master03 ~]# ls /etc/kubernetes/pki/
admin.csr      apiserver-key.pem  ca.pem                      front-proxy-ca.csr      front-proxy-client-key.pem  scheduler.csr
admin-key.pem  apiserver.pem      controller-manager.csr      front-proxy-ca-key.pem  front-proxy-client.pem      scheduler-key.pem
admin.pem      ca.csr             controller-manager-key.pem  front-proxy-ca.pem      sa.key                      scheduler.pem
apiserver.csr  ca-key.pem         controller-manager.pem      front-proxy-client.csr  sa.pub

[root@k8s-master03 ~]# ls /etc/kubernetes/pki/ | wc -l
23

```





```
kubectl config set-cluster kubernetes \
     --certificate-authority=/etc/kubernetes/pki/ca.pem \
     --embed-certs=true \
     --server=https://192.168.1.110:8443 \
     --kubeconfig=/etc/kubernetes/controller-manager.kubeconfig
     
kubectl config set-context system:kube-controller-manager@kubernetes \
    --cluster=kubernetes \
    --user=system:kube-controller-manager \
    --kubeconfig=/etc/kubernetes/controller-manager.kubeconfig
    
    
kubectl config set-credentials system:kube-controller-manager \
   --client-certificate=/etc/kubernetes/pki/controller-manager.pem \
   --client-key=/etc/kubernetes/pki/controller-manager-key.pem \
   --embed-certs=true \
   --kubeconfig=/etc/kubernetes/controller-manager.kubeconfig
   
kubectl config use-context system:kube-controller-manager@kubernetes \
     --kubeconfig=/etc/kubernetes/controller-manager.kubeconfig
     
     
     
     
     
     

kubectl config set-cluster kubernetes \
     --certificate-authority=/etc/kubernetes/pki/ca.pem \
     --embed-certs=true \
     --server=https://192.168.1.110:8443 \
     --kubeconfig=/etc/kubernetes/scheduler.kubeconfig
     
kubectl config set-credentials system:kube-scheduler \
     --client-certificate=/etc/kubernetes/pki/scheduler.pem \
     --client-key=/etc/kubernetes/pki/scheduler-key.pem \
     --embed-certs=true \
     --kubeconfig=/etc/kubernetes/scheduler.kubeconfig
     
kubectl config set-context system:kube-scheduler@kubernetes \
     --cluster=kubernetes \
     --user=system:kube-scheduler \
     --kubeconfig=/etc/kubernetes/scheduler.kubeconfig
     
kubectl config use-context system:kube-scheduler@kubernetes \
     --kubeconfig=/etc/kubernetes/scheduler.kubeconfig
     
     
     
  
kubectl config set-cluster kubernetes     \
  --certificate-authority=/etc/kubernetes/pki/ca.pem     \
  --embed-certs=true     \
  --server=https://192.168.1.110:8443     \
  --kubeconfig=/etc/kubernetes/admin.kubeconfig
  
kubectl config set-credentials kubernetes-admin  \
  --client-certificate=/etc/kubernetes/pki/admin.pem     \
  --client-key=/etc/kubernetes/pki/admin-key.pem     \
  --embed-certs=true     \
  --kubeconfig=/etc/kubernetes/admin.kubeconfig
  
kubectl config set-context kubernetes-admin@kubernetes    \
  --cluster=kubernetes     \
  --user=kubernetes-admin     \
  --kubeconfig=/etc/kubernetes/admin.kubeconfig
  
kubectl config use-context kubernetes-admin@kubernetes  --kubeconfig=/etc/kubernetes/admin.kubeconfig




kubectl config set-cluster kubernetes     \
  --certificate-authority=/etc/kubernetes/pki/ca.pem     \
  --embed-certs=true     \
  --server=https://192.168.1.110:8443     \
  --kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig
  
kubectl config set-credentials kube-proxy  \
  --client-certificate=/etc/kubernetes/pki/kube-proxy.pem     \
  --client-key=/etc/kubernetes/pki/kube-proxy-key.pem     \
  --embed-certs=true     \
  --kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig
  
kubectl config set-context kube-proxy@kubernetes    \
  --cluster=kubernetes     \
  --user=kube-proxy     \
  --kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig
  
kubectl config use-context kube-proxy@kubernetes  --kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig





```

