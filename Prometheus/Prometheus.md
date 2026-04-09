```
Expr: node_memory_MemFree_bytes / node_memory_MemTotal_bytes *100 {instance="172.16.10.29:9100",job="elasticsearch"}
Step: 20s
```

https://github.com/prometheus/prometheus/archive/refs/tags/v2.36.2.tar.gz

https://github.com/prometheus/alertmanager/archive/refs/tags/v0.24.0.tar.gz

https://github.com/prometheus/node_exporter/archive/refs/tags/v1.3.1.tar.gz

https://github.com/prometheus/pushgateway/archive/refs/tags/v1.4.3.tar.gz

https://github.com/prometheus/blackbox_exporter/archive/refs/tags/v0.21.1.tar.gz

https://github.com/grafana/grafana/archive/refs/tags/v8.5.9.tar.gz

s

https://github.com/prometheus-community/windows_exporter/releases/download/v0.19.0/windows_exporter-0.19.0-amd64.exe

99.248.1.63 19090

99.248.1.177 19090

prometheus中心节点VPC的IP地址：10.248.1.209

99.248.10.230

```
Expr: node_memory_MemTotal_bytes{instance="172.16.10.29:9100",job="elasticsearch"}
Step: 20s
```

0 3 * * * /bin/bash /root/registry-gc/clean.sh > /tmp/clean.log
/root/registry-gc/gc-registry-prefix.sh



*/30 * * * * /bin/bash /root/registry-gc/clean.sh > /tmp/clean.log

/usr/local/prometheus/bin/prometheus \
--config.file=/usr/local/prometheus/configs/prometheus.yml \
--web.listen-address="0.0.0.0:9090" \
--web.max-connections=1024 \
--web.enable-lifecycle \
--web.enable-admin-api \
--storage.tsdb.path="/usr/local/prometheus/data/" \
--storage.tsdb.retention.time=180d \
--query.max-concurrency=200 \
--query.max-samples=500000000 \
--log.level=info &

curl -X POST http://172.16.16.5:9090/-/reload



curl -X POST http://127.0.0.1:19090/-/reload

/usr/local/node_exporter/node_exporter \
--web.listen-address=":19100" \
--web.max-requests=400 \
--log.level=info &



```
 /usr/local/grafana/bin/grafana-server \
-homepath /usr/local/grafana \
-config /usr/local/grafana/conf/config.ini \
&
```



```
nohup /usr/local/grafana/bin/grafana-server  -homepath /usr/local/grafana -config /usr/local/grafana/conf/config.ini >> /var/log/grafana.log &
```



```
nohup /usr/local/grafana-9.1.2/bin/grafana-server  -homepath /usr/local/grafana-9.1.2 -config /usr/local/grafana-9.1.2/conf/config.ini >> /var/log/grafana-9.1.2.log &
```

/usr/local/alertmanager/bin/alertmanager \
--config.file="/usr/local/alertmanager/configs/alertmanager.yml" \
--storage.path="/usr/local/alertmanager/data/" \
--data.retention=120h \
--web.listen-address=":19093" \
--log.level=info \
&

curl -X POST http://127.0.0.1:19093/-/reload

/usr/local/pushgateway/bin/pushgateway \
--web.listen-address=":19091" \
--web.enable-lifecycle \
--web.enable-admin-api \
--persistence.file="/usr/local/pushgateway/data/pushgateway.data" \
--persistence.interval=5m \
--log.level=info \
& 
curl -X POST http://127.0.0.1:19091/-/reload

/usr/local/blackbox_exporter/blackbox_exporter \
--config.file="/usr/local/blackbox_exporter/blackbox.yml" \
--web.listen-address=":19115" \
--log.level=info \
&


172.16.16.250/cfs-sit-jf/cfs-corporate:0727-b1_20220725163922
csst.registry.cmbyc.com

UAT-SALVE05 172.16.30.4

Paas#2021
Paas@2022
1qaz@WSX
Jiahong:2b
Wangyue:2b
Paas@2222

http://99.248.10.15:19090/

./alertmanager-wechatbot-webhook -RobotKey dbeb3023-057a-45d7-9954-59e2858401eb &

https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=dbeb3023-057a-45d7-9954-59e2858401eb



curl -XPOST "http://172.16.16.5:19093/api/v2/alerts" -H "Content-type: application/json" -d '[{"status":"firing"},{"alertname":"name"},{"service":"myservice"},{"severity":"warning"},{"instance":"limugen-test"},{"annotations":"{"summary":"High latency is high!"}"},{"generatirURL":"www.test.com"},]' -v

curl -XPOST "http://172.16.16.5:9093/api/v2/alerts" -H "Content-type: application/json" -d '[{"status":"firing"},{"alertname":"name"},{"service":"myservice"},{"severity":"warning"},{"instance":"limugen-test"},{"annotations":"{"summary":"High latency is high!"}"},{"generatirURL":"www.test.com"}]' -v







```
groups:
- name: test-group
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      description: "stuff's happening with {{ $labels.instance }}"
      wechatRobot: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=dbeb3023-057a-45d7-9954-59e2858401eb"

```

```
- targets:
  - 172.16.16.5:9100
  labels:
    evn: sit
    app_name: prometheus
    app_module: monitor
    qy_acc: dec@cmbyc.com
    vpc_name: dec
    sub_job: app

```

服务器{{ $labels.ipaddr }}(主机名称为{{ $labels.hostname }})在宕机可能性。\n应用名称：{{ $labels.app_name }}\\n模块：{{ $labels.app_module }}\n青云账户：{{ $labels.qy_acc }}\nVPC名称：{{ $labels.vpc_name }}\n应用类型：{{ $labels.sub_job }}\n应用环境类型： {{ $labels.env }} 

```
- targets:
  - 172.16.16.5:9100
  labels:
    ipaddr: 172.16.16.5
    hostname: prometheus
    env: sit
    app_name: prometheus
    app_module: monitor
    qy_acc: dec@cmbyc.com
    vpc_name: dec
    sub_job: app

```

 

```
groups:
- name: test-group
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "服务器{{ $labels.ipaddr }}(主机名称为{{ $labels.hostname }})存在宕机可能性"
      description: "服务器{{ $labels.ipaddr }}监控agent异常：【应用名称：{{ $labels.app_name }}\t模块：{{ $labels.app_module }}\t青云账户：{{ $labels.qy_acc }}\tVPC名称：{{ $labels.vpc_name }}\t应用类型：{{ $labels.sub_job }}\t应用环境类型： {{ $labels.env }}】 "
      wechatRobot: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=dbeb3023-057a-45d7-9954-59e2858401eb"

```





/opt/node_exporter/sbin/node_exporter \
--web.listen-address=":9100" \
--web.max-requests=400 \
--log.level=info  >> /var/log/node_export.log 2>&1 &





```
- targets:
  - 172.16.22.2:9100
  labels:
    ipaddr: 172.16.22.2
    hostname: cfs-nacos
    env: sit
    app_name: cfs
    app_module: nacos
    qy_acc: dec@cmbyc.com
    vpc_name: dec
    sub_job: middleware

- targets:
  - 172.16.22.2:9100
  labels:
    ipaddr: 172.16.22.2
    hostname: cfs-nacos
    env: sit
    app_name: cfs
    app_module: nacos
    qy_acc: dec@cmbyc.com
    vpc_name: dec
    sub_job: middleware
   
  
```



https://grafana.com/api/dashboards/1375/revisions/1/download





node_load1{}

node_load1{}

node_load1{app_module="monitor", app_name="prometheus", env="sit", hostname="prometheus", instance="172.16.22.2:9100", ipaddr="172.16.22.2", job="host monitor", qy_acc="dec@cmbyc.com", sub_job="app", vpc_name="dec"}







```
- targets:
  - 172.16.16.5:9100
  labels:
    job: test
    sub_job: ops
    module: promtheus
    sub_module: server
    env: sit
    ipaddr: 172.16.16.5
    hostname: prometheus-server
    vpc_name: dec
    qy_acc: dec@cmbyc.com
- targets:
  - 172.16.22.2:9100
  labels:
    job: cfs
    sub_job: middleware
    module: nacos
    sub_module: all
    env: sit
    ipaddr: 172.16.22.2
    hostname: cfs-nacos
    vpc_name: dec
    qy_acc: dec@cmbyc.com
- targets:
  - 172.16.25.6:9100
  labels:
    job: cso
    sub_job: middleware
    module: rocketmq
    sub_module: all
    env: sit
    ipaddr: 172.16.25.6
    hostname: cso-rocketmq
    vpc_name: dec
    qy_acc: dec@cmbyc.com
- targets:
  - 172.16.22.7:9100
  labels:
    job: cfs
    sub_job: middleware
    module: rocketmq
    sub_module: all
    env: sit
    ipaddr: 172.16.22.7
    hostname: cfs-rocketmq
    vpc_name: dec
    qy_acc: dec@cmbyc.com
- targets:
  - 172.16.100.6:9100
  labels:
    job: trip
    sub_job: middleware
    module: rabbitmq
    sub_module: all
    env: sit
    ipaddr: 172.16.100.6
    hostname: trip-rabbitmq
    vpc_name: dec
    qy_acc: dec@cmbyc.com
- targets:
  - 172.16.25.10:9100
  labels:
    job: sco
    sub_job: db
    module: mysql
    sub_module: all
    env: sit
    ipaddr: 172.16.25.10
    hostname: sco-db
    vpc_name: dec
    qy_acc: dec@cmbyc.com
```

```
nohup /root/alertmanager-wechatbot-webhook -RobotKey dbeb3023-057a-45d7-9954-59e2858401eb > /tmp/alertmanager-wechatbot-webhook.log 2>1 &
```



```
(1 - sum(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) / sum(rate(node_cpu_seconds_total[5m])) by (instance)) * 100
```

```
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

```
(1- node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100
```





(1 - sum(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) / sum(rate(node_cpu_seconds_total[5m])) by (instance)) * 100





/usr/local/prometheus/prometheus \
--config.file=/usr/local/prometheus/prometheus.yml \
--web.listen-address="0.0.0.0:9090" \
--web.max-connections=1024 \
--web.enable-lifecycle \
--web.enable-admin-api \
--storage.tsdb.path="usr/local/prometheus/data/" \
--storage.tsdb.retention.time=180d \
--query.max-concurrency=200 \
--query.max-samples=500000000 \
--log.level=info &





./consul agent -server -data-dir=/data/consul/ -bootstrap -ui -bind=0.0.0.0 -client=0.0.0.0 &





(1- node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100	{{job}}_{{instance}}

(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100



(1 - sum(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (job,instance) / sum(rate(node_cpu_seconds_total[5m])) by (job,instance)) * 100





```
.*instance="(.*?)".*
```



```
/usr/local/grafana/bin/grafana-server \
-config /usr/local/grafana/conf/config.ini \
-homepath /usr/local/grafana \
-pidfile /data/grafana/grafana.pid \
-profile \
-profile-addr 0.0.0.0 \
-profile-port 16060 \
-tracing \
-tracing-file /data/grafana/log/trace.out 
```

http://wiki.cmbyc.com/pages/viewpage.action?pageId=101882834





cat add.list 

```
linux,devops,prd,192.168.0.4:19100
linux,devops,prd,192.168.0.5:19100
linux,devops,prd,192.168.0.6:19100
linux,devops,prd,192.168.0.7:19100
linux,devops,prd,192.168.0.8:19100
linux,map,prd,192.168.0.3:19100
linux,map,prd,192.168.0.6:19100
linux,map,prd,192.168.0.7:19100
linux,map,prd,192.168.0.9:19100
linux,map,prd,192.168.0.10:19100
```

cat add_rule.sh 

```
#!/bin/bash
DIR=$(cd `dirname $0`;pwd)
list_file="add.list"
add_log_file="/var/log/prometheus_rule_add.log"
template_file="linux_host_intance.yml.template"

if [ ! -f "${DIR}/${list_file}" ]
then
    exit
    echo ${DIR}/${list_file} is not EXIST!!PLS check again and run this scrips again!
    echo `date +"%Y-%m-%d %H:%M:%S"` ${DIR}/${list_file} is not EXIST!!PLS check again and run this scrips again! >> ${add_log_file}
fi


if [ ! -f "${DIR}/${template_file}" ]
then
    exit
    echo ${DIR}/${template_file} is not EXIST!!PLS check again and run this scrips again!
    echo `date +"%Y-%m-%d %H:%M:%S"` ${DIR}/${template_file} is not EXIST!!PLS check again and run this scrips again! >> ${add_log_file}
fi

for list in `cat ${list_file}`
do
    for param in  ${list}
    do
       system_type=`echo ${param}|awk -F"," '{print $1}'`
       job_name=`echo ${param}|awk -F"," '{print $2}'`
       env=`echo ${param}|awk -F"," '{print $3}'`
       instance_name=`echo ${param}|awk -F"," '{print $4}'`
       rule_file_name="rule_${system_type}_${job_name}_${env}_${instance_name}.yml"
       if [ ! -f "${DIR}/${rule_file_name}" ]
       then
           cp ${DIR}/${template_file} ${DIR}/${rule_file_name}
           sed -i "s/instance_name/${instance_name}/" ${DIR}/${rule_file_name}
           sed -i "s/job_name/${job_name}/" ${DIR}/${rule_file_name}
           echo "Finished to add rule of ${DIR}/${rule_file_name}"
           echo `date +"%Y-%m-%d %H:%M:%S"` Finished to add rule file of ${DIR}/${rule_file_name} >> ${add_log_file}
       fi
    done
done

```



cat del.list 

```
linux,devops,prd,192.168.0.4:19100
linux,devops,prd,192.168.0.5:19100
```

cat del_rule.sh 

```
#!/bin/bash
#set -x
DIR=$(cd `dirname $0`;pwd)
del_file="del.list"
del_log_file="/var/log/prometheus_rule_del.log"


if [ ! -f "${DIR}/${del_file}" ]
then
    exit
    echo ${DIR}/${del_file} is not EXIST!!Pls check this rule again!
    echo `date +"%Y-%m-%d %H:%M:%S"` ${DIR}/${del_file} is not EXIST!!PLS check this rule again! >> ${del_log_file}
fi

for list in `cat ${del_file}`
do
    for param in  ${list}
    do
       system_type=`echo ${param}|awk -F"," '{print $1}'`
       job_name=`echo ${param}|awk -F"," '{print $2'`
       env=`echo ${param}|awk -F"," '{print $3'`
       instance_name=`echo ${param}|awk -F"," '{print $4'`
       rule_file_name="rule_${system_type}_${job_name}_${env}_${instance_name}.yml"
       if [ -f "${DIR}/${rule_file_name}" ]
       then
           rm -fr ${DIR}/${rule_file_name}
           echo rule file of ${DIR}/${rule_file_name} is deleted!!!
           echo `date +"%Y-%m-%d %H:%M:%S"` rule file of ${DIR}/${rule_file_name} is deleted!!! >> ${del_log_file}
       else
           echo rule file of ${DIR}/${rule_file_name} is not exist!!
           echo `date +"%Y-%m-%d %H:%M:%S"` rule file of ${DIR}/${rule_file_name} is not exist!! >> ${del_log_file}
       fi
    done
done
```





cat linux_host_intance.yml.template 

```
groups:
- name: "agent status"
  rules:
  - alert: "监控客户端状态异常"
    expr: up{instance="instance_name",job="job_name"} == 0
    for: 1m
    labels:
      severity: 严重告警
    annotations:
      summary: "资源{{ $labels.instance }}监控客户异常"
      description: "【当前agent状态：{{ $value }}】\n资源详情：【系统名称:{{ $labels.job }} 环境名称：{{ $labels.env }} 主机IP地址：{{ $labels.ipaddr }} 系统模块名称:{{ $labels.module }} 主机名称:{{ $labels.hostname }} 主机所属区域：{{ $labels.region }} 管理账户：{{ $labels.account }} vpc名称：{{ $labels.vpc_name }}】"

- name: "memory used"
  rules:
  - alert: "内存使用率超过阈值"
    expr: floor(((node_memory_MemTotal_bytes{instance="instance_name",job="job_name"} - node_memory_MemAvailable_bytes{instance="instance_name",job="job_name"}) / (node_memory_MemTotal_bytes{instance="instance_name",job="job_name"} )) * 100) >= 90
    for: 1m
    labels:
      severity: 严重告警
    annotations:
      summary: "资源内存使用率 >=90%"
      description: 【当前内存使用率为：{{ $value }}%】\n资源详情：【系统名称:{{ $labels.job }} 环境名称：{{ $labels.env }} 主机IP地址：{{ $labels.ipaddr }} 系统模块名称:{{ $labels.module }} 主机名称:{{ $labels.hostname }} 主机所属区域：{{ $labels.region }} 管理账户：{{ $labels.account }} vpc名称：{{ $labels.vpc_name }}】"

- name: "cpu used"
  rules:
  - alert: "CPU使用率超过阈值"
    expr: floor(100 - avg(irate(node_cpu_seconds_total{mode="idle",instance="instance_name",job="job_name"}[5m]))*100) >= 80
    for: 1m
    labels:
      severity: 严重告警
    annotations:
      summary: "资源CPU使用率 >=80%"
      description: 【当前CPU使用率为：{{ $value }}%】\n资源详情：【系统名称:{{ $labels.job }} 环境名称：{{ $labels.env }} 主机IP地址：{{ $labels.ipaddr }} 系统模块名称:{{ $labels.module }} 主机名称:{{ $labels.hostname }} 主机所属区域：{{ $labels.region }} 管理账户：{{ $labels.account }} vpc名称：{{ $labels.vpc_name }}】"

- name: "disk used"
  rules:
  - alert: "磁盘分区使用率超过阈值"
    expr: floor(100 -(node_filesystem_avail_bytes{instance="instance_name",job="job_name",fstype=~"ext2|ext3|ext4|xfs"} / node_filesystem_size_bytes{instance="instance_name",job="job_name",fstype=~"ext2|ext3|ext4|xfs"}) *100) >= 90
    for: 1m
    labels:
      severity: 严重告警
    annotations:
      summary: "资源磁盘分区{{ $labels.mountpoint }}使用率 >=90%"
      description: 【当前分区名为："{{ $labels.mountpoint }}"，分区当前使用率为：{{ $value }}%】\n资源详情：【系统名称:{{ $labels.job }} 环境名称：{{ $labels.env }} 主机IP地址：{{ $labels.ipaddr }} 系统模块名称:{{ $labels.module }} 主机名称:{{ $labels.hostname }} 主机所属区域：{{ $labels.region }} 管理账户：{{ $labels.account }} vpc名称：{{ $labels.vpc_name }}】"

```



cat add_endpoint.list 

```
linux,map,prd,192.168.0.3:19100,mid,nginx,alone,daping-online,SHA,chenjunqiang@mbcloud.com,cubo-online-prod
linux,map,prd,192.168.0.6:19100,app,map,alone,map-a-app,SHA,chenjunqiang@mbcloud.com,cubo-online-prod
linux,map,prd,192.168.0.7:19100,mid,redis,alone,map-redis-fastdfs,SHA,chenjunqiang@mbcloud.com,cubo-online-prod
linux,map,prd,192.168.0.9:19100,app,dap,alone,daping-offline,SHA,chenjunqiang@mbcloud.com,cubo-online-prod
linux,map,prd,192.168.0.10:19100,app,dap,alone,daping-online,SHA,chenjunqiang@mbcloud.com,cubo-online-prod
```



cat add_endpoint.sh 

```
#!/bin/bash
DIR=$(cd `dirname $0`;pwd)
list_file="add_endpoint.list"
log_file="/var/log/prometheus_rule_endpoint.log"

if [ ! -f "${DIR}/${list_file}" ]
then
    exit
    echo ${DIR}/${list_file} is not EXIST!!PLS check again and run this scrips again!
    echo `date +"%Y-%m-%d %H:%M:%S"` ${DIR}/${list_file} is not EXIST!!PLS check again and run this scrips again! >> ${log_file}
fi



for list in `cat ${list_file}`
do
    for param in  ${list}
    do
       system_type=`echo ${param}|awk -F"," '{print $1}'`
       job_name=`echo ${param}|awk -F"," '{print $2}'`
       env=`echo ${param}|awk -F"," '{print $3}'`
       instance_name=`echo ${param}|awk -F"," '{print $4}'`
       sub_job_name=`echo ${param}|awk -F"," '{print $5}'`
       module_name=`echo ${param}|awk -F"," '{print $6}'`
       sub_module_name=`echo ${param}|awk -F"," '{print $7}'`
       ipaddr=${instance_name%:*}
       host_name=`echo ${param}|awk -F"," '{print $8}'`
       region_name=`echo ${param}|awk -F"," '{print $9}'`
       account_name=`echo ${param}|awk -F"," '{print $10}'`
       vpc_name=`echo ${param}|awk -F"," '{print $11}'`
       endpoint_file_name="endpoint_${system_type}_${job_name}_${env}_${instance_name}.yml"
       if [ ! -f "${DIR}/${endpoint_file_name}" ]
       then
           cat > ${DIR}/${endpoint_file_name} << EOF

- targets:
  - ${instance_name}
    labels:
    job: ${job_name}
    sub_job: ${sub_job_name}
    module: ${module_name}
    sub_module: ${sub_module_name}
    env: ${env}
    ipaddr: ${ipaddr}
    hostname: ${host_name}
    region: ${region_name}
    account: ${account_name}
    vpc_name: ${vpc_name}
    EOF
           echo "Finished to add endpoint config of ${DIR}/${endpoint_file_name}"
           echo `date +"%Y-%m-%d %H:%M:%S"` Finished to add endopint file of ${DIR}/${endpoint_file_name} >> ${log_file}
       fi
     done
    done
```



 cat del_endpoint.list 

```
linux,map,prd,192.168.0.3:19100,mid,nginx,alone,daping-online,SHA,chenjunqiang@mbcloud.com,cubo-online-prod
linux,map,prd,192.168.0.6:19100,app,map,alone,map-a-app,SHA,chenjunqiang@mbcloud.com,cubo-online-prod
```



cat del_endpoint.sh 

```
#!/bin/bash
DIR=$(cd `dirname $0`;pwd)
list_file="del_endpoint.list"
log_file="/var/log/prometheus_rule_del_endpoint.log"

if [ ! -f "${DIR}/${list_file}" ]
then
    exit
    echo ${DIR}/${list_file} is not EXIST!!PLS check again and run this scrips again!
    echo `date +"%Y-%m-%d %H:%M:%S"` ${DIR}/${list_file} is not EXIST!!PLS check again and run this scrips again! >> ${log_file}
fi



for list in `cat ${list_file}`
do
    for param in  ${list}
    do
       system_type=`echo ${param}|awk -F"," '{print $1}'`
       job_name=`echo ${param}|awk -F"," '{print $2}'`
       env=`echo ${param}|awk -F"," '{print $3}'`
       instance_name=`echo ${param}|awk -F"," '{print $4}'`
       sub_job_name=`echo ${param}|awk -F"," '{print $5}'`
       module_name=`echo ${param}|awk -F"," '{print $6}'`
       sub_module_name=`echo ${param}|awk -F"," '{print $7}'`
       ipaddr=${instance_name%:*}
       host_name=`echo ${param}|awk -F"," '{print $8}'`
       region_name=`echo ${param}|awk -F"," '{print $9}'`
       account_name=`echo ${param}|awk -F"," '{print $10}'`
       vpc_name=`echo ${param}|awk -F"," '{print $11}'`
       endpoint_file_name="endpoint_${system_type}_${job_name}_${env}_${instance_name}.yml"
       if [ -f "${DIR}/${endpoint_file_name}" ]
       then
           rm -fr ${DIR}/${endpoint_file_name}
           echo "Finished to del endpoint config of ${DIR}/${endpoint_file_name}"
           echo `date +"%Y-%m-%d %H:%M:%S"` Finished to del endopint file of ${DIR}/${endpoint_file_name} >> ${log_file}
       fi
   done
done
```


