### 软件安装

将alertmanager及amtool拷贝到/usr/sbin/目录，将赋予执行权限

### 目录创建

创建如下目录，并授予alertmanager用户权限

1. /alertmanager		##alertmanager数据存储目录
2. /etc/alertmanager/         ##alertmanager配置文件目录

### systemctl管理

- /usr/lib/systemd/system/alertmanager.service

```
[Unit]
Description=Alertmanager Server

[Service]
User=alertmanager
EnvironmentFile=/etc/sysconfig/alertmanager
ExecStart=/usr/sbin/alertmanager $OPTIONS
Restart=always
RestartSec=30s

[Install]
WantedBy=multi-user.target
```

- /etc/sysconfig/alertmanager  ##集群配置

```
PTIONS="--web.listen-address :19093 \
--storage.path /alertmanager \
--data.retention 240h \
--config.file /etc/alertmanager/alertmanager.yml \
--cluster.listen-address 0.0.0.0:19094 \
--cluster.peer 192.168.0.2:19094 \
--log.level info"
```

```
OPTIONS="--web.listen-address :19093 \
--storage.path /alertmanager \
--data.retention 240h \
--config.file /etc/alertmanager/alertmanager.yml \
--cluster.listen-address 0.0.0.0:19094 \
--cluster.peer 192.168.0.2:19094 \
--log.level info"

```

```
OPTIONS="--web.listen-address :19093 \
--storage.path /alertmanager \
--data.retention 240h \
--config.file /etc/alertmanager/alertmanager.yml \
--cluster.listen-address 0.0.0.0:19094 \
--cluster.peer 192.168.0.2:19094 \
--log.level info"
```

执行如下命令使生效并设置开机启动：

systemctl daemon-reload    ##加载/usr/lib/systemd/system/alertmanager.service使其生效

systemctl enable alertmanager.service      设置prometheus服务开机自启动

## 配置

/etc/alertmanager/alertmanager.yml

```
route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h 
  receiver: 'web.hook'
receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://192.168.0.5:8999/webhook?key=dbeb3023-057a-45d7-9954-59e2858401eb'
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
```



## 运维

### 服务重启

systemctl restart alertmanager.service

### 配置重加载

curl -X POST http://127.0.0.1:19093/-/reload

##  web管理

web访问地址：http://IP:PORT