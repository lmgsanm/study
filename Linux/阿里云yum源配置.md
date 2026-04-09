# 阿里巴巴开源镜像站地址

https://mirrors.aliyun.com/

# 相关仓库

- CentOS过期源（centos-vault）：https://developer.aliyun.com/mirror/centos-vault
- CentOS arm源（centos-altarch）：https://developer.aliyun.com/mirror/centos-altarch/
- CentOS Stream源（centos-stream）：https://developer.aliyun.com/mirror/centos-stream
- CentOS debuginfo源（centos-debuginfo）：https://developer.aliyun.com/mirror/centos-debuginfo/

# 配置方法

## 1. 备份初始yum文件

```
mkdir /etc/yum.repos.d/backup && mv /etc/yum.repos.d/CentOS-* /etc/yum.repos.d/backup/
```



## 2. 下载新的 CentOS-Base.repo 到 /etc/yum.repos.d/

### centos8

```
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo
yum install -y https://mirrors.aliyun.com/epel/epel-release-latest-8.noarch.rpm
```

### centos7

```
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
```



### centos6

```
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-vault-6.10.repo
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-vault-6.10.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-archive-6.repo
```

## 3.刷新yum源

```
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/epel.repo
yum clean all && yum makecache
```

