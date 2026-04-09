# 1、Nginx监控方案说明

​	Nginx的模块支持，使用nginx_exporter采集nginx暴露出来的数据即可

# 2、Nginx监控部署

示例中nginx的监控端口为9090，nginx_exporter采集端口为19113（默认为9113）

## Nginx配置修改

在需要采集数据的Nginx的server模块中添加如下配置，并重载nginx配置 sbin/nginx --s reload

```
       location =/stub_status {
       stub_status;
    }
```

![image-20230213154245305](D:\limugen\00-self\note\专题\监控\image-20230213154245305.png)

## playbook文件

### hosts

```
[nginx_exporter]
10.233.156.162
10.233.156.163
```

### main.yml 

```
---
# tasks file for node_export
- hosts: nginx_exporter
  gather_facts: no
  tasks:
#添加运行监控服务的用户monitoring，所有运行服务器上的监控服务用户均为monitoring
  - name: "add user monitoring"
    user:
      name: monitoring
      comment: for monitor service
      shell: /sbin/nologin
      state: present
#
  - name: "copy nginx_exporter"
    copy:
      src: nginx-prometheus-exporter
      dest: /usr/sbin/nginx-prometheus-exporter
      mode: 755

  - name: "copy nginx_exporter.service"
    copy:
      src: nginx_exporter.service
      dest: /lib/systemd/system/nginx_exporter.service

  - name: "copy sysconfig.nginx_exporter"
    copy:
      src: sysconfig.nginx_exporter
      dest: /etc/sysconfig/sysconfig.nginx_exporter

  - name: "daemon-reload"
    systemd:
      daemon_reload: yes

  - name: "enable nginx_exporter.service"
    systemd:
      name: nginx_exporter.service
      enabled: yes
      state: restarted

```

### files/nginx_exporter.service

```
[Unit]
Description=nginx Exporter

[Service]
User=monitoring
EnvironmentFile=/etc/sysconfig/sysconfig.nginx_exporter
ExecStart=/usr/sbin/nginx-prometheus-exporter $OPTIONS
Restart=always
RestartSec=30s

[Install]
WantedBy=multi-user.target

```

### files/sysconfig.nginx_exporter

```
OPTIONS="--web.listen-address=:19113 --nginx.scrape-uri=http://127.0.0.1:9090/stub_status"

```

### run.sh

```
#!/bin/bash
hosts="hosts"
playbook="main.yml"

ansible-playbook -i $hosts $playbook

```



## 运行playbook

/bin/bash run.sh

# 3、Metrics访问

curl -XGET http://10.233.156.162:19113/metrics

```
# HELP nginx_connections_accepted Accepted client connections
# TYPE nginx_connections_accepted counter
nginx_connections_accepted 8.199969e+06
# HELP nginx_connections_active Active client connections
# TYPE nginx_connections_active gauge
nginx_connections_active 7
# HELP nginx_connections_handled Handled client connections
# TYPE nginx_connections_handled counter
nginx_connections_handled 8.199969e+06
# HELP nginx_connections_reading Connections where NGINX is reading the request header
# TYPE nginx_connections_reading gauge
nginx_connections_reading 0
# HELP nginx_connections_waiting Idle client connections
# TYPE nginx_connections_waiting gauge
nginx_connections_waiting 2
# HELP nginx_connections_writing Connections where NGINX is writing the response back to the client
# TYPE nginx_connections_writing gauge
nginx_connections_writing 5
# HELP nginx_http_requests_total Total http requests
# TYPE nginx_http_requests_total counter
nginx_http_requests_total 410256
# HELP nginx_up Status of the last metric scrape
# TYPE nginx_up gauge
nginx_up 1
# HELP nginxexporter_build_info Exporter build information
# TYPE nginxexporter_build_info gauge
nginxexporter_build_info{arch="linux/amd64",commit="e4a6810d4f0b776f7fde37fea1d84e4c7284b72a",date="2022-09-07T21:09:51Z",dirty="false",go="go1.19",version="0.11.0"} 1
```



# 4、Nginx监控数据接入

在prometheus配置文件“prometheus.yml”添加如下内容

```
  - job_name: "nginx"
    static_configs:
      - targets: ["10.233.156.137:19113"]
```



# 5、Nginx监控指标说明

| 序号 | 指标名称         | 指标内涵          | 计算公式                                                     |
| ---- | ---------------- | ----------------- | ------------------------------------------------------------ |
| 1    | heap堆内在使用率 | JVM的堆内存使用率 | sum(jvm_memory_used_bytes{area="heap"})/sum(jvm_memory_max_bytes{area="heap"}) * 100 |
| 2    | 阻塞线程数       | 阻塞线程数        | jvm_threads_states_threads{state="blocked"}                  |

# 6、Nginx监控告警阈值



# 7、Nginx监控数据展示