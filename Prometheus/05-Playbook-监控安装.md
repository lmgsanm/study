ansible-playbook -i hosts --key-file ../ssh_key-kp-fy7d7rhi main.yml

./run.sh 



# 一、前置准备

## 1.1	创建prometheus服务器

## 1.2	创建ssh密钥并挂载

## 1.3	ssh密钥上传

如密钥文件名称为kp-fy7d7rhi,将该密钥上传到/root/目录

### 1.3.1	修改密钥名称

```
mv kp-fy7d7rhi ssh_key
```

### 1.3.2	修改密钥权限

```
chmod 400 ssh_key
```

## 1.4	上传playbook制品

将prometheus-playbook.tar.gz下载或上传到/root/目录下

## 1.5	部署规划

| 序号 | 组件名称      | IP地址       |
| ---- | ------------- | ------------ |
| 1    | prometheus    | 172.16.16.8  |
| 2    | node_exporter | 172.16.100.6 |
| 3    | node_exporter | 172.16.16.24 |
| 4    | node_exporter | 172.16.25.6  |
| 5    | alertmanager  | 172.16.16.5  |



# 二、ansible安装

## 2.1	YUM源配置

### 2.1.1	yum源地址配置

分别telnet 10.248.1.53或99.248.1.108的80端口。

如telnet 10.248.1.53 80可通，则执行

```
echo "10.248.1.53 nexus3-cicd.apps.test.openshift.com" >> /etc/hosts
```

如telnet 99.248.1.108 80可通，则执行

```
echo "99.248.1.108 nexus3-cicd.apps.test.openshift.com" >> /etc/hosts
```

### 2.1.2	repo配置

```
mkdir -p /etc/yum.repos.d/backup && mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/
cat > /etc/yum.repos.d/base.repo << EOF
[base]
name=CentOS-$releasever - Base
baseurl=http://nexus3-cicd.apps.test.openshift.com/repository/yum/centos/$releasever/os/$basearch/
enabled=1
gpgcheck=0

[updates]
name=CentOS-$releasever - Updates
baseurl=http://nexus3-cicd.apps.test.openshift.com/repository/yum/centos/$releasever/updates/$basearch/
enabled=1
gpgcheck=0

[extras]
name=CentOS-$releasever - Extras
baseurl=http://nexus3-cicd.apps.test.openshift.com/repository/yum/centos/$releasever/extras/$basearch/
enabled=1
gpgcheck=0

[epel]
name=CentOS-$releasever - Epel
baseurl=http://nexus3-cicd.apps.test.openshift.com/repository/yum/epel/$releasever/$basearch/
enabled=1
gpgcheck=0

[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=http://nexus3-cicd.apps.test.openshift.com/repository/yum/docker-ce/linux/centos/7/$basearch/stable
enabled=1
gpgcheck=0

[kubernetes]
name=Kubernetes
baseurl=http://nexus3-cicd.apps.test.openshift.com/repository/yum/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0

[openshift]
name=Openshift
baseurl=http://nexus3-cicd.apps.test.openshift.com/repository/yum/centos/$releasever/paas/$basearch/openshift-origin311/
gpgcheck=0
EOF
```

### 2.1.3	刷新yum源

```
yum clean all && yum makecache
```

## 2.2	ansible安装

```
yum -y install ansible
rpm -qa | grep ansible
```

# 三、软件安装

## 3.1	解压制品包

```
tar xzf prometheus-playbook.tar.gz
```

## 3.2	修改hosts文件

注：该文件为执行ansible脚本的服务器主机清单文件，并非/etc/hosts文件。

按部署规划，如部署prometheus（必选）的IP地址为172.16.16.8，部署node_exporter（必选）的IP地址为172.16.100.6、172.16.16.24、172.16.25.6，部署alertmanager（可选）的IP地址为172.16.16.5，则hosts配置文件如下

```
[prometheus]
172.16.16.8
[node_exporter]
172.16.100.6
172.16.16.24
172.16.25.6
[alertmanager]
172.16.16.5
```

## 3.3	prometheus安装

### 进入prometheus目录

```
cd prometheus
```

### 执行run.sh

```
./run.sh
```

## 3.4	node_exporterp安装

### 进入node_exporter目录

```
cd node_exporter
```

### 执行run.sh

```
./run.sh
```

## 3.5	alertmanager安装

### 进入alertmanager目录

```
cd alertmanager
```

### 执行run.sh

```
./run.sh
```

# 四、监控配置

## 4.1主机监控配置

### 4.1.1	进入主机监控配置目录

```
cd /etc/prometheus/sd_files/
```

### 4.1.2	创建监控配置文件

```
mkdir cfs.yml
```

注：该配置文件以系统名称，即job名称命名

### 4.1.3	监控配置模板

```
- targets:
  - xxx.xxx.xxx.xxx:19100
  labels:
    job: xxx
    sub_job: xxx
    module: xxx
    sub_module: xxx
    env: xxx
    ipaddr: xxx.xxx.xxx.xxx
    hostname: xxx
    region: xxx
    account: xxx
    vpc_name: xxx
```

其中xxx.xxx.xxx.xxx:19100为被监控主机实例名称，即IP:PORT

labels命名规范参考“监控平台规范指引.docx”

### 4.1.4	热加载promethes服务

执行如下命令重新热加载

```
curl -X POST http://127.0.0.1:19090/-/reload
```



## 4.2	TCP监控配置

TCP监控配置文件为/etc/prometheus/prometheus.yml

### 4.2.1	配置示例

```
# my global config
global:
  scrape_interval: 60s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 60s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:19090"]
  - job_name: "pushgateway"
    static_configs:
      - targets: ["localhost:19091"]
  - job_name: "file_sd_configs"
    file_sd_configs:
      - files:
        - /etc/prometheus/sd_files/*.yml
  - job_name: 'sco_blackbox'
    metrics_path: /probe
    params:
      module: [tcp_connect]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 127.0.0.1:19115
    static_configs:
      - targets:
        - 172.16.25.6:9876 
        - 172.16.25.6:10911
        - 172.16.25.6:10912
        - 172.16.25.6:19100
        labels:
          job: sco
          sub_job: middleware
          module: rocketmq
          sub_module: all
          env: sit
          ipaddr: 172.16.25.6
          hostname: sco-rocketmq
          region: SHC
          account: dec@cmbyc.com
          vpc_name: dec
```

如上配置，该配置监控了172.16.25.6上的9876、10911、10912、10913、19100端口，job_name为job_blackbox命名，如需监控多台主机，则配置多个job_name

### 4.2.2	检查配置文件

执行如下命令，检查prometheus.yml配置文件是否存在语法错误

```
promtool check config /etc/prometheus/prometheus.yml
```

如输出结果如下，说明prometheus.yml没有语法错误

```
Checking /etc/prometheus/prometheus.yml
 SUCCESS: /etc/prometheus/prometheus.yml is valid prometheus config file syntax
```

### 4.2.3	热加载promethes服务

执行如下命令重新热加载

```
curl -X POST http://127.0.0.1:19090/-/reload
```