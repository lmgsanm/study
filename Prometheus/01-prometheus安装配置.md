## 安装

### 软件安装

将prometheus及promtool拷贝到/usr/sbin/目录，将赋予执行权限

### 目录创建

创建如下登上，并授予monitoring用户权限

1. /data/prometheus		##prometheus数据存储目录
2. /etc/prometheus/         ##prometheus配置文件目录

### systemctl管理

- /usr/lib/systemd/system/prometheus.service

```
[Unit]
Description=Prometheus Server

[Service]
User=monitoring
EnvironmentFile=/etc/sysconfig/prometheus
ExecStart=/usr/sbin/prometheus $OPTIONS
Restart=always
RestartSec=30s

[Install]
WantedBy=multi-user.target
```

- /etc/sysconfig/prometheus

```
OPTIONS="--web.listen-address :19090 \
--config.file /etc/prometheus/prometheus.yml  \
--web.enable-lifecycle \
--web.enable-admin-api \
--storage.tsdb.path /data/prometheus \
--storage.tsdb.retention.time 180d \
--storage.tsdb.no-lockfile \
--query.max-concurrency 10000 \
--web.console.templates /etc/prometheus/consoles \
--web.console.libraries /etc/prometheus/console_libraries \
--log.level info"
```

执行如下命令使生效并设置开机启动：

systemctl daemon-reload    ##加载/usr/lib/systemd/system/prometheus.service使其生效

systemctl enable prometheus.service      设置prometheus服务开机自启动



## 配置

### 配置目录结构

```
tree -d /etc/prometheus/
/etc/prometheus/
├── backup
├── console_libraries
├── consoles
├── probe_files
├── rules
│   ├── backup
│   └── backup_rules
├── sd_files
└── test
```

### prometheus.yml

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
           - 99.248.10.89:19093
#           - 192.168.0.4:19093
#           - 192.168.0.5:19093
#           - 192.168.0.6:19093
#
# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  - "rules/*.yml"
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
        - sd_files/*.yml
  - job_name: 'blackbox'
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
    file_sd_configs:
      - files:
        - probe_files/*.yml

  - job_name: "federate"
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="map"}'
        - '{job="map-a-prod"}'
        - '{job="map-b-prod"}'
        - '{job="css"}'
        - '{job="sdc"}'
        - '{job="muse-sasac"}'
        - '{job="sco"}'
        - '{job="yxs02-prod"}'
        - '{job="cfs-prod"}'
        - '{job="public"}'
        - '{job="cos"}'
        - '{job="usecar"}'
        - '{job="zchf"}'
        - '{job="yunxing"}'
        - '{job="szqy"}'
        - '{__name__=~"job:.*"}'
    static_configs:
      - targets:
        - 99.248.1.212:29090
        - 99.248.10.187:19090
        - 99.248.10.180:19090 
        - 99.248.10.213:19090 
        - 99.248.10.156:19090 
        - 99.222.1.32:19090 

```

### instance配置

sd_files/monitor.yml

```
- targets:
  - 192.168.0.2:19100
  labels:
    job: devops
    sub_job: monitor
    module: prometheus
    sub_module: prometheus
    env: PRD
    ipaddr: 192.168.0.2
    hostname: prd-monitor-prom-01
    region: SHC
    account: mbc_prod@mbcloud.com#devops
    vpc_name: devops

- targets:
  - 192.168.0.3:19100
  labels:
    job: devops
    sub_job: monitor
    module: prometheus
    sub_module: prometheus
    env: PRD
    ipaddr: 192.168.0.3
    hostname: prd-monitor-prom-02
    region: SHC
    account: mbc_prod@mbcloud.com#devops
    vpc_name: devops

```

### rules配置

rules/rule_linux_cos_prd_172.16.112.2:19100.yml

```
groups:
- name: "agent status"
  rules:
  - alert: "监控客户端状态异常"
    expr: up{instance="172.16.112.2:19100",job="cos"} == 0
    for: 1m
    labels:
      severity: 严重告警
    annotations:
      summary: "监控客户端异常"
      description: "【当前agent状态：{{ $value }}】（状态为0表示不正常）\n  系统名称：{{ $labels.job }}\n  环境名称：{{ $labels.env }}\n  主机IP地址：{{ $labels.ipaddr }}\n  系统模块名称：{{ $labels.module }}\n  主机名称：{{ $labels.hostname }}\n  主机所属区域：{{ $labels.region }}\n  管理账户：{{ $labels.account }}\n  vpc名称：{{ $labels.vpc_name }}】"

- name: "memory used"
  rules:
  - alert: "内存使用率超过阈值"
    expr: floor(((node_memory_MemTotal_bytes{instance="172.16.112.2:19100",job="cos"} - node_memory_MemAvailable_bytes{instance="172.16.112.2:19100",job="cos"}) / (node_memory_MemTotal_bytes{instance="172.16.112.2:19100",job="cos"} )) * 100) >= 90
    for: 1m
    labels:
      severity: 严重告警
    annotations:
      summary: "内存使用率 >=90%"
      description: "【当前内存使用率为：{{ $value }}%】\n  系统名称：{{ $labels.job }}\n  环境名称：{{ $labels.env }}\n  主机IP地址：{{ $labels.ipaddr }}\n  系统模块名称：{{ $labels.module }}\n  主机名称：{{ $labels.hostname }}\n  主机所属区域：{{ $labels.region }}\n  管理账户：{{ $labels.account }}\n  vpc名称：{{ $labels.vpc_name }}】"

- name: "cpu used"
  rules:
  - alert: "CPU使用率超过阈值"
    expr: floor(100 - (avg by (instance,ipaddr,account,job,sub_job,module,sub_module,vpc_name,hostname,region,env) (irate(node_cpu_seconds_total{mode="idle",instance="172.16.112.2:19100",job="cos"}[5m])))*100) >= 80
    for: 1m
    labels:
      severity: 严重告警
    annotations:
      summary: "CPU使用率 >=80%"
      description: "【当前CPU使用率为：{{ $value }}%】\n    系统名称：{{ $labels.job }}\n  环境名称：{{ $labels.env }}\n  主机IP地址：{{ $labels.ipaddr }}\n  系统模块名称：{{ $labels.module }}\n  主机名称：{{ $labels.hostname }}\n  主机所属区域：{{ $labels.region }}\n  管理账户：{{ $labels.account }}\n  vpc名称：{{ $labels.vpc_name }}】"

- name: "disk used"
  rules:
  - alert: "磁盘分区使用率超过阈值"
    expr: floor(100 -(node_filesystem_avail_bytes{instance="172.16.112.2:19100",job="cos",fstype=~"ext2|ext3|ext4|xfs"} / node_filesystem_size_bytes{instance="172.16.112.2:19100",job="cos",fstype=~"ext2|ext3|ext4|xfs"}) *100) >= 90
    for: 1m
    labels:
      severity: 严重告警
    annotations:
      summary: "磁盘分区{{ $labels.mountpoint }}使用率 >=90%"
      description: "【当前分区名为：{{ $labels.mountpoint }}，分区当前使用率为：{{ $value }}%】\n    系统名称：{{ $labels.job }}\n  环境名称：{{ $labels.env }}\n  主机IP地址：{{ $labels.ipaddr }}\n  系统模块名称：{{ $labels.module }}\n  主机名称：{{ $labels.hostname }}\n  主机所属区域：{{ $labels.region }}\n  管理账户：{{ $labels.account }}\n  vpc名称：{{ $labels.vpc_name }}】"
```



## 运维

### 服务重启

systemctl restart prometheus.service

### 配置重加载

curl -X POST http://127.0.0.1:19090/-/reload

### 数据存储

tree  /data/prometheus/

```
tree /data/prometheus/
/data/prometheus/
├── 01GCGYG4ZRGXVG45VWZ3Z0486Y
│   ├── chunks
│   │   └── 000001
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GD2AP97X24A3HV0GJBTRQARW
│   ├── chunks
│   │   └── 000001
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GDKPW6F8FZZPKDQSYKG9EB0G
│   ├── chunks
│   │   └── 000001
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GE531ZRENHWYCF8K17XR9NEH
│   ├── chunks
│   │   └── 000001
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GEPF80C5F7GERN9DH37E55RW
│   ├── chunks
│   │   ├── 000001
│   │   └── 000002
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GF7VDPA0DVV99Q68KBG65756
│   ├── chunks
│   │   ├── 000001
│   │   └── 000002
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GFS7KNF88ED6WT9KXE7401DW
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   └── 000003
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GGAKSJQ997Z3YV9BKYAQZSFS
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   └── 000003
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GGVZZBKH2G8MNWNNTQSNKJX6
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   └── 000003
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GHDC5984BD47NMBZWDRN1B34
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   └── 000003
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GHYRB3EST3SC3ZP8T5QFK2HR
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   └── 000003
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GJG4H1ZHRKXSX3CHC4NGDMFZ
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   └── 000003
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GK1GQ22X6TW6VEFJMYP6Z25B
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   └── 000004
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GKJWWT99R8TJ9MNNYFPXE1PN
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   └── 000004
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GM492SJ1CHNF2V4TJF7E501F
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   └── 000004
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GMNNAETASBKN8WY4RZ7CKVKN
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   ├── 000004
│   │   ├── 000005
│   │   ├── 000006
│   │   ├── 000007
│   │   ├── 000008
│   │   └── 000009
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GN71GE2WVGFZ9FJC7E60SV6D
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   ├── 000004
│   │   ├── 000005
│   │   ├── 000006
│   │   ├── 000007
│   │   ├── 000008
│   │   ├── 000009
│   │   ├── 000010
│   │   ├── 000011
│   │   ├── 000012
│   │   └── 000013
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GNRDPA6TFA0EJG41XC0KMBR6
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   ├── 000004
│   │   ├── 000005
│   │   ├── 000006
│   │   ├── 000007
│   │   ├── 000008
│   │   ├── 000009
│   │   ├── 000010
│   │   ├── 000011
│   │   ├── 000012
│   │   └── 000013
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GP9SW0DBFGSH8VFZ3G5TV7QD
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   ├── 000004
│   │   ├── 000005
│   │   ├── 000006
│   │   ├── 000007
│   │   ├── 000008
│   │   ├── 000009
│   │   ├── 000010
│   │   ├── 000011
│   │   ├── 000012
│   │   └── 000013
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GPV62182940TJ79XZRRTDQW1
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   ├── 000004
│   │   ├── 000005
│   │   ├── 000006
│   │   ├── 000007
│   │   ├── 000008
│   │   ├── 000009
│   │   ├── 000010
│   │   ├── 000011
│   │   ├── 000012
│   │   └── 000013
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GQCJ7N2749R8KKF76QGMZC11
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   ├── 000004
│   │   ├── 000005
│   │   ├── 000006
│   │   ├── 000007
│   │   ├── 000008
│   │   ├── 000009
│   │   ├── 000010
│   │   ├── 000011
│   │   ├── 000012
│   │   └── 000013
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GQXYDJ21SMJZ6VW2QAJQHJVH
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   ├── 000004
│   │   ├── 000005
│   │   ├── 000006
│   │   ├── 000007
│   │   ├── 000008
│   │   ├── 000009
│   │   ├── 000010
│   │   ├── 000011
│   │   ├── 000012
│   │   └── 000013
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GRFAKQX5P0HC1K4C1W7PYVXN
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   ├── 000004
│   │   ├── 000005
│   │   ├── 000006
│   │   ├── 000007
│   │   ├── 000008
│   │   ├── 000009
│   │   ├── 000010
│   │   ├── 000011
│   │   ├── 000012
│   │   └── 000013
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GS0PSCRX0TGC28K6EE3ZWD0M
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   ├── 000004
│   │   ├── 000005
│   │   ├── 000006
│   │   ├── 000007
│   │   ├── 000008
│   │   ├── 000009
│   │   ├── 000010
│   │   ├── 000011
│   │   ├── 000012
│   │   └── 000013
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GSJ2ZF85QDQJGV3F1HSWAQ2F
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   ├── 000004
│   │   ├── 000005
│   │   ├── 000006
│   │   ├── 000007
│   │   ├── 000008
│   │   ├── 000009
│   │   ├── 000010
│   │   ├── 000011
│   │   ├── 000012
│   │   └── 000013
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GT3F53GVDQM0AQ7BVRS4GFM0
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   ├── 000004
│   │   ├── 000005
│   │   ├── 000006
│   │   ├── 000007
│   │   ├── 000008
│   │   ├── 000009
│   │   ├── 000010
│   │   ├── 000011
│   │   ├── 000012
│   │   └── 000013
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GTMVASFPBC8CRY687M34XZHG
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   ├── 000004
│   │   ├── 000005
│   │   ├── 000006
│   │   ├── 000007
│   │   ├── 000008
│   │   ├── 000009
│   │   ├── 000010
│   │   ├── 000011
│   │   ├── 000012
│   │   └── 000013
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GTTMP9MG9NX46J0DAKAWY2YV
│   ├── chunks
│   │   ├── 000001
│   │   ├── 000002
│   │   ├── 000003
│   │   ├── 000004
│   │   └── 000005
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GTWJF6BCJ3WCEED3G839TYQP
│   ├── chunks
│   │   ├── 000001
│   │   └── 000002
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GTYG8TCHCMAJVR43TRHYW75R
│   ├── chunks
│   │   ├── 000001
│   │   └── 000002
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GTYXZHY1DS5RGTTB9PVM361Z
│   ├── chunks
│   │   └── 000001
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GTZ4V9BBRE1DWQERPH3VBRNH
│   ├── chunks
│   │   └── 000001
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GTZ4VK6GW8GP1J4KJ200178M
│   ├── chunks
│   │   └── 000001
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GTZBQ0BQWN3C2N5KVPERJTQJ
│   ├── chunks
│   │   └── 000001
│   ├── index
│   ├── meta.json
│   └── tombstones
├── 01GTZJJQCT0KXQ4XTYWHY44WE6
│   ├── chunks
│   │   └── 000001
│   ├── index
│   ├── meta.json
│   └── tombstones
├── chunks_head
│   └── 000938
├── pushgateway.data
├── queries.active
└── wal
    ├── 00004176
    ├── 00004177
    ├── 00004178
    └── checkpoint.00004175
        └── 00000000
```

- 01GTZJJQCT0KXQ4XTYWHY44WE6：blockID，为一个完整的block

- meta.json：block的元数据
- chunks：目录下存储每一个block中的所有chunks，目录个每个文件都是一个chunk数据单元
- index：索引文件
- tombstones：数据删除记录文件，记录删除信息
- chunks_head：磁盘内在映射头块
- checkpoint：wal的检查点数据
- wal：保存内存最近的数据，默认为2小时内数据



### 命令行使用

####  prometheus

```
usage: prometheus [<flags>]

The Prometheus monitoring server

Flags:
  -h, --help                     Show context-sensitive help (also try --help-long and --help-man).
      --version                  Show application version.
      --config.file="prometheus.yml"  
                                 Prometheus configuration file path.
      --web.listen-address="0.0.0.0:9090"  
                                 Address to listen on for UI, API, and telemetry.
      --web.config.file=""       [EXPERIMENTAL] Path to configuration file that can enable TLS or authentication.
      --web.read-timeout=5m      Maximum duration before timing out read of the request, and closing idle connections.
      --web.max-connections=512  Maximum number of simultaneous connections.
      --web.external-url=<URL>   The URL under which Prometheus is externally reachable (for example, if Prometheus is served via a reverse proxy). Used for generating relative and
                                 absolute links back to Prometheus itself. If the URL has a path portion, it will be used to prefix all HTTP endpoints served by Prometheus. If omitted,
                                 relevant URL components will be derived automatically.
      --web.route-prefix=<path>  Prefix for the internal routes of web endpoints. Defaults to path of --web.external-url.
      --web.user-assets=<path>   Path to static asset directory, available at /user.
      --web.enable-lifecycle     Enable shutdown and reload via HTTP request.
      --web.enable-admin-api     Enable API endpoints for admin control actions.
      --web.enable-remote-write-receiver  
                                 Enable API endpoint accepting remote write requests.
      --web.console.templates="consoles"  
                                 Path to the console template directory, available at /consoles.
      --web.console.libraries="console_libraries"  
                                 Path to the console library directory.
      --web.page-title="Prometheus Time Series Collection and Processing Server"  
                                 Document title of Prometheus instance.
      --web.cors.origin=".*"     Regex for CORS origin. It is fully anchored. Example: 'https?://(domain1|domain2)\.com'
      --storage.tsdb.path="data/"  
                                 Base path for metrics storage. Use with server mode only.
      --storage.tsdb.retention=STORAGE.TSDB.RETENTION  
                                 [DEPRECATED] How long to retain samples in storage. This flag has been deprecated, use "storage.tsdb.retention.time" instead. Use with server mode only.
      --storage.tsdb.retention.time=STORAGE.TSDB.RETENTION.TIME  
                                 How long to retain samples in storage. When this flag is set it overrides "storage.tsdb.retention". If neither this flag nor "storage.tsdb.retention" nor
                                 "storage.tsdb.retention.size" is set, the retention time defaults to 15d. Units Supported: y, w, d, h, m, s, ms. Use with server mode only.
      --storage.tsdb.retention.size=STORAGE.TSDB.RETENTION.SIZE  
                                 Maximum number of bytes that can be stored for blocks. A unit is required, supported units: B, KB, MB, GB, TB, PB, EB. Ex: "512MB". Based on powers-of-2,
                                 so 1KB is 1024B. Use with server mode only.
      --storage.tsdb.no-lockfile  
                                 Do not create lockfile in data directory. Use with server mode only.
      --storage.tsdb.allow-overlapping-blocks  
                                 Allow overlapping blocks, which in turn enables vertical compaction and vertical query merge. Use with server mode only.
      --storage.tsdb.head-chunks-write-queue-size=0  
                                 Size of the queue through which head chunks are written to the disk to be m-mapped, 0 disables the queue completely. Experimental. Use with server mode
                                 only.
      --storage.agent.path="data-agent/"  
                                 Base path for metrics storage. Use with agent mode only.
      --storage.agent.wal-compression  
                                 Compress the agent WAL. Use with agent mode only.
      --storage.agent.retention.min-time=STORAGE.AGENT.RETENTION.MIN-TIME  
                                 Minimum age samples may be before being considered for deletion when the WAL is truncated Use with agent mode only.
      --storage.agent.retention.max-time=STORAGE.AGENT.RETENTION.MAX-TIME  
                                 Maximum age samples may be before being forcibly deleted when the WAL is truncated Use with agent mode only.
      --storage.agent.no-lockfile  
                                 Do not create lockfile in data directory. Use with agent mode only.
      --storage.remote.flush-deadline=<duration>  
                                 How long to wait flushing sample on shutdown or config reload.
      --storage.remote.read-sample-limit=5e7  
                                 Maximum overall number of samples to return via the remote read interface, in a single query. 0 means no limit. This limit is ignored for streamed response
                                 types. Use with server mode only.
      --storage.remote.read-concurrent-limit=10  
                                 Maximum number of concurrent remote read calls. 0 means no limit. Use with server mode only.
      --storage.remote.read-max-bytes-in-frame=1048576  
                                 Maximum number of bytes in a single frame for streaming remote read response types before marshalling. Note that client might have limit on frame size as
                                 well. 1MB as recommended by protobuf by default. Use with server mode only.
      --rules.alert.for-outage-tolerance=1h  
                                 Max time to tolerate prometheus outage for restoring "for" state of alert. Use with server mode only.
      --rules.alert.for-grace-period=10m  
                                 Minimum duration between alert and restored "for" state. This is maintained only for alerts with configured "for" time greater than grace period. Use with
                                 server mode only.
      --rules.alert.resend-delay=1m  
                                 Minimum amount of time to wait before resending an alert to Alertmanager. Use with server mode only.
      --alertmanager.notification-queue-capacity=10000  
                                 The capacity of the queue for pending Alertmanager notifications. Use with server mode only.
      --query.lookback-delta=5m  The maximum lookback duration for retrieving metrics during expression evaluations and federation. Use with server mode only.
      --query.timeout=2m         Maximum time a query may take before being aborted. Use with server mode only.
      --query.max-concurrency=20  
                                 Maximum number of queries executed concurrently. Use with server mode only.
      --query.max-samples=50000000  
                                 Maximum number of samples a single query can load into memory. Note that queries will fail if they try to load more samples than this into memory, so this
                                 also limits the number of samples a query can return. Use with server mode only.
      --enable-feature= ...      Comma separated feature names to enable. Valid options: agent, exemplar-storage, expand-external-labels, memory-snapshot-on-shutdown, promql-at-modifier,
                                 promql-negative-offset, promql-per-step-stats, remote-write-receiver (DEPRECATED), extra-scrape-metrics, new-service-discovery-manager, auto-gomaxprocs.
                                 See https://prometheus.io/docs/prometheus/latest/feature_flags/ for more details.
      --log.level=info           Only log messages with the given severity or above. One of: [debug, info, warn, error]
      --log.format=logfmt        Output format of log messages. One of: [logfmt, json]

```



#### promtool

```
usage: promtool [<flags>] <command> [<args> ...]

Tooling for the Prometheus monitoring system.

Flags:
  -h, --help                 Show context-sensitive help (also try --help-long and --help-man).
      --version              Show application version.
      --enable-feature= ...  Comma separated feature names to enable (only PromQL related). See https://prometheus.io/docs/prometheus/latest/feature_flags/ for the options and more
                             details.

Commands:
  help [<command>...]
    Show help.

  check service-discovery [<flags>] <config-file> <job>
    Perform service discovery for the given job name and report the results, including relabeling.

  check config [<flags>] <config-files>...
    Check if the config files are valid or not.

  check web-config <web-config-files>...
    Check if the web config files are valid or not.

  check rules [<flags>] <rule-files>...
    Check if the rule files are valid or not.

  check metrics
    Pass Prometheus metrics over stdin to lint them for consistency and correctness.

    examples:

    $ cat metrics.prom | promtool check metrics

    $ curl -s http://localhost:9090/metrics | promtool check metrics

  query instant [<flags>] <server> <expr>
    Run instant query.

  query range [<flags>] <server> <expr>
    Run range query.

  query series --match=MATCH [<flags>] <server>
    Run series query.

  query labels [<flags>] <server> <name>
    Run labels query.

  debug pprof <server>
    Fetch profiling debug information.

  debug metrics <server>
    Fetch metrics debug information.

  debug all <server>
    Fetch all debug information.

  test rules <test-rule-file>...
    Unit tests for rules.

  tsdb bench write [<flags>] [<file>]
    Run a write performance benchmark.

  tsdb analyze [<flags>] [<db path>] [<block id>]
    Analyze churn, label pair cardinality and compaction efficiency.

  tsdb list [<flags>] [<db path>]
    List tsdb blocks.

  tsdb dump [<flags>] [<db path>]
    Dump samples from a TSDB.

  tsdb create-blocks-from openmetrics <input file> [<output directory>]
    Import samples from OpenMetrics input and produce TSDB blocks. Please refer to the storage docs for more details.

  tsdb create-blocks-from rules --start=START [<flags>] <rule-files>...
    Create blocks of data for new recording rules.

```

示例

```
promtool check config /etc/prometheus/prometheus.yml
promtool check rules /etc/prometheus/rules/rule_linux_devops_prd_192.168.0.5\:19100.yml
```

## web使用

web访问地址：http://IP:PORT

## grafana使用

 /usr/local/grafana/bin/grafana-server \
-homepath /usr/local/grafana \
-config /usr/local/grafana/conf/config.ini \
&