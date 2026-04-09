## 查看可用的设备

[root@server ~]# nmcli connection show
NAME    UUID                                  TYPE      DEVICE
enp0s3  bec8bf1a-6e2e-3f2e-91fc-182aac7a2c61  ethernet  enp0s3
lo      e55b4c51-bed0-4ebf-b6fc-51ed9d633b15  loopback  lo

# 方法一、直接修改IP配置

如不存在 /etc/NetworkManager/system-connections/enp0s3.nmconnection配置文件，使用如下命令配置IP地址

执行如下命令后，在RockyLinux 8会在/etc/sysconfig/network-scripts/中生成ifcfg-enp0s3文件

```
 ## 语法：nmcli con add type ethernet ifname <网卡名> con-name <连接名> ipv4.method manual ipv4.addresses <IP/掩码> ipv4.gateway <网关> ipv4.dns <DNS>
 
 nmcli con add type ethernet ifname enp0s3 con-name enp0s3 ipv4.addresses 192.168.1.9/24 ipv4.gateway 192.168.1.1 ipv4.dns "202.96.134.133" ipv4.method manual
```

如存在 /etc/NetworkManager/system-connections/enp0s3.nmconnection配置文件，则使用如下命令配置IP地址

```
nmcli con mod enp0s3 ipv4.addresses 192.168.1.100/24 ipv4.gateway 192.168.1.1 ipv4.dns "202.96.134.133" ipv4.method manual
```



# 方法二、配置文件设置

## 配置文件

创建一个以.nmconnection结尾的配置文件，按实际需要填写如下内容，uuid可不填写

```
cat /etc/NetworkManager/system-connections/enp0s3.nmconnection

[connection]
id=enp0s3
uuid=bec8bf1a-6e2e-3f2e-91fc-182aac7a2c61
type=ethernet
autoconnect-priority=-999
interface-name=enp0s3
timestamp=1761545953

[ethernet]

[ipv4]
method=manual
address=192.168.1.11/24
dns=202.96.134.133;8.8.8.8
gateway=192.168.1.1

[ipv6]
addr-gen-mode=eui64
method=auto

[proxy]
```

## 修改配置文件权限

```
chmod 600 /etc/NetworkManager/system-connections/enp0s3.nmconnection
```



## 加载配置文件

### 第一次配置需加载配置文件

```
[root@server ~]# nmcli connection load /etc/NetworkManager/system-connections/enp0s3.nmconnection
```



### 修改IP地址后需重载配置文件 

```
[root@server ~]# nmcli connection reload /etc/NetworkManager/system-connections/enp0s3.nmconnection
```



## 重启网卡设备

```
[root@server ~]# nmcli connection down enp0s3 &&  nmcli connection up   enp0s3
Connection 'enp0s3' successfully deactivated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/6)
Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/7)
```

# nmcli使用

