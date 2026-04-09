## 监控方案说明

Nacos组件已内嵌支持prometheus监控（内嵌支持3种监控方式：prometheus，elasticsearch，influx，默认没有启动，需在nacos配置文件application.properties中启动即可）

## Nacos配置修改

修改application.properties配置文件，将“management.endpoints.web.exposure.include=*”前的注释删掉

```
sed -i '/management.endpoints.web.exposure.include/s/#//' application.properties
```

## Metrics访问

如下示例中，nacos的访问端口为8849

curl -XGET http://10.233.156.137:8849/nacos/actuator/prometheus

返回值如下

```
# HELP tomcat_threads_busy_threads  
# TYPE tomcat_threads_busy_threads gauge
tomcat_threads_busy_threads{name="http-nio-8849",} 1.0
# HELP jvm_threads_states_threads The current number of threads having NEW state
# TYPE jvm_threads_states_threads gauge
jvm_threads_states_threads{state="runnable",} 34.0
jvm_threads_states_threads{state="blocked",} 0.0
jvm_threads_states_threads{state="waiting",} 124.0
jvm_threads_states_threads{state="timed-waiting",} 42.0
jvm_threads_states_threads{state="new",} 0.0
jvm_threads_states_threads{state="terminated",} 0.0
# HELP jvm_memory_used_bytes The amount of used memory
# TYPE jvm_memory_used_bytes gauge
jvm_memory_used_bytes{area="heap",id="PS Survivor Space",} 1671200.0
jvm_memory_used_bytes{area="heap",id="PS Old Gen",} 5.03538168E8
jvm_memory_used_bytes{area="heap",id="PS Eden Space",} 6.975758E8
jvm_memory_used_bytes{area="nonheap",id="Metaspace",} 8.636848E7
jvm_memory_used_bytes{area="nonheap",id="Code Cache",} 5.3514304E7
jvm_memory_used_bytes{area="nonheap",id="Compressed Class Space",} 1.026812E7
# HELP nacos_monitor  
# TYPE nacos_monitor gauge
nacos_monitor{module="config",name="longPolling",} 31.0
nacos_monitor{module="config",name="configCount",} 55.0
nacos_monitor{module="naming",name="failedPush",} 21.0
nacos_monitor{module="naming",name="leaderStatus",} 0.0
nacos_monitor{module="config",name="publish",} 0.0
nacos_monitor{module="naming",name="tcpHealthCheck",} 0.0
nacos_monitor{module="config",name="dumpTask",} 0.0
nacos_monitor{module="config",name="notifyTask",} 0.0
nacos_monitor{module="naming",name="totalPush",} 21.0
nacos_monitor{module="naming",name="avgPushCost",} -1.0
nacos_monitor{module="config",name="getConfig",} 18.0
nacos_monitor{module="naming",name="ipCount",} 55.0
nacos_monitor{module="naming",name="mysqlhealthCheck",} 0.0
nacos_monitor{module="naming",name="serviceCount",} 28.0
nacos_monitor{module="naming",name="httpHealthCheck",} 0.0
nacos_monitor{module="naming",name="maxPushCost",} -1.0
# HELP jvm_buffer_memory_used_bytes An estimate of the memory that the Java virtual machine is using for this buffer pool
# TYPE jvm_buffer_memory_used_bytes gauge
jvm_buffer_memory_used_bytes{id="direct",} 712705.0
jvm_buffer_memory_used_bytes{id="mapped",} 0.0
# HELP jvm_threads_daemon_threads The current number of live daemon threads
# TYPE jvm_threads_daemon_threads gauge
jvm_threads_daemon_threads 172.0
# HELP process_files_open_files The open file descriptor count
# TYPE process_files_open_files gauge
process_files_open_files 200.0
# HELP jvm_threads_live_threads The current number of live threads including both daemon and non-daemon threads
# TYPE jvm_threads_live_threads gauge
jvm_threads_live_threads 200.0
# HELP process_uptime_seconds The uptime of the Java virtual machine
# TYPE process_uptime_seconds gauge
process_uptime_seconds 414279.499
# HELP tomcat_global_request_seconds  
# TYPE tomcat_global_request_seconds summary
tomcat_global_request_seconds_count{name="http-nio-8849",} 8043275.0
tomcat_global_request_seconds_sum{name="http-nio-8849",} 1.1918409072E7
# HELP jvm_gc_memory_promoted_bytes_total Count of positive increases in the size of the old generation memory pool before GC to after GC
# TYPE jvm_gc_memory_promoted_bytes_total counter
jvm_gc_memory_promoted_bytes_total 5.03431656E8
# HELP tomcat_sessions_expired_sessions_total  
# TYPE tomcat_sessions_expired_sessions_total counter
tomcat_sessions_expired_sessions_total 0.0
# HELP system_cpu_usage The "recent cpu usage" for the whole system
# TYPE system_cpu_usage gauge
system_cpu_usage 0.016330166270783847
# HELP tomcat_threads_current_threads  
# TYPE tomcat_threads_current_threads gauge
tomcat_threads_current_threads{name="http-nio-8849",} 11.0
# HELP http_server_requests_seconds  
# TYPE http_server_requests_seconds summary
http_server_requests_seconds_count{exception="IllegalStateException",method="POST",outcome="SERVER_ERROR",status="500",uri="/v1/ns/raft/beat",} 1.0
http_server_requests_seconds_sum{exception="IllegalStateException",method="POST",outcome="SERVER_ERROR",status="500",uri="/v1/ns/raft/beat",} 0.011607024
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/history",} 20.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/history",} 0.08635362
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/actuator/prometheus",} 5992.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/actuator/prometheus",} 46.714532516
http_server_requests_seconds_count{exception="None",method="DELETE",outcome="SUCCESS",status="200",uri="/v1/ns/instance",} 21.0
http_server_requests_seconds_sum{exception="None",method="DELETE",outcome="SUCCESS",status="200",uri="/v1/ns/instance",} 0.043313462
http_server_requests_seconds_count{exception="None",method="POST",outcome="SUCCESS",status="200",uri="root",} 6.0
http_server_requests_seconds_sum{exception="None",method="POST",outcome="SUCCESS",status="200",uri="root",} 0.024900442
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/instance/statuses",} 46.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/instance/statuses",} 0.04370362
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/operator/cluster/state",} 2.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/operator/cluster/state",} 0.010433298
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/catalog/instances",} 8.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/catalog/instances",} 0.012205888
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/catalog/services",} 24.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/catalog/services",} 0.074225314
http_server_requests_seconds_count{exception="None",method="PUT",outcome="SUCCESS",status="200",uri="/v1/ns/distro/datum",} 37.0
http_server_requests_seconds_sum{exception="None",method="PUT",outcome="SUCCESS",status="200",uri="/v1/ns/distro/datum",} 0.167321319
http_server_requests_seconds_count{exception="None",method="PUT",outcome="SUCCESS",status="200",uri="/v1/ns/distro/checksum",} 165687.0
http_server_requests_seconds_sum{exception="None",method="PUT",outcome="SUCCESS",status="200",uri="/v1/ns/distro/checksum",} 167.250448993
http_server_requests_seconds_count{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/auth/users/login",} 22.0
http_server_requests_seconds_sum{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/auth/users/login",} 3.085479538
http_server_requests_seconds_count{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/core/cluster/report",} 207096.0
http_server_requests_seconds_sum{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/core/cluster/report",} 187.52078281
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/console/server/state",} 13.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/console/server/state",} 0.018632476
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/distro/datum",} 50.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/distro/datum",} 0.068193551
http_server_requests_seconds_count{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/ns/service/status",} 165685.0
http_server_requests_seconds_sum{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/ns/service/status",} 151.971974749
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/configs",} 227.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/configs",} 0.577695651
http_server_requests_seconds_count{exception="None",method="PUT",outcome="SUCCESS",status="200",uri="/v1/ns/instance/beat",} 1426326.0
http_server_requests_seconds_sum{exception="None",method="PUT",outcome="SUCCESS",status="200",uri="/v1/ns/instance/beat",} 1074.152986858
http_server_requests_seconds_count{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/ns/instance",} 17.0
http_server_requests_seconds_sum{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/ns/instance",} 0.067658165
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/catalog/service",} 7.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/catalog/service",} 0.017631657
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/service/subscribers",} 2.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/service/subscribers",} 0.009051856
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/**/favicon.ico",} 4.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/**/favicon.ico",} 0.021329128
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/instance/list",} 4610874.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/instance/list",} 5125.854541495
http_server_requests_seconds_count{exception="None",method="GET",outcome="REDIRECTION",status="304",uri="/**",} 26.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="REDIRECTION",status="304",uri="/**",} 0.087835426
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/service/list",} 9340.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/service/list",} 10.503099024
http_server_requests_seconds_count{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/cs/configs",} 3.0
http_server_requests_seconds_sum{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/cs/configs",} 0.213240616
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/console/namespaces",} 18.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/console/namespaces",} 0.081537375
http_server_requests_seconds_count{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/ns/raft/beat",} 1.0
http_server_requests_seconds_sum{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/ns/raft/beat",} 0.014783426
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/communication/dataChange",} 19.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/communication/dataChange",} 0.022085599
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/communication/configWatchers",} 26.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/communication/configWatchers",} 5.243733674
http_server_requests_seconds_count{exception="None",method="PUT",outcome="SUCCESS",status="200",uri="root",} 1047590.0
http_server_requests_seconds_sum{exception="None",method="PUT",outcome="SUCCESS",status="200",uri="root",} 2943.430624582
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/operator/server/status",} 7.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/operator/server/status",} 0.051791611
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/history/previous",} 4.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/history/previous",} 0.020627899
http_server_requests_seconds_count{exception="PatternSyntaxException",method="GET",outcome="CLIENT_ERROR",status="400",uri="/v1/ns/catalog/services",} 7.0
http_server_requests_seconds_sum{exception="PatternSyntaxException",method="GET",outcome="CLIENT_ERROR",status="400",uri="/v1/ns/catalog/services",} 0.016922114
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/configs/listener",} 11.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/configs/listener",} 2.300049356
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/**",} 54.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/**",} 0.308029526
http_server_requests_seconds_count{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/cs/configs/listener",} 25.0
http_server_requests_seconds_sum{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/cs/configs/listener",} 0.015753078
http_server_requests_seconds_count{exception="None",method="GET",outcome="CLIENT_ERROR",status="404",uri="/v1/cs/configs",} 330.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="CLIENT_ERROR",status="404",uri="/v1/cs/configs",} 0.386809273
# HELP http_server_requests_seconds_max  
# TYPE http_server_requests_seconds_max gauge
http_server_requests_seconds_max{exception="IllegalStateException",method="POST",outcome="SERVER_ERROR",status="500",uri="/v1/ns/raft/beat",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/history",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/actuator/prometheus",} 0.008721244
http_server_requests_seconds_max{exception="None",method="DELETE",outcome="SUCCESS",status="200",uri="/v1/ns/instance",} 0.0
http_server_requests_seconds_max{exception="None",method="POST",outcome="SUCCESS",status="200",uri="root",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/instance/statuses",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/operator/cluster/state",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/catalog/instances",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/catalog/services",} 0.0
http_server_requests_seconds_max{exception="None",method="PUT",outcome="SUCCESS",status="200",uri="/v1/ns/distro/datum",} 0.0
http_server_requests_seconds_max{exception="None",method="PUT",outcome="SUCCESS",status="200",uri="/v1/ns/distro/checksum",} 0.001314799
http_server_requests_seconds_max{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/auth/users/login",} 0.0
http_server_requests_seconds_max{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/core/cluster/report",} 0.00144165
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/console/server/state",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/distro/datum",} 0.0
http_server_requests_seconds_max{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/ns/service/status",} 0.002057098
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/configs",} 0.0
http_server_requests_seconds_max{exception="None",method="PUT",outcome="SUCCESS",status="200",uri="/v1/ns/instance/beat",} 0.001346235
http_server_requests_seconds_max{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/ns/instance",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/catalog/service",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/service/subscribers",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/**/favicon.ico",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/instance/list",} 0.002672669
http_server_requests_seconds_max{exception="None",method="GET",outcome="REDIRECTION",status="304",uri="/**",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/service/list",} 0.001539025
http_server_requests_seconds_max{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/cs/configs",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/console/namespaces",} 0.0
http_server_requests_seconds_max{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/ns/raft/beat",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/communication/dataChange",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/communication/configWatchers",} 0.0
http_server_requests_seconds_max{exception="None",method="PUT",outcome="SUCCESS",status="200",uri="root",} 0.00444349
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/ns/operator/server/status",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/history/previous",} 0.0
http_server_requests_seconds_max{exception="PatternSyntaxException",method="GET",outcome="CLIENT_ERROR",status="400",uri="/v1/ns/catalog/services",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/v1/cs/configs/listener",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/**",} 0.0
http_server_requests_seconds_max{exception="None",method="POST",outcome="SUCCESS",status="200",uri="/v1/cs/configs/listener",} 0.0
http_server_requests_seconds_max{exception="None",method="GET",outcome="CLIENT_ERROR",status="404",uri="/v1/cs/configs",} 0.0
# HELP tomcat_global_sent_bytes_total  
# TYPE tomcat_global_sent_bytes_total counter
tomcat_global_sent_bytes_total{name="http-nio-8849",} 4.411676522E9
# HELP tomcat_cache_hit_total  
# TYPE tomcat_cache_hit_total counter
tomcat_cache_hit_total 0.0
# HELP tomcat_cache_access_total  
# TYPE tomcat_cache_access_total counter
tomcat_cache_access_total 0.0
# HELP tomcat_sessions_alive_max_seconds  
# TYPE tomcat_sessions_alive_max_seconds gauge
tomcat_sessions_alive_max_seconds 0.0
# HELP jvm_gc_max_data_size_bytes Max size of old generation memory pool
# TYPE jvm_gc_max_data_size_bytes gauge
jvm_gc_max_data_size_bytes 0.0
# HELP jvm_memory_committed_bytes The amount of memory in bytes that is committed for the Java virtual machine to use
# TYPE jvm_memory_committed_bytes gauge
jvm_memory_committed_bytes{area="heap",id="PS Survivor Space",} 2097152.0
jvm_memory_committed_bytes{area="heap",id="PS Old Gen",} 1.073741824E9
jvm_memory_committed_bytes{area="heap",id="PS Eden Space",} 1.06954752E9
jvm_memory_committed_bytes{area="nonheap",id="Metaspace",} 9.0963968E7
jvm_memory_committed_bytes{area="nonheap",id="Code Cache",} 5.472256E7
jvm_memory_committed_bytes{area="nonheap",id="Compressed Class Space",} 1.1010048E7
# HELP jvm_gc_live_data_size_bytes Size of old generation memory pool after a full GC
# TYPE jvm_gc_live_data_size_bytes gauge
jvm_gc_live_data_size_bytes 0.0
# HELP system_cpu_count The number of processors available to the Java virtual machine
# TYPE system_cpu_count gauge
system_cpu_count 4.0
# HELP tomcat_servlet_error_total  
# TYPE tomcat_servlet_error_total counter
tomcat_servlet_error_total{name="default",} 0.0
tomcat_servlet_error_total{name="jsp",} 0.0
tomcat_servlet_error_total{name="dispatcherServlet",} 0.0
# HELP system_load_average_1m The sum of the number of runnable entities queued to available processors and the number of runnable entities running on the available processors averaged over a period of time
# TYPE system_load_average_1m gauge
system_load_average_1m 0.01
# HELP jvm_classes_loaded_classes The number of classes that are currently loaded in the Java virtual machine
# TYPE jvm_classes_loaded_classes gauge
jvm_classes_loaded_classes 15049.0
# HELP tomcat_global_received_bytes_total  
# TYPE tomcat_global_received_bytes_total counter
tomcat_global_received_bytes_total{name="http-nio-8849",} 5.07970989E8
# HELP nacos_timer_seconds_max  
# TYPE nacos_timer_seconds_max gauge
nacos_timer_seconds_max{module="config",name="notifyRt",} 0.0
# HELP nacos_timer_seconds  
# TYPE nacos_timer_seconds summary
nacos_timer_seconds_count{module="config",name="notifyRt",} 9.0
nacos_timer_seconds_sum{module="config",name="notifyRt",} 0.605
# HELP tomcat_servlet_request_seconds  
# TYPE tomcat_servlet_request_seconds summary
tomcat_servlet_request_seconds_count{name="default",} 0.0
tomcat_servlet_request_seconds_sum{name="default",} 0.0
tomcat_servlet_request_seconds_count{name="jsp",} 0.0
tomcat_servlet_request_seconds_sum{name="jsp",} 0.0
tomcat_servlet_request_seconds_count{name="dispatcherServlet",} 8043307.0
tomcat_servlet_request_seconds_sum{name="dispatcherServlet",} 9998.797
# HELP tomcat_global_error_total  
# TYPE tomcat_global_error_total counter
tomcat_global_error_total{name="http-nio-8849",} 338.0
# HELP tomcat_global_request_max_seconds  
# TYPE tomcat_global_request_max_seconds gauge
tomcat_global_request_max_seconds{name="http-nio-8849",} 29.528
# HELP tomcat_sessions_active_max_sessions  
# TYPE tomcat_sessions_active_max_sessions gauge
tomcat_sessions_active_max_sessions 0.0
# HELP jvm_classes_unloaded_classes_total The total number of classes unloaded since the Java virtual machine has started execution
# TYPE jvm_classes_unloaded_classes_total counter
jvm_classes_unloaded_classes_total 0.0
# HELP tomcat_sessions_created_sessions_total  
# TYPE tomcat_sessions_created_sessions_total counter
tomcat_sessions_created_sessions_total 0.0
# HELP jvm_gc_memory_allocated_bytes_total Incremented for an increase in the size of the young generation memory pool after one GC to before the next
# TYPE jvm_gc_memory_allocated_bytes_total counter
jvm_gc_memory_allocated_bytes_total 1.931053364376E12
# HELP jvm_gc_pause_seconds Time spent in GC pause
# TYPE jvm_gc_pause_seconds summary
jvm_gc_pause_seconds_count{action="end of minor GC",cause="Allocation Failure",} 1812.0
jvm_gc_pause_seconds_sum{action="end of minor GC",cause="Allocation Failure",} 16.135
# HELP jvm_gc_pause_seconds_max Time spent in GC pause
# TYPE jvm_gc_pause_seconds_max gauge
jvm_gc_pause_seconds_max{action="end of minor GC",cause="Allocation Failure",} 0.009
# HELP process_cpu_usage The "recent cpu usage" for the Java Virtual Machine process
# TYPE process_cpu_usage gauge
process_cpu_usage 0.01771575613618369
# HELP tomcat_sessions_active_current_sessions  
# TYPE tomcat_sessions_active_current_sessions gauge
tomcat_sessions_active_current_sessions 0.0
# HELP jvm_buffer_count_buffers An estimate of the number of buffers in the pool
# TYPE jvm_buffer_count_buffers gauge
jvm_buffer_count_buffers{id="direct",} 38.0
jvm_buffer_count_buffers{id="mapped",} 0.0
# HELP tomcat_sessions_rejected_sessions_total  
# TYPE tomcat_sessions_rejected_sessions_total counter
tomcat_sessions_rejected_sessions_total 0.0
# HELP jvm_threads_peak_threads The peak live thread count since the Java virtual machine started or peak was reset
# TYPE jvm_threads_peak_threads gauge
jvm_threads_peak_threads 203.0
# HELP tomcat_threads_config_max_threads  
# TYPE tomcat_threads_config_max_threads gauge
tomcat_threads_config_max_threads{name="http-nio-8849",} 200.0
# HELP tomcat_servlet_request_max_seconds  
# TYPE tomcat_servlet_request_max_seconds gauge
tomcat_servlet_request_max_seconds{name="default",} 0.0
tomcat_servlet_request_max_seconds{name="jsp",} 0.0
tomcat_servlet_request_max_seconds{name="dispatcherServlet",} 0.322
# HELP jvm_memory_max_bytes The maximum amount of memory in bytes that can be used for memory management
# TYPE jvm_memory_max_bytes gauge
jvm_memory_max_bytes{area="heap",id="PS Survivor Space",} 2097152.0
jvm_memory_max_bytes{area="heap",id="PS Old Gen",} 1.073741824E9
jvm_memory_max_bytes{area="heap",id="PS Eden Space",} 1.06954752E9
jvm_memory_max_bytes{area="nonheap",id="Metaspace",} 3.3554432E8
jvm_memory_max_bytes{area="nonheap",id="Code Cache",} 2.5165824E8
jvm_memory_max_bytes{area="nonheap",id="Compressed Class Space",} 3.27155712E8
# HELP logback_events_total Number of error level events that made it to the logs
# TYPE logback_events_total counter
logback_events_total{level="warn",} 2276.0
logback_events_total{level="debug",} 0.0
logback_events_total{level="error",} 1.0
logback_events_total{level="trace",} 0.0
logback_events_total{level="info",} 700781.0
# HELP process_start_time_seconds Start time of the process since unix epoch.
# TYPE process_start_time_seconds gauge
process_start_time_seconds 1.675857115245E9
# HELP jvm_buffer_total_capacity_bytes An estimate of the total capacity of the buffers in this pool
# TYPE jvm_buffer_total_capacity_bytes gauge
jvm_buffer_total_capacity_bytes{id="direct",} 712704.0
jvm_buffer_total_capacity_bytes{id="mapped",} 0.0
# HELP process_files_max_files The maximum file descriptor count
# TYPE process_files_max_files gauge
process_files_max_files 65535.0
```



## Nacos监控数据接入Promethues

在prometheus配置文件“prometheus.yml”添加如下内容

```
  - job_name: "nacos_configs"
    metrics_path: '/nacos/actuator/prometheus'
    static_configs:
      - targets: ["10.233.156.137:8849"]
```



## Nacos监控指标

| 序号 | 指标名称         | 指标内涵          | 计算公式                                                     |
| ---- | ---------------- | ----------------- | ------------------------------------------------------------ |
| 1    | heap堆内在使用率 | JVM的堆内存使用率 | sum(jvm_memory_used_bytes{area="heap"})/sum(jvm_memory_max_bytes{area="heap"}) * 100 |
| 2    | 阻塞线程数       | 阻塞线程数        | jvm_threads_states_threads{state="blocked"}                  |



## Nacos监控告警阈值

| 序号 | 指标名称         | 阈值  | 计算公式                                                     |
| ---- | ---------------- | ----- | ------------------------------------------------------------ |
| 1    | heap堆内在使用率 | >= 85 | sum(jvm_memory_used_bytes{area="heap"})/sum(jvm_memory_max_bytes{area="heap"}) * 100 |
| 2    | 阻塞线程数       | > 0   | jvm_threads_states_threads{state="blocked"}                  |

## Nacos监控展示

 [Nacos性能监控.json](Nacos性能监控.json) 

```
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "datasource",
          "uid": "grafana"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "target": {
          "limit": 100,
          "matchAny": false,
          "tags": [],
          "type": "dashboard"
        },
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "id": 29,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "collapsed": false,
      "datasource": {
        "type": "prometheus",
        "uid": "Fbpdsih4z"
      },
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 80,
      "panels": [],
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "Fbpdsih4z"
          },
          "refId": "A"
        }
      ],
      "title": "nacos monitor",
      "type": "row"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "Fbpdsih4z"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 4,
        "x": 0,
        "y": 1
      },
      "id": 89,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "colorMode": "none",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "textMode": "auto"
      },
      "pluginVersion": "9.1.2",
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "count(nacos_monitor{name=\"configCount\"})",
          "format": "time_series",
          "intervalFactor": 1,
          "range": true,
          "refId": "A"
        }
      ],
      "title": "UP",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "Fbpdsih4z"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 4,
        "x": 4,
        "y": 1
      },
      "id": 90,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "colorMode": "none",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "textMode": "auto"
      },
      "pluginVersion": "9.1.2",
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "max(nacos_monitor{name='serviceCount'})",
          "format": "time_series",
          "intervalFactor": 1,
          "range": true,
          "refId": "A"
        }
      ],
      "title": "service count",
      "type": "stat"
    },
    {
      "datasource": {},
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 4,
        "x": 8,
        "y": 1
      },
      "id": 93,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "colorMode": "none",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "textMode": "auto"
      },
      "pluginVersion": "9.1.2",
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "max(nacos_monitor{name='ipCount'})",
          "format": "time_series",
          "intervalFactor": 1,
          "range": true,
          "refId": "A"
        }
      ],
      "title": "ip count",
      "type": "stat"
    },
    {
      "datasource": {},
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 3,
        "x": 12,
        "y": 1
      },
      "id": 92,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "colorMode": "none",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "textMode": "auto"
      },
      "pluginVersion": "9.1.2",
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "max(nacos_monitor{name='configCount', instance=~'$instance'})",
          "format": "time_series",
          "intervalFactor": 1,
          "range": true,
          "refId": "A"
        }
      ],
      "title": "config count",
      "type": "stat"
    },
    {
      "datasource": {},
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 4,
        "x": 15,
        "y": 1
      },
      "id": 91,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "colorMode": "none",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "textMode": "auto"
      },
      "pluginVersion": "9.1.2",
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "sum(nacos_monitor{name='longPolling'})",
          "format": "time_series",
          "intervalFactor": 1,
          "range": true,
          "refId": "A"
        }
      ],
      "title": "long polling",
      "type": "stat"
    },
    {
      "datasource": {},
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 4,
        "x": 19,
        "y": 1
      },
      "id": 88,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "colorMode": "none",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "textMode": "auto"
      },
      "pluginVersion": "9.1.2",
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "sum(nacos_monitor{name='getConfig', instance=~'$instance'}) by (name)",
          "format": "time_series",
          "intervalFactor": 1,
          "range": true,
          "refId": "A"
        }
      ],
      "title": "config push total",
      "type": "stat"
    },
    {
      "datasource": {},
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "max": 100,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#299c46",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 50
              },
              {
                "color": "#d44a3a",
                "value": 80
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 4,
        "x": 0,
        "y": 5
      },
      "id": 33,
      "interval": "",
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true
      },
      "pluginVersion": "9.1.2",
      "repeatDirection": "h",
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "max(system_cpu_usage{instance=~'$instance'}) * 100",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "CpuUsed",
      "type": "gauge"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "Fbpdsih4z"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "max": 70,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#299c46",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 50
              },
              {
                "color": "#d44a3a",
                "value": 70
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 4,
        "x": 4,
        "y": 5
      },
      "id": 32,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true
      },
      "pluginVersion": "9.1.2",
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "sum(jvm_memory_used_bytes{area=\"heap\", instance=~'$instance'})/sum(jvm_memory_max_bytes{area=\"heap\", instance=~'$instance'}) * 100",
          "format": "time_series",
          "intervalFactor": 1,
          "range": true,
          "refId": "A"
        }
      ],
      "title": "MemoryUsed",
      "type": "gauge"
    },
    {
      "datasource": {},
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "max": 20,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#299c46",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 5
              },
              {
                "color": "#d44a3a",
                "value": 10
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 4,
        "x": 8,
        "y": 5
      },
      "id": 30,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true
      },
      "pluginVersion": "9.1.2",
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "max(system_load_average_1m{instance=~'$instance'})",
          "format": "time_series",
          "intervalFactor": 1,
          "range": true,
          "refId": "A"
        }
      ],
      "title": "load_1m",
      "type": "gauge"
    },
    {
      "datasource": {},
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "max": 5000,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#299c46",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 1000
              },
              {
                "color": "#d44a3a",
                "value": 5000
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 3,
        "x": 12,
        "y": 5
      },
      "id": 70,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true
      },
      "pluginVersion": "9.1.2",
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "max(nacos_monitor{name='avgPushCost', instance=~'$instance'})",
          "format": "time_series",
          "intervalFactor": 1,
          "range": true,
          "refId": "A"
        }
      ],
      "title": "avgPushCost",
      "type": "gauge"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "Fbpdsih4z"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "max": 2000,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#299c46",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 1000
              },
              {
                "color": "#d44a3a",
                "value": 2000
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 4,
        "x": 15,
        "y": 5
      },
      "id": 25,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true
      },
      "pluginVersion": "9.1.2",
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "sum(http_server_requests_seconds_count{uri=~'/v1/cs/configs|/nacos/v1/ns/instance|/nacos/v1/ns/health', instance=~'$instance'})",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Qps",
      "type": "gauge"
    },
    {
      "datasource": {},
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "max": 1500,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#299c46",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 800
              },
              {
                "color": "#d44a3a",
                "value": 1500
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 4,
        "x": 19,
        "y": 5
      },
      "id": 29,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true
      },
      "pluginVersion": "9.1.2",
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "max(jvm_threads_daemon_threads{instance=~'$instance'})",
          "format": "time_series",
          "intervalFactor": 1,
          "range": true,
          "refId": "A"
        }
      ],
      "title": "JvmThreads",
      "type": "gauge"
    },
    {
      "collapsed": false,
      "datasource": {
        "type": "prometheus",
        "uid": "Fbpdsih4z"
      },
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 9
      },
      "id": 78,
      "panels": [],
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "Fbpdsih4z"
          },
          "refId": "A"
        }
      ],
      "title": "nacos detail",
      "type": "row"
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": {
        "type": "prometheus",
        "uid": "Fbpdsih4z"
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 5,
        "w": 8,
        "x": 0,
        "y": 10
      },
      "hiddenSeries": false,
      "id": 20,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "9.1.2",
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "Fbpdsih4z"
          },
          "editorMode": "code",
          "expr": "http_server_requests_seconds_sum{uri=~'/v1/cs/configs|/nacos/v1/ns', instance=~'$instance'}/http_server_requests_seconds_count{uri=~'/v1/cs/configs|/nacos/v1/ns/instance|/nacos/v1/ns/health', instance=~'$instance'} * 1000",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "Fbpdsih4z"
          },
          "editorMode": "code",
          "exemplar": false,
          "expr": "sum(rate(http_server_requests_seconds_sum{instance=~'$instance'}[1m]))/sum(rate(http_server_requests_seconds_count{instance=~'$instance'}[1m])) * 1000",
          "format": "time_series",
          "hide": false,
          "instant": true,
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "__auto",
          "range": false,
          "refId": "B"
        }
      ],
      "thresholds": [],
      "timeRegions": [],
      "title": "rt",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "mode": "time",
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "logBase": 1,
          "show": true
        },
        {
          "format": "short",
          "logBase": 1,
          "show": true
        }
      ],
      "yaxis": {
        "align": false
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": {
        "type": "prometheus",
        "uid": "Fbpdsih4z"
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 5,
        "w": 8,
        "x": 8,
        "y": 10
      },
      "hiddenSeries": false,
      "id": 41,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "9.1.2",
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "repeat": "group",
      "repeatDirection": "h",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "nacos_monitor{name='longPolling', instance=~'$instance'}",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeRegions": [],
      "title": "long polling",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "mode": "time",
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": "",
          "logBase": 1,
          "show": true
        },
        {
          "format": "short",
          "logBase": 1,
          "show": true
        }
      ],
      "yaxis": {
        "align": false
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": {
        "type": "prometheus",
        "uid": "Fbpdsih4z"
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 5,
        "w": 8,
        "x": 16,
        "y": 10
      },
      "hiddenSeries": false,
      "id": 37,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "9.1.2",
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "system_load_average_1m{instance=~'$instance'}",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeRegions": [],
      "title": "load 1m",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "mode": "time",
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "logBase": 1,
          "show": true
        },
        {
          "format": "short",
          "logBase": 1,
          "show": true
        }
      ],
      "yaxis": {
        "align": false
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": {
        "type": "prometheus",
        "uid": "Fbpdsih4z"
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 5,
        "w": 8,
        "x": 0,
        "y": 15
      },
      "hiddenSeries": false,
      "id": 18,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "9.1.2",
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "http_server_requests_seconds_count{uri=~'/v1/cs/configs|/nacos/v1/ns/instance|/nacos/v1/ns/health', instance=~'$instance'}",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        },
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "sum(rate(http_server_requests_seconds_count[1m])) by(instance,method,uri)",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "__auto",
          "range": true,
          "refId": "B"
        }
      ],
      "thresholds": [],
      "timeRegions": [],
      "title": "qps",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "mode": "time",
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "logBase": 1,
          "show": true
        },
        {
          "format": "short",
          "logBase": 1,
          "show": true
        }
      ],
      "yaxis": {
        "align": false
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": {
        "type": "prometheus",
        "uid": "Fbpdsih4z"
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 5,
        "w": 8,
        "x": 8,
        "y": 15
      },
      "hiddenSeries": false,
      "id": 52,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "9.1.2",
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "nacos_monitor{name='leaderStatus', instance=~'$instance'}",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "__auto",
          "range": true,
          "refId": "B"
        }
      ],
      "thresholds": [],
      "timeRegions": [],
      "title": "leaderStatus",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "mode": "time",
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "logBase": 1,
          "show": true
        },
        {
          "format": "short",
          "logBase": 1,
          "show": true
        }
      ],
      "yaxis": {
        "align": false
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": {
        "type": "prometheus",
        "uid": "Fbpdsih4z"
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 5,
        "w": 8,
        "x": 16,
        "y": 15
      },
      "hiddenSeries": false,
      "id": 50,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "9.1.2",
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "nacos_monitor{name='avgPushCost', instance=~'$instance'}",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeRegions": [],
      "title": "avgPushCost",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "mode": "time",
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "logBase": 1,
          "show": true
        },
        {
          "format": "short",
          "logBase": 1,
          "show": true
        }
      ],
      "yaxis": {
        "align": false
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": {
        "type": "prometheus",
        "uid": "Fbpdsih4z"
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 5,
        "w": 8,
        "x": 0,
        "y": 20
      },
      "hiddenSeries": false,
      "id": 53,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "9.1.2",
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "nacos_monitor{name='maxPushCost', instance=~'$instance'}",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeRegions": [],
      "title": "maxPushCost",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "mode": "time",
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "logBase": 1,
          "show": true
        },
        {
          "format": "short",
          "logBase": 1,
          "show": true
        }
      ],
      "yaxis": {
        "align": false
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": {
        "type": "prometheus",
        "uid": "Fbpdsih4z"
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 5,
        "w": 8,
        "x": 8,
        "y": 20
      },
      "hiddenSeries": false,
      "id": 83,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "9.1.2",
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "nacos_monitor{name='publish', instance=~'$instance'}",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeRegions": [],
      "title": "config statistics",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "mode": "time",
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "logBase": 1,
          "show": true
        },
        {
          "format": "short",
          "logBase": 1,
          "show": true
        }
      ],
      "yaxis": {
        "align": false
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": {
        "type": "prometheus",
        "uid": "Fbpdsih4z"
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 5,
        "w": 8,
        "x": 16,
        "y": 20
      },
      "hiddenSeries": false,
      "id": 16,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "9.1.2",
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "datasource": {
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "sum(nacos_monitor{name=~'.*HealthCheck', instance=~'$instance'}) by (name,instance) * 60",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeRegions": [],
      "title": "health check",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "mode": "time",
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "logBase": 1,
          "show": true
        },
        {
          "format": "short",
          "logBase": 1,
          "show": true
        }
      ],
      "yaxis": {
        "align": false
      }
    }
  ],
  "refresh": false,
  "schemaVersion": 37,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": [
      {
        "allValue": "",
        "current": {
          "selected": false,
          "text": "10.233.156.136:8849",
          "value": "10.233.156.136:8849"
        },
        "datasource": {
          "type": "prometheus",
          "uid": "Fbpdsih4z"
        },
        "definition": "label_values(nacos_monitor, instance)",
        "hide": 0,
        "includeAll": true,
        "label": "instance",
        "multi": false,
        "name": "instance",
        "options": [],
        "query": {
          "query": "label_values(nacos_monitor, instance)",
          "refId": "StandardVariableQuery"
        },
        "refresh": 2,
        "regex": "/.*:8849/",
        "skipUrlSync": false,
        "sort": 0,
        "tagValuesQuery": "",
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      }
    ]
  },
  "time": {
    "from": "now-5m",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ],
    "time_options": [
      "5m",
      "15m",
      "1h",
      "6h",
      "12h",
      "24h",
      "2d",
      "7d",
      "30d"
    ]
  },
  "timezone": "",
  "title": "Nacos性能监控",
  "uid": "Bz_QALEiz1",
  "version": 11,
  "weekStart": ""
}
```

