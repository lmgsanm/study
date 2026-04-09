## 安装

### 软件安装

将alertmanager及amtool拷贝到/usr/sbin/目录，将赋予执行权限

### 目录创建

创建如下目录，并授予monitoring用户权限

1. /data/prometheus/pushgateway.data		##pushgateway数据存储目录

### systemctl管理

- /usr/lib/systemd/system/pushgateway.service

```
[Unit]
Description=Pushgateway Server

[Service]
User=monitoring
EnvironmentFile=/etc/sysconfig/pushgateway
ExecStart=/usr/sbin/pushgateway $OPTIONS
Restart=always
RestartSec=30s

[Install]
WantedBy=multi-user.target
```

- /etc/sysconfig/pushgateway

```
OPTIONS="--web.listen-address :19091 \
--web.enable-lifecycle \
--web.enable-admin-api \
--persistence.file /data/prometheus/pushgateway.data \
--persistence.interval 5m \
--log.level info"
```

执行如下命令使生效并设置开机启动：

systemctl daemon-reload    ##加载/usr/lib/systemd/system/pushgateway.service使其生效

systemctl enable pushgateway.service      设置pushgateway服务开机自启动

## 配置

## 运维

### 服务重启

systemctl restart alertmanager.service

### 配置重加载

curl -X POST http://127.0.0.1:19093/-/reload

### 命令行使用

```
usage: pushgateway [<flags>]

The Pushgateway

Flags:
  -h, --help                     Show context-sensitive help (also try --help-long and --help-man).
      --web.config.file=""       [EXPERIMENTAL] Path to configuration file that can enable TLS or authentication.
      --web.listen-address=":9091"  
                                 Address to listen on for the web interface, API, and telemetry.
      --web.telemetry-path="/metrics"  
                                 Path under which to expose metrics.
      --web.external-url=        The URL under which the Pushgateway is externally reachable.
      --web.route-prefix=""      Prefix for the internal routes of web endpoints. Defaults to the path of --web.external-url.
      --web.enable-lifecycle     Enable shutdown via HTTP request.
      --web.enable-admin-api     Enable API endpoints for admin control actions.
      --persistence.file=""      File to persist metrics. If empty, metrics are only kept in memory.
      --persistence.interval=5m  The minimum interval at which to write out the persistence file.
      --push.disable-consistency-check  
                                 Do not check consistency of pushed metrics. DANGEROUS.
      --log.level=info           Only log messages with the given severity or above. One of: [debug, info, warn, error]
      --log.format=logfmt        Output format of log messages. One of: [logfmt, json]
      --version                  Show application version.

```



## 使用

###  web管理

web访问地址：http://IP:PORT

#### 数据推送1

```shell
echo "lmgsanmtest01  2000" | curl --data-binary @- http://127.0.0.1:19091/metrics/job/lmgsanm
echo "lmgsanmtest01  2000" | curl --data-binary @- http://127.0.0.1:19091/metrics/job/lmgsanm/instance/lmgsanmin
echo "pushgatewytest  2023" | curl --data-binary @- http://127.0.0.1:19091/metrics/job/lmgsanm/instance/lmgsanmin
```

查询结果

```
curl -s http://127.0.0.1:19091/metrics| grep lmgsanm
# TYPE lmgsanmtest01 untyped
lmgsanmtest01{instance="",job="lmgsanm"} 2000
lmgsanmtest01{instance="lmgsanmin",job="lmgsanm"} 2000
push_failure_time_seconds{instance="",job="lmgsanm"} 0
push_failure_time_seconds{instance="lmgsanmin",job="lmgsanm"} 0
push_time_seconds{instance="",job="lmgsanm"} 1.6782550029180849e+09
push_time_seconds{instance="lmgsanmin",job="lmgsanm"} 1.6782550683805487e+09
pushgatewytest{instance="lmgsanmin",job="lmgsanm"} 2023
```

curl -X GET http://127.0.0.1:19091/api/v1/metrics

#### 数据推送2

```
cat << EOF | curl --data-binary @- http://127.0.0.1:19091/metrics/job/lmgsanm/instance/lmgsanm_instance/moudel/test
limugen 2003
aget 2017
pi 3.14
EOF
```

查询结果

```
curl -s http://127.0.0.1:19091/metrics| grep lmgsanm            
aget{instance="lmgsanm_instance",job="lmgsanm",moudel="test"} 2017
limugen{instance="lmgsanm_instance",job="lmgsanm",moudel="test"} 2003
pi{instance="lmgsanm_instance",job="lmgsanm",moudel="test"} 3.14
push_failure_time_seconds{instance="lmgsanm_instance",job="lmgsanm",moudel="test"} 0
push_time_seconds{instance="lmgsanm_instance",job="lmgsanm",moudel="test"} 1.6782559395064163e+09

```

curl -X GET http://127.0.0.1:19091/api/v1/metrics

#### 数据删除

```
curl -X DELETE http://127.0.0.1:19091/metrics/job/lmgsanm/instance/lmgsanmin
curl -X DELETE http://127.0.0.1:19091/metrics/job/lmgsanm
```

