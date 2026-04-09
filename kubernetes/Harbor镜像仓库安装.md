# 第一部分	背景

# 第二部分	原理

# 第三部分	分析

# 第四部分	实践

curl -SL https://github.com/docker/compose/releases/download/v2.7.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose

mv docker-compose-linux-x86_64 docker-compose

chmod +x docker-compose

 mv docker-compose /usr/local/bin/

tar xzf harbor-offline-installer-v1.10.10.tgz

 cd harbor

mkdir -p certs

openssl req -newkey rsa:4096 -nodes -sha256 -keyout certs/domain.key -x509 -days 36500 -out certs/domain.crt

![image-20220726225255824](E:\data\github\self\03-个人总结\00-实践总结\image-20220726225255824.png)

![image-20220726225411863](E:\data\github\self\03-个人总结\00-实践总结\image-20220726225411863.png)





cat > /etc/sysctl.d/k8s.conf <<EOF 
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl -p /etc/sysctl.d/k8s.conf





# 第五部分	验证