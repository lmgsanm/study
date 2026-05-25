#!/bin/bash
VERSION=\$1
REPOS=registry.aliyuncs.com
IMAGES_NAME="metrics-server"
HOSTS="node01 node02 node03"
for name in \${IMAGES_NAME}
do
	docker pull \${REPOS}/google_containers/\${name}:\${VERSION}	#从docker.m.daocloud.io下载镜像
	docker tag \${REPOS}/google_containers/\${name}:\${VERSION} registry.k8s.io/metrics-server/\${name}:\${VERSION}	#修改镜像名称的URL地址
	docker save -o	\${name}_\${VERSION}.tar registry.k8s.io/metrics-server/\${name}:\${VERSION}	#打包镜像成tar包
	#将镜像传输至其它节点的root用户下的home目录
	for host in \${HOSTS}
	do
		scp \${name}_\${VERSION}.tar \${host}:~
	done
done