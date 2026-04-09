# 一、部署架构

## 1.1软件版本

### 1.1.1	jdk

jdk1.8.0_202

### 1.1.2	elasticsearch

elasticsearch-6.8.23

### 1.1.3	logstash

logstash-6.8.23

### 1.1.4	kibana

kibana-6.8.23

### 1.1.5	filebeat

filebeat-6.8.23

### 1.1.6	apm-server

apm-server-6.8.23

## 1.2服务器版本

### 1.2.1	内核版本

3.10.0-957.27.2.el7.x86_64

### 1.2.2	系统版本

CentOS Linux release 7.6.1810 (Core)

## 1.3服务器IP

| IP地址       | 主机名 | 部署软件                            | 发布端口 |
| ------------ | ------ | ----------------------------------- | -------- |
| 172.25.149.4 | node01 | elasticsearch、kibana、filebeat     |          |
| 172.25.149.5 | node02 | elasticsearch、logstash             |          |
| 172.25.149.6 | node01 | elasticsearch、apm-server、logstash |          |

# 二、应用部署

## 2.1	部署前置操作

### 2.1.1	主机名设置

分别设置好主机名

#### 172.25.149.4

```
hostnamectl set-hostname node01
echo "node01" > /etc/hostname
```



#### 172.25.149.5

```
hostnamectl set-hostname node02
echo "node02" > /etc/hostname
```



#### 172.25.149.6

```
hostnamectl set-hostname node03
echo "node03" > /etc/hostname
```



### 2.1.2	hosts文件修改

将主机和IP地址映射关系定入/etc/hosts配置文件

```
cat >> /etc/hosts << EOF
172.25.149.4 node01
172.25.149.5 node02
172.25.149.6 node03
EOF
```

```
cat /etc/hosts
```

*127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4*
*::1         localhost localhost.localdomain localhost6 localhost6.localdomain6*
*172.25.149.4 node01*
*172.25.149.5 node02*
*172.25.149.6 node03*



## 2.2	jdk部署

### 2.2.1	部署说明

三个节点都必须部署jdk

### 2.2.2	部署步骤

#### 解压软件包

```
cd ~
tar xzf jdk-8u202-linux-x64.tar.gz /usr/local
ln -s /usr/local/jdk1.8.0_202/ /usr/local/java
```



#### 添加环境变量

```
cat > /etc/profile.d/jdk.sh << EOF
export JAVA_HOME=/usr/local/java
export CLASSPATH=:.\$JAVA_HOME/lib/dt.jar:$\JAVA_HOME/lib/tools.jar
export PATH=\$JAVA_HOME/bin:\$PATH
EOF
```

```
cat /etc/profile.d/jdk.sh
```

*export JAVA_HOME=/usr/local/java*
*export CLASSPATH=:.$JAVA_HOME/lib/dt.jar:$\JAVA_HOME/lib/tools.jar*
*export PATH=$JAVA_HOME/bin:$PATH*

#### 生效环境变更

source  /etc/profile.d/jdk.sh

#### 验证软件版本

```
java -version
```



*java version "1.7.0_80"*
*Java(TM) SE Runtime Environment (build 1.7.0_80-b15)*
*Java HotSpot(TM) 64-Bit Server VM (build 24.80-b11, mixed mode)*



## 2.3	elasticsearch部署

### 2.3.1	部署说明

三个节点都部署elasticsearch软件

### 2.3.2	准备工作

#### 创建es用户

```
useradd es
echo "es@#12345" | passwd --stdin es
```



### 2.3.3	部署步骤

#### 解压软件包

```
cd ~
tar xzf elasticsearch-6.8.23.tar.gz -C /usr/local
ln -s /usr/local/elasticsearch-6.8.23/ /usr/local/elasticsearch
chown -R es.es /usr/local/elasticsearch*
```



#### 修改jvm参数

##### jvm参数文件路径

/usr/local/elasticsearch/config/jvm.options

##### 需修改的参数

按实际的需求将jvm的内存配置进行修改

```
-Xms1g
-Xms1g
```

#### 修改elasticsearch环境变量

##### 环境变量文件路径

/usr/local/elasticsearch/bin/elasticsearch-env

##### 修改内容

在文件中第二行添加如下内容

```
export JAVA_HOME=/usr/local/java
```



#### 修改配置文件

##### 配置文件路径

/usr/local/elasticsearch/config/elasticsearch.yml

##### 需修改的内容

```
cluster.name: es-limugen
node.name: node01
path.data: /data/elasticsearch/data
path.logs: /data/elasticsearch/logs
bootstrap.memory_lock: true
network.host: 0.0.0.0
http.port: 9200
discovery.zen.ping.unicast.hosts: ["node01", "node02","node03"]
gateway.recover_after_nodes: 3
```



#### 启动elasticsearch

##### 创建目录并配置权限

```
mkdir -p /data/elasticsearch/data
mkdir -p /data/elasticsearch/logs
chown -R es.es /data/elasticsearch/
```



##### limits.conf文件修改

文件路径：/etc/security/limits.conf

添加如下内容

```
es soft    nofile         655360
es  hard    nofile       655360
es soft memlock unlimited
es hard memlock unlimited
```



##### 系统参数优化

文件路径：/etc/sysctl.conf

添加如下内容

```
vm.max_map_count=262144
```

执行如下命令使生效

```
sysctl -p
```



##### 使用es用户启动

```
su - es
```

```
/usr/local/elasticsearch/bin/elasticsearch &
```

###### 启动日志

*[1] 27534*
*[es@node01 ~]$ [2022-05-16T17:30:59,903][INFO ][o.e.e.NodeEnvironment    ] [node01] using [1] data paths, mounts [[/ (rootfs)]], net usable_space [52.5gb], net total_space [58.9gb], types [rootfs]*
*[2022-05-16T17:30:59,906][INFO ][o.e.e.NodeEnvironment    ] [node01] heap size [1007.3mb], compressed ordinary object pointers [true]*
*[2022-05-16T17:30:59,907][INFO ][o.e.n.Node               ] [node01] node name [node01], node ID [LVBGoOYpT56Dmi38o4Ofmg]*
*[2022-05-16T17:30:59,908][INFO ][o.e.n.Node               ] [node01] version[6.8.23], pid[27534], build[default/tar/4f67856/2022-01-06T21:30:50.087716Z], OS[Linux/3.10.0-957.27.2.el7.x86_64/amd64], JVM[Oracle Corporation/Java HotSpot(TM) 64-Bit Server VM/1.8.0_202/25.202-b08]*
*[2022-05-16T17:30:59,908][INFO ][o.e.n.Node               ] [node01] JVM arguments [-Xms1g, -Xmx1g, -XX:+UseConcMarkSweepGC, -XX:CMSInitiatingOccupancyFraction=75, -XX:+UseCMSInitiatingOccupancyOnly, -Des.networkaddress.cache.ttl=60, -Des.networkaddress.cache.negative.ttl=10, -XX:+AlwaysPreTouch, -Xss1m, -Djava.awt.headless=true, -Dfile.encoding=UTF-8, -Djna.nosys=true, -XX:-OmitStackTraceInFastThrow, -Dio.netty.noUnsafe=true, -Dio.netty.noKeySetOptimization=true, -Dio.netty.recycler.maxCapacityPerThread=0, -Dlog4j.shutdownHookEnabled=false, -Dlog4j2.disable.jmx=true, -Dlog4j2.formatMsgNoLookups=true, -Djava.io.tmpdir=/tmp/elasticsearch-7588154349172778729, -XX:+HeapDumpOnOutOfMemoryError, -XX:HeapDumpPath=data, -XX:ErrorFile=logs/hs_err_pid%p.log, -XX:+PrintGCDetails, -XX:+PrintGCDateStamps, -XX:+PrintTenuringDistribution, -XX:+PrintGCApplicationStoppedTime, -Xloggc:logs/gc.log, -XX:+UseGCLogFileRotation, -XX:NumberOfGCLogFiles=32, -XX:GCLogFileSize=64m, -Des.path.home=/usr/local/elasticsearch, -Des.path.conf=/usr/local/elasticsearch/config, -Des.distribution.flavor=default, -Des.distribution.type=tar]*
*[2022-05-16T17:31:02,700][INFO ][o.e.p.PluginsService     ] [node01] loaded module [aggs-matrix-stats]*
*[2022-05-16T17:31:02,701][INFO ][o.e.p.PluginsService     ] [node01] loaded module [analysis-common]*
*[2022-05-16T17:31:02,701][INFO ][o.e.p.PluginsService     ] [node01] loaded module [ingest-common]*
*[2022-05-16T17:31:02,701][INFO ][o.e.p.PluginsService     ] [node01] loaded module [ingest-geoip]*
*[2022-05-16T17:31:02,701][INFO ][o.e.p.PluginsService     ] [node01] loaded module [ingest-user-agent]*
*[2022-05-16T17:31:02,701][INFO ][o.e.p.PluginsService     ] [node01] loaded module [lang-expression]*
*[2022-05-16T17:31:02,701][INFO ][o.e.p.PluginsService     ] [node01] loaded module [lang-mustache]*
*[2022-05-16T17:31:02,701][INFO ][o.e.p.PluginsService     ] [node01] loaded module [lang-painless]*
*[2022-05-16T17:31:02,701][INFO ][o.e.p.PluginsService     ] [node01] loaded module [mapper-extras]*
*[2022-05-16T17:31:02,701][INFO ][o.e.p.PluginsService     ] [node01] loaded module [parent-join]*
*[2022-05-16T17:31:02,702][INFO ][o.e.p.PluginsService     ] [node01] loaded module [percolator]*
*[2022-05-16T17:31:02,702][INFO ][o.e.p.PluginsService     ] [node01] loaded module [rank-eval]*
*[2022-05-16T17:31:02,702][INFO ][o.e.p.PluginsService     ] [node01] loaded module [reindex]*
*[2022-05-16T17:31:02,702][INFO ][o.e.p.PluginsService     ] [node01] loaded module [repository-url]*
*[2022-05-16T17:31:02,702][INFO ][o.e.p.PluginsService     ] [node01] loaded module [transport-netty4]*
*[2022-05-16T17:31:02,702][INFO ][o.e.p.PluginsService     ] [node01] loaded module [tribe]*
*[2022-05-16T17:31:02,702][INFO ][o.e.p.PluginsService     ] [node01] loaded module [x-pack-ccr]*
*[2022-05-16T17:31:02,702][INFO ][o.e.p.PluginsService     ] [node01] loaded module [x-pack-core]*
*[2022-05-16T17:31:02,702][INFO ][o.e.p.PluginsService     ] [node01] loaded module [x-pack-deprecation]*
*[2022-05-16T17:31:02,702][INFO ][o.e.p.PluginsService     ] [node01] loaded module [x-pack-graph]*
*[2022-05-16T17:31:02,702][INFO ][o.e.p.PluginsService     ] [node01] loaded module [x-pack-ilm]*
*[2022-05-16T17:31:02,702][INFO ][o.e.p.PluginsService     ] [node01] loaded module [x-pack-logstash]*
*[2022-05-16T17:31:02,703][INFO ][o.e.p.PluginsService     ] [node01] loaded module [x-pack-ml]*
*[2022-05-16T17:31:02,703][INFO ][o.e.p.PluginsService     ] [node01] loaded module [x-pack-monitoring]*
*[2022-05-16T17:31:02,703][INFO ][o.e.p.PluginsService     ] [node01] loaded module [x-pack-rollup]*
*[2022-05-16T17:31:02,703][INFO ][o.e.p.PluginsService     ] [node01] loaded module [x-pack-security]*
*[2022-05-16T17:31:02,703][INFO ][o.e.p.PluginsService     ] [node01] loaded module [x-pack-sql]*
*[2022-05-16T17:31:02,703][INFO ][o.e.p.PluginsService     ] [node01] loaded module [x-pack-upgrade]*
*[2022-05-16T17:31:02,703][INFO ][o.e.p.PluginsService     ] [node01] loaded module [x-pack-watcher]*
*[2022-05-16T17:31:02,703][INFO ][o.e.p.PluginsService     ] [node01] no plugins loaded*
*[2022-05-16T17:31:07,324][INFO ][o.e.x.s.a.s.FileRolesStore] [node01] parsed [0] roles from file [/usr/local/elasticsearch/config/roles.yml]*
*[2022-05-16T17:31:08,356][INFO ][o.e.x.m.p.l.CppLogMessageHandler] [node01] [controller/27600] [Main.cc@114] controller (64 bit): Version 6.8.23 (Build 31256deab94add) Copyright (c) 2022 Elasticsearch BV*
*[2022-05-16T17:31:09,128][DEBUG][o.e.a.ActionModule       ] [node01] Using REST wrapper from plugin org.elasticsearch.xpack.security.Security*
*[2022-05-16T17:31:09,627][INFO ][o.e.d.DiscoveryModule    ] [node01] using discovery type [zen] and host providers [settings]*
*[2022-05-16T17:31:10,944][INFO ][o.e.n.Node               ] [node01] initialized*
*[2022-05-16T17:31:10,945][INFO ][o.e.n.Node               ] [node01] starting ...*
*[2022-05-16T17:31:11,150][INFO ][o.e.t.TransportService   ] [node01] publish_address {172.25.149.4:9300}, bound_addresses {[::]:9300}*
*[2022-05-16T17:31:11,222][INFO ][o.e.b.BootstrapChecks    ] [node01] bound or publishing to a non-loopback address, enforcing bootstrap checks*
*[2022-05-16T17:31:14,330][INFO ][o.e.c.s.MasterService    ] [node01] zen-disco-elected-as-master ([0] nodes joined), reason: new_master {node01}{LVBGoOYpT56Dmi38o4Ofmg}{7ysysnwgS3OnDX5WbOxK2A}{172.25.149.4}{172.25.149.4:9300}{ml.machine_memory=3973636096, xpack.installed=true, ml.max_open_jobs=20, ml.enabled=true}*
*[2022-05-16T17:31:14,337][INFO ][o.e.c.s.ClusterApplierService] [node01] new_master {node01}{LVBGoOYpT56Dmi38o4Ofmg}{7ysysnwgS3OnDX5WbOxK2A}{172.25.149.4}{172.25.149.4:9300}{ml.machine_memory=3973636096, xpack.installed=true, ml.max_open_jobs=20, ml.enabled=true}, reason: apply cluster state (from master [master {node01}{LVBGoOYpT56Dmi38o4Ofmg}{7ysysnwgS3OnDX5WbOxK2A}{172.25.149.4}{172.25.149.4:9300}{ml.machine_memory=3973636096, xpack.installed=true, ml.max_open_jobs=20, ml.enabled=true} committed version [1] source [zen-disco-elected-as-master ([0] nodes joined)]])*
*[2022-05-16T17:31:14,384][INFO ][o.e.h.n.Netty4HttpServerTransport] [node01] publish_address {172.25.149.4:9200}, bound_addresses {[::]:9200}*
*[2022-05-16T17:31:14,385][INFO ][o.e.n.Node               ] [node01] started*

###### 新节点加入日志

*[2022-05-16T17:32:52,124][INFO ][o.e.c.s.MasterService    ] [node01] zen-disco-node-join[{node02}{u7kX2PgdQjOqNva-bo04Og}{oKRYpztFTZWGevxHyf-3jg}{172.25.149.5}{172.25.149.5:9300}{ml.machine_memory=3973627904, ml.max_open_jobs=20, xpack.installed=true, ml.enabled=true}], reason: added {{node02}{u7kX2PgdQjOqNva-bo04Og}{oKRYpztFTZWGevxHyf-3jg}{172.25.149.5}{172.25.149.5:9300}{ml.machine_memory=3973627904, ml.max_open_jobs=20, xpack.installed=true, ml.enabled=true},}*
*[2022-05-16T17:32:52,183][INFO ][o.e.c.s.ClusterApplierService] [node01] added {{node02}{u7kX2PgdQjOqNva-bo04Og}{oKRYpztFTZWGevxHyf-3jg}{172.25.149.5}{172.25.149.5:9300}{ml.machine_memory=3973627904, ml.max_open_jobs=20, xpack.installed=true, ml.enabled=true},}, reason: apply cluster state (from master [master {node01}{LVBGoOYpT56Dmi38o4Ofmg}{7ysysnwgS3OnDX5WbOxK2A}{172.25.149.4}{172.25.149.4:9300}{ml.machine_memory=3973636096, xpack.installed=true, ml.max_open_jobs=20, ml.enabled=true} committed version [2] source [zen-disco-node-join[{node02}{u7kX2PgdQjOqNva-bo04Og}{oKRYpztFTZWGevxHyf-3jg}{172.25.149.5}{172.25.149.5:9300}{ml.machine_memory=3973627904, ml.max_open_jobs=20, xpack.installed=true, ml.enabled=true}]]])*
*[2022-05-16T17:32:52,196][WARN ][o.e.d.z.ElectMasterService] [node01] value for setting "discovery.zen.minimum_master_nodes" is too low. This can result in data loss! Please set it to at least a quorum of master-eligible nodes (current value: [-1], total number of master-eligible nodes used for publishing in this round: [2])*

#### 网页访问

http://172.25.149.4:9200/

```
{
  "name" : "node01",
  "cluster_name" : "es-limugen",
  "cluster_uuid" : "Sn0HWlNFSfKEvuJU6UDuTQ",
  "version" : {
    "number" : "6.8.23",
    "build_flavor" : "default",
    "build_type" : "tar",
    "build_hash" : "4f67856",
    "build_date" : "2022-01-06T21:30:50.087716Z",
    "build_snapshot" : false,
    "lucene_version" : "7.7.3",
    "minimum_wire_compatibility_version" : "5.6.0",
    "minimum_index_compatibility_version" : "5.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

### 2.3.4	文件信息

#### 2.3.4.1	文件目录文件

/usr/local/elasticsearch/

```
tree /usr/local/elasticsearch/
```

*/usr/local/elasticsearch/*
*├── bin*
*│   ├── elasticsearch*
*│   ├── elasticsearch.bat*
*│   ├── elasticsearch-certgen*
*│   ├── elasticsearch-certgen.bat*
*│   ├── elasticsearch-certutil*
*│   ├── elasticsearch-certutil.bat*
*│   ├── elasticsearch-cli*
*│   ├── elasticsearch-cli.bat*
*│   ├── elasticsearch-croneval*
*│   ├── elasticsearch-croneval.bat*
*│   ├── elasticsearch-env*
*│   ├── elasticsearch-env.bat*
*│   ├── elasticsearch-keystore*
*│   ├── elasticsearch-keystore.bat*
*│   ├── elasticsearch-migrate*
*│   ├── elasticsearch-migrate.bat*
*│   ├── elasticsearch-plugin*
*│   ├── elasticsearch-plugin.bat*
*│   ├── elasticsearch-saml-metadata*
*│   ├── elasticsearch-saml-metadata.bat*
*│   ├── elasticsearch-service.bat*
*│   ├── elasticsearch-service-mgr.exe*
*│   ├── elasticsearch-service-x64.exe*
*│   ├── elasticsearch-setup-passwords*
*│   ├── elasticsearch-setup-passwords.bat*
*│   ├── elasticsearch-shard*
*│   ├── elasticsearch-shard.bat*
*│   ├── elasticsearch-sql-cli*
*│   ├── elasticsearch-sql-cli-6.8.23.jar*
*│   ├── elasticsearch-sql-cli.bat*
*│   ├── elasticsearch-syskeygen*
*│   ├── elasticsearch-syskeygen.bat*
*│   ├── elasticsearch-translog*
*│   ├── elasticsearch-translog.bat*
*│   ├── elasticsearch-users*
*│   ├── elasticsearch-users.bat*
*│   ├── x-pack*
*│   │   ├── certgen*
*│   │   ├── certgen.bat*
*│   │   ├── certutil*
*│   │   ├── certutil.bat*
*│   │   ├── croneval*
*│   │   ├── croneval.bat*
*│   │   ├── migrate*
*│   │   ├── migrate.bat*
*│   │   ├── saml-metadata*
*│   │   ├── saml-metadata.bat*
*│   │   ├── setup-passwords*
*│   │   ├── setup-passwords.bat*
*│   │   ├── sql-cli*
*│   │   ├── sql-cli.bat*
*│   │   ├── syskeygen*
*│   │   ├── syskeygen.bat*
*│   │   ├── users*
*│   │   └── users.bat*
*│   ├── x-pack-env*
*│   ├── x-pack-env.bat*
*│   ├── x-pack-security-env*
*│   ├── x-pack-security-env.bat*
*│   ├── x-pack-watcher-env*
*│   └── x-pack-watcher-env.bat*
*├── config*
*│   ├── elasticsearch.yml*
*│   ├── jvm.options*
*│   ├── log4j2.properties*
*│   ├── role_mapping.yml*
*│   ├── roles.yml*
*│   ├── users*
*│   └── users_roles*
*├── lib*
*│   ├── elasticsearch-6.8.23.jar*
*│   ├── elasticsearch-cli-6.8.23.jar*
*│   ├── elasticsearch-core-6.8.23.jar*
*│   ├── elasticsearch-launchers-6.8.23.jar*
*│   ├── elasticsearch-secure-sm-6.8.23.jar*
*│   ├── elasticsearch-x-content-6.8.23.jar*
*│   ├── HdrHistogram-2.1.9.jar*
*│   ├── hppc-0.7.1.jar*
*│   ├── jackson-core-2.8.11.jar*
*│   ├── jackson-dataformat-cbor-2.8.11.jar*
*│   ├── jackson-dataformat-smile-2.8.11.jar*
*│   ├── jackson-dataformat-yaml-2.8.11.jar*
*│   ├── java-version-checker-6.8.23.jar*
*│   ├── jna-5.5.0.jar*
*│   ├── joda-time-2.10.10.jar*
*│   ├── jopt-simple-5.0.2.jar*
*│   ├── jts-core-1.15.0.jar*
*│   ├── log4j-1.2-api-2.17.1.jar*
*│   ├── log4j-api-2.17.1.jar*
*│   ├── log4j-core-2.17.1.jar*
*│   ├── lucene-analyzers-common-7.7.3.jar*
*│   ├── lucene-backward-codecs-7.7.3.jar*
*│   ├── lucene-core-7.7.3.jar*
*│   ├── lucene-grouping-7.7.3.jar*
*│   ├── lucene-highlighter-7.7.3.jar*
*│   ├── lucene-join-7.7.3.jar*
*│   ├── lucene-memory-7.7.3.jar*
*│   ├── lucene-misc-7.7.3.jar*
*│   ├── lucene-queries-7.7.3.jar*
*│   ├── lucene-queryparser-7.7.3.jar*
*│   ├── lucene-sandbox-7.7.3.jar*
*│   ├── lucene-spatial3d-7.7.3.jar*
*│   ├── lucene-spatial-7.7.3.jar*
*│   ├── lucene-spatial-extras-7.7.3.jar*
*│   ├── lucene-suggest-7.7.3.jar*
*│   ├── plugin-classloader-6.8.23.jar*
*│   ├── snakeyaml-1.17.jar*
*│   ├── spatial4j-0.7.jar*
*│   ├── t-digest-3.2.jar*
*│   └── tools*
*│       ├── plugin-cli*
*│       │   ├── bcpg-jdk15on-1.64.jar*
*│       │   ├── bcprov-jdk15on-1.64.jar*
*│       │   └── elasticsearch-plugin-cli-6.8.23.jar*
*│       └── security-cli*
*│           ├── bcpkix-jdk15on-1.64.jar*
*│           ├── bcprov-jdk15on-1.64.jar*
*│           └── elasticsearch-security-cli-6.8.23.jar*
*├── LICENSE.txt*
*├── logs*
*├── modules*
*│   ├── aggs-matrix-stats*
*│   │   ├── aggs-matrix-stats-client-6.8.23.jar*
*│   │   └── plugin-descriptor.properties*
*│   ├── analysis-common*
*│   │   ├── analysis-common-6.8.23.jar*
*│   │   └── plugin-descriptor.properties*
*│   ├── ingest-common*
*│   │   ├── elasticsearch-dissect-6.8.23.jar*
*│   │   ├── elasticsearch-grok-6.8.23.jar*
*│   │   ├── ingest-common-6.8.23.jar*
*│   │   ├── jcodings-1.0.12.jar*
*│   │   ├── joni-2.1.6.jar*
*│   │   └── plugin-descriptor.properties*
*│   ├── ingest-geoip*
*│   │   ├── geoip2-2.9.0.jar*
*│   │   ├── GeoLite2-ASN.mmdb*
*│   │   ├── GeoLite2-City.mmdb*
*│   │   ├── GeoLite2-Country.mmdb*
*│   │   ├── ingest-geoip-6.8.23.jar*
*│   │   ├── jackson-annotations-2.8.11.jar*
*│   │   ├── jackson-databind-2.8.11.6.jar*
*│   │   ├── maxmind-db-1.2.2.jar*
*│   │   ├── plugin-descriptor.properties*
*│   │   └── plugin-security.policy*
*│   ├── ingest-user-agent*
*│   │   ├── ingest-user-agent-6.8.23.jar*
*│   │   └── plugin-descriptor.properties*
*│   ├── lang-expression*
*│   │   ├── antlr4-runtime-4.5.1-1.jar*
*│   │   ├── asm-5.0.4.jar*
*│   │   ├── asm-commons-5.0.4.jar*
*│   │   ├── asm-tree-5.0.4.jar*
*│   │   ├── lang-expression-6.8.23.jar*
*│   │   ├── lucene-expressions-7.7.3.jar*
*│   │   ├── plugin-descriptor.properties*
*│   │   └── plugin-security.policy*
*│   ├── lang-mustache*
*│   │   ├── compiler-0.9.3.jar*
*│   │   ├── lang-mustache-client-6.8.23.jar*
*│   │   ├── plugin-descriptor.properties*
*│   │   └── plugin-security.policy*
*│   ├── lang-painless*
*│   │   ├── antlr4-runtime-4.5.3.jar*
*│   │   ├── asm-debug-all-5.1.jar*
*│   │   ├── elasticsearch-scripting-painless-spi-6.8.23.jar*
*│   │   ├── lang-painless-6.8.23.jar*
*│   │   ├── plugin-descriptor.properties*
*│   │   └── plugin-security.policy*
*│   ├── mapper-extras*
*│   │   ├── mapper-extras-6.8.23.jar*
*│   │   └── plugin-descriptor.properties*
*│   ├── parent-join*
*│   │   ├── parent-join-client-6.8.23.jar*
*│   │   └── plugin-descriptor.properties*
*│   ├── percolator*
*│   │   ├── percolator-client-6.8.23.jar*
*│   │   └── plugin-descriptor.properties*
*│   ├── rank-eval*
*│   │   ├── plugin-descriptor.properties*
*│   │   └── rank-eval-client-6.8.23.jar*
*│   ├── reindex*
*│   │   ├── commons-codec-1.10.jar*
*│   │   ├── commons-logging-1.1.3.jar*
*│   │   ├── elasticsearch-rest-client-6.8.23.jar*
*│   │   ├── elasticsearch-ssl-config-6.8.23.jar*
*│   │   ├── httpasyncclient-4.1.2.jar*
*│   │   ├── httpclient-4.5.2.jar*
*│   │   ├── httpcore-4.4.5.jar*
*│   │   ├── httpcore-nio-4.4.5.jar*
*│   │   ├── plugin-descriptor.properties*
*│   │   ├── plugin-security.policy*
*│   │   └── reindex-client-6.8.23.jar*
*│   ├── repository-url*
*│   │   ├── plugin-descriptor.properties*
*│   │   ├── plugin-security.policy*
*│   │   └── repository-url-6.8.23.jar*
*│   ├── transport-netty4*
*│   │   ├── netty-buffer-4.1.32.Final.jar*
*│   │   ├── netty-codec-4.1.32.Final.jar*
*│   │   ├── netty-codec-http-4.1.32.Final.jar*
*│   │   ├── netty-common-4.1.32.Final.jar*
*│   │   ├── netty-handler-4.1.32.Final.jar*
*│   │   ├── netty-resolver-4.1.32.Final.jar*
*│   │   ├── netty-transport-4.1.32.Final.jar*
*│   │   ├── plugin-descriptor.properties*
*│   │   ├── plugin-security.policy*
*│   │   └── transport-netty4-client-6.8.23.jar*
*│   ├── tribe*
*│   │   ├── plugin-descriptor.properties*
*│   │   └── tribe-6.8.23.jar*
*│   ├── x-pack-ccr*
*│   │   ├── LICENSE.txt*
*│   │   ├── NOTICE.txt*
*│   │   ├── plugin-descriptor.properties*
*│   │   ├── plugin-security.policy*
*│   │   └── x-pack-ccr-6.8.23.jar*
*│   ├── x-pack-core*
*│   │   ├── commons-codec-1.10.jar*
*│   │   ├── commons-logging-1.1.3.jar*
*│   │   ├── httpasyncclient-4.1.2.jar*
*│   │   ├── httpclient-4.5.2.jar*
*│   │   ├── httpcore-4.4.5.jar*
*│   │   ├── httpcore-nio-4.4.5.jar*
*│   │   ├── LICENSE.txt*
*│   │   ├── netty-buffer-4.1.32.Final.jar*
*│   │   ├── netty-codec-4.1.32.Final.jar*
*│   │   ├── netty-codec-http-4.1.32.Final.jar*
*│   │   ├── netty-common-4.1.32.Final.jar*
*│   │   ├── netty-handler-4.1.32.Final.jar*
*│   │   ├── netty-resolver-4.1.32.Final.jar*
*│   │   ├── netty-transport-4.1.32.Final.jar*
*│   │   ├── NOTICE.txt*
*│   │   ├── plugin-descriptor.properties*
*│   │   ├── plugin-security.policy*
*│   │   ├── transport-netty4-client-6.8.23.jar*
*│   │   ├── unboundid-ldapsdk-4.0.8.jar*
*│   │   └── x-pack-core-6.8.23.jar*
*│   ├── x-pack-deprecation*
*│   │   ├── LICENSE.txt*
*│   │   ├── NOTICE.txt*
*│   │   ├── plugin-descriptor.properties*
*│   │   ├── plugin-security.policy*
*│   │   └── x-pack-deprecation-6.8.23.jar*
*│   ├── x-pack-graph*
*│   │   ├── LICENSE.txt*
*│   │   ├── NOTICE.txt*
*│   │   ├── plugin-descriptor.properties*
*│   │   ├── plugin-security.policy*
*│   │   └── x-pack-graph-6.8.23.jar*
*│   ├── x-pack-ilm*
*│   │   ├── LICENSE.txt*
*│   │   ├── NOTICE.txt*
*│   │   ├── plugin-descriptor.properties*
*│   │   └── x-pack-ilm-6.8.23.jar*
*│   ├── x-pack-logstash*
*│   │   ├── LICENSE.txt*
*│   │   ├── NOTICE.txt*
*│   │   ├── plugin-descriptor.properties*
*│   │   ├── plugin-security.policy*
*│   │   └── x-pack-logstash-6.8.23.jar*
*│   ├── x-pack-ml*
*│   │   ├── elasticsearch-grok-6.8.23.jar*
*│   │   ├── icu4j-62.1.jar*
*│   │   ├── jcodings-1.0.12.jar*
*│   │   ├── joni-2.1.6.jar*
*│   │   ├── LICENSE.txt*
*│   │   ├── NOTICE.txt*
*│   │   ├── platform*
*│   │   │   ├── darwin-x86_64*
*│   │   │   │   └── controller.app*
*│   │   │   │       └── Contents*
*│   │   │   │           ├── CodeResources*
*│   │   │   │           ├── _CodeSignature*
*│   │   │   │           │   └── CodeResources*
*│   │   │   │           ├── Info.plist*
*│   │   │   │           ├── lib*
*│   │   │   │           │   ├── libboost_date_time-clang-darwin42-mt-1_65_1.dylib*
*│   │   │   │           │   ├── libboost_filesystem-clang-darwin42-mt-1_65_1.dylib*
*│   │   │   │           │   ├── libboost_iostreams-clang-darwin42-mt-1_65_1.dylib*
*│   │   │   │           │   ├── libboost_program_options-clang-darwin42-mt-1_65_1.dylib*
*│   │   │   │           │   ├── libboost_regex-clang-darwin42-mt-1_65_1.dylib*
*│   │   │   │           │   ├── libboost_system-clang-darwin42-mt-1_65_1.dylib*
*│   │   │   │           │   ├── libboost_thread-clang-darwin42-mt-1_65_1.dylib*
*│   │   │   │           │   ├── liblog4cxx.10.dylib*
*│   │   │   │           │   ├── libMlApi.dylib*
*│   │   │   │           │   ├── libMlConfig.dylib*
*│   │   │   │           │   ├── libMlCore.dylib*
*│   │   │   │           │   ├── libMlMaths.dylib*
*│   │   │   │           │   └── libMlModel.dylib*
*│   │   │   │           ├── MacOS*
*│   │   │   │           │   ├── autoconfig*
*│   │   │   │           │   ├── autodetect*
*│   │   │   │           │   ├── categorize*
*│   │   │   │           │   ├── controller*
*│   │   │   │           │   └── normalize*
*│   │   │   │           └── Resources*
*│   │   │   │               └── ml-en.dict*
*│   │   │   ├── linux-x86_64*
*│   │   │   │   ├── bin*
*│   │   │   │   │   ├── autoconfig*
*│   │   │   │   │   ├── autodetect*
*│   │   │   │   │   ├── categorize*
*│   │   │   │   │   ├── controller*
*│   │   │   │   │   └── normalize*
*│   │   │   │   ├── lib*
*│   │   │   │   │   ├── libapr-1.so.0*
*│   │   │   │   │   ├── libaprutil-1.so.0*
*│   │   │   │   │   ├── libboost_date_time-gcc62-mt-1_65_1.so.1.65.1*
*│   │   │   │   │   ├── libboost_filesystem-gcc62-mt-1_65_1.so.1.65.1*
*│   │   │   │   │   ├── libboost_iostreams-gcc62-mt-1_65_1.so.1.65.1*
*│   │   │   │   │   ├── libboost_program_options-gcc62-mt-1_65_1.so.1.65.1*
*│   │   │   │   │   ├── libboost_regex-gcc62-mt-1_65_1.so.1.65.1*
*│   │   │   │   │   ├── libboost_system-gcc62-mt-1_65_1.so.1.65.1*
*│   │   │   │   │   ├── libboost_thread-gcc62-mt-1_65_1.so.1.65.1*
*│   │   │   │   │   ├── libexpat.so.0*
*│   │   │   │   │   ├── libgcc_s.so.1*
*│   │   │   │   │   ├── liblog4cxx.so.10*
*│   │   │   │   │   ├── libMlApi.so*
*│   │   │   │   │   ├── libMlConfig.so*
*│   │   │   │   │   ├── libMlCore.so*
*│   │   │   │   │   ├── libMlMaths.so*
*│   │   │   │   │   ├── libMlModel.so*
*│   │   │   │   │   ├── libstdc++.so.6*
*│   │   │   │   │   └── libxml2.so.2*
*│   │   │   │   └── resources*
*│   │   │   │       └── ml-en.dict*
*│   │   │   └── windows-x86_64*
*│   │   │       ├── bin*
*│   │   │       │   ├── autoconfig.exe*
*│   │   │       │   ├── autodetect.exe*
*│   │   │       │   ├── boost_chrono-vc120-mt-1_65_1.dll*
*│   │   │       │   ├── boost_date_time-vc120-mt-1_65_1.dll*
*│   │   │       │   ├── boost_filesystem-vc120-mt-1_65_1.dll*
*│   │   │       │   ├── boost_iostreams-vc120-mt-1_65_1.dll*
*│   │   │       │   ├── boost_program_options-vc120-mt-1_65_1.dll*
*│   │   │       │   ├── boost_regex-vc120-mt-1_65_1.dll*
*│   │   │       │   ├── boost_system-vc120-mt-1_65_1.dll*
*│   │   │       │   ├── boost_thread-vc120-mt-1_65_1.dll*
*│   │   │       │   ├── categorize.exe*
*│   │   │       │   ├── controller.exe*
*│   │   │       │   ├── libapr-1.dll*
*│   │   │       │   ├── libapriconv-1.dll*
*│   │   │       │   ├── libaprutil-1.dll*
*│   │   │       │   ├── libMlApi.dll*
*│   │   │       │   ├── libMlConfig.dll*
*│   │   │       │   ├── libMlCore.dll*
*│   │   │       │   ├── libMlMaths.dll*
*│   │   │       │   ├── libMlModel.dll*
*│   │   │       │   ├── libxml2.dll*
*│   │   │       │   ├── log4cxx.dll*
*│   │   │       │   ├── msvcp120.dll*
*│   │   │       │   ├── msvcr120.dll*
*│   │   │       │   ├── normalize.exe*
*│   │   │       │   └── zlib1.dll*
*│   │   │       └── resources*
*│   │   │           ├── date_time_zonespec.csv*
*│   │   │           └── ml-en.dict*
*│   │   ├── plugin-descriptor.properties*
*│   │   ├── plugin-security.policy*
*│   │   ├── super-csv-2.4.0.jar*
*│   │   └── x-pack-ml-6.8.23.jar*
*│   ├── x-pack-monitoring*
*│   │   ├── elasticsearch-rest-client-6.8.23.jar*
*│   │   ├── elasticsearch-rest-client-sniffer-6.8.23.jar*
*│   │   ├── LICENSE.txt*
*│   │   ├── NOTICE.txt*
*│   │   ├── plugin-descriptor.properties*
*│   │   ├── plugin-security.policy*
*│   │   └── x-pack-monitoring-6.8.23.jar*
*│   ├── x-pack-rollup*
*│   │   ├── LICENSE.txt*
*│   │   ├── NOTICE.txt*
*│   │   ├── plugin-descriptor.properties*
*│   │   ├── plugin-security.policy*
*│   │   └── x-pack-rollup-6.8.23.jar*
*│   ├── x-pack-security*
*│   │   ├── cryptacular-1.2.4.jar*
*│   │   ├── guava-19.0.jar*
*│   │   ├── httpclient-cache-4.5.2.jar*
*│   │   ├── java-support-7.3.0.jar*
*│   │   ├── LICENSE.txt*
*│   │   ├── log4j-slf4j-impl-2.17.1.jar*
*│   │   ├── metrics-core-3.2.2.jar*
*│   │   ├── NOTICE.txt*
*│   │   ├── opensaml-core-3.3.0.jar*
*│   │   ├── opensaml-messaging-api-3.3.0.jar*
*│   │   ├── opensaml-messaging-impl-3.3.0.jar*
*│   │   ├── opensaml-profile-api-3.3.0.jar*
*│   │   ├── opensaml-profile-impl-3.3.0.jar*
*│   │   ├── opensaml-saml-api-3.3.0.jar*
*│   │   ├── opensaml-saml-impl-3.3.0.jar*
*│   │   ├── opensaml-security-api-3.3.0.jar*
*│   │   ├── opensaml-security-impl-3.3.0.jar*
*│   │   ├── opensaml-soap-api-3.3.0.jar*
*│   │   ├── opensaml-soap-impl-3.3.0.jar*
*│   │   ├── opensaml-storage-api-3.3.0.jar*
*│   │   ├── opensaml-storage-impl-3.3.0.jar*
*│   │   ├── opensaml-xmlsec-api-3.3.0.jar*
*│   │   ├── opensaml-xmlsec-impl-3.3.0.jar*
*│   │   ├── plugin-descriptor.properties*
*│   │   ├── plugin-security.policy*
*│   │   ├── slf4j-api-1.6.2.jar*
*│   │   ├── xmlsec-2.0.8.jar*
*│   │   └── x-pack-security-6.8.23.jar*
*│   ├── x-pack-sql*
*│   │   ├── aggs-matrix-stats-client-6.8.23.jar*
*│   │   ├── LICENSE.txt*
*│   │   ├── NOTICE.txt*
*│   │   ├── plugin-descriptor.properties*
*│   │   ├── plugin-security.policy*
*│   │   ├── sql-action-6.8.23.jar*
*│   │   ├── sql-proto-6.8.23.jar*
*│   │   └── x-pack-sql-6.8.23.jar*
*│   ├── x-pack-upgrade*
*│   │   ├── LICENSE.txt*
*│   │   ├── NOTICE.txt*
*│   │   ├── plugin-descriptor.properties*
*│   │   ├── plugin-security.policy*
*│   │   └── x-pack-upgrade-6.8.23.jar*
*│   └── x-pack-watcher*
*│       ├── activation-1.1.1.jar*
*│       ├── guava-16.0.1.jar*
*│       ├── javax.mail-1.6.2.jar*
*│       ├── LICENSE.txt*
*│       ├── NOTICE.txt*
*│       ├── owasp-java-html-sanitizer-r239.jar*
*│       ├── plugin-descriptor.properties*
*│       ├── plugin-security.policy*
*│       └── x-pack-watcher-6.8.23.jar*
*├── NOTICE.txt*
*├── plugins*
*└── README.textile*

*54 directories, 380 files*



#### 2.3.4.2	配置文件说明

##### elasticsearch.yml



##### jvm.options

##### log4j2.properties

##### role_mapping.yml

##### roles.yml

##### users

##### users_roles

## 2.4	logstash部署

### 2.4.1	部署说明

kibana部署在需要进行日志收集的服务器即可，如果要部署多个节点，可以使用nginx作为代理访问

### 2.4.2	准备工作

### 2.4.3	部署步骤



### 2.4.4	目录信息

### 2.4.5	常见问题

## 2.5	kibana部署

### 2.5.1	部署说明

kibana部署1个节点即可，如果要部署多个节点，可以使用nginx作为代理访问

### 2.5.2	准备工作

### 2.5.3	部署步骤

#### 解压软件包

```
tar xzf kibana-6.8.23-linux-x86_64.tar.gz -C /usr/local
ln -s /usr/local/kibana-6.8.23-linux-x86_64/  /usr/local/kibana
```

#### 环境变量修改

#### 修改jvm参数

#### 修改配置文件

配置文件路径：/usr/local/kibana/config/kibana.yml

配置文件内容

```
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://node01:9200","http://node02:9200","http://node03:9200"]
kibana.index: ".kibana"
```

#### 启动kibana

```
/usr/local/kibana/bin/kibana &
```

#### 访问方式

http://172.25.149.4:5601/app/kibana

### 2.5.4	目录信息

### 2.5.5	常见问题





## 2.6	filebeat部署

### 2.6.1	部署说明

kibana部署在需要进行日志收集的服务器即可，如果要部署多个节点，可以使用nginx作为代理访问

### 2.6.2	准备工作

### 2.6.3	部署步骤



### 2.6.4	目录信息

### 2.6.5	常见问题

## 2.7	apm-server部署

### 2.7.1	部署说明

kibana部署在需要进行日志收集的服务器即可，如果要部署多个节点，可以使用nginx作为代理访问

### 2.7.2	准备工作

### 2.7.3	部署步骤



### 2.7.4	目录信息

### 2.7.5	常见问题