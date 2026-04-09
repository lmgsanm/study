# cfssl证书生成-ETCD

> 证书地址 [cfssl下载](https://github.com/cloudflare/cfssl)

## 一. 创建CA证书

### 1. ca配置文件`ca-config.json`

> 主要作用就是，不同组件证书的形式，有效期是不一样的，因此，在ca配置中心，应该有一个配置文件，来具体的配置

```
{
    "signing": {
        "default": {
            "expiry": "876000h"
        },
        "profiles": {
            "etcd": {
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ],
                "expiry": "876000h"
            }
        }
    }
}
```

字段说明:

- “ca-config.json”：可以定义多个 profiles，分别指定不同的过期时间、使用场景等参数；后续在签名证书时使用某个profile；
- “signing”：表示该证书可用于签名其它证书；生成的ca.pem证书中CA=TRUE；
- “server auth”：表示client可以用该 CA 对server提供的证书进行验证；
- “client auth”：表示server可以用该 CA 对client提供的证书进行验证；

### 2. ca证书签名请求`ca-csr.json`

> 就是申请证书的人，你得把你的基本信息告诉证书颁发中心吧，证书颁发中心，根据你填写的基本信息，来生成你的证书。

```
{
    "CN": "etcd",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "fuzhou",
            "L": "fuzhou",
            "O": "etcd",
            "OU": "System"
        }
    ]
}
```

参数说明:

- “CN”：Common Name，etcd 从证书中提取该字段作为请求的用户名 (User Name)；浏览器使用该字段验证网站是否合法；
- “O”：Organization，etcd 从证书中提取该字段作为请求用户所属的组 (Group)；

> 这两个参数在后面的kubernetes启用RBAC模式中很重要，因为需要设置kubelet、admin等角色权限，那么在配置证书的时候就必须配置对了，”在etcd这两个参数没太大的重要意义，跟着配置就好。”

### 3. 生成ca证书和私钥

```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

> 生成`ca.csr`,`ca-key.pem`,`ca.pem`

## 二. 颁发证书

### 1. etcd-csr.json

> tcd组件的基本信息,认证中心根据这个文件，生成证书

```
{
    "CN": "etcd",
    "hosts": [
        "127.0.0.1",
        "172.16.91.195"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "fuzhou",
            "L": "fuzhou",
            "O": "etcd",
            "OU": "System"
        }
    ]
}
```

- 如果 hosts 字段不为空则需要指定授权使用该证书的IP或域名列表，由于该证书后续被 etcd 集群使用，所以填写IP即可。因为本次部署etcd是单台，那么则需要填写单台的IP地址即可。
- ‘CN’，kube-apiserver从证书中提取该字段作为请求的用户名 (User Name)；浏览器使用该字段验证网站是否合法;
- “names”值实际上是名称对象的列表。每个名称对象应至少包含一个“C”，“L”，“O”，“OU”或“ST”值（或这些的任意组合）。这些值是：
  - “C”：国家 该”hosts”是可以使用该证书域名列表。
  - “L”：地区或城市（如城市或城镇名称）
  - “O”：组织 Organization，kube-apiserver从证书中提取该字段作为请求用户所属的组 (Group)；
  - “OU”：组织单位，如负责拥有密钥的部门; 它也可以用于“做生意”（DBS）的名称
  - “ST”：州或省

### 2. 生成etcd证书

```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=etcd etcd-csr.json | cfssljson -bare etcd
```

> > 生成`ca.csr`,`ca-key.pem`,`ca.pem`