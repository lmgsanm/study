#!/bin/bash
apiserver_version="v1.24.0"
controller_version="v1.24.0"
scheduler_version="v1.24.0"
proxy_version="v1.24.0"
pause_version="3.7"
etcd_version="3.5.3-0"
coredns_version="v1.8.6"

grc_uri="k8s.gcr.io"
aliyuncs_uri="registry.aliyuncs.com/google_containers"
#docker pull
docker pull ${aliyuncs_uri}/kube-apiserver:${apiserver_version}
docker pull ${aliyuncs_uri}/kube-controller-manager:${controller_version}
docker pull ${aliyuncs_uri}/kube-scheduler:${scheduler_version}
docker pull ${aliyuncs_uri}/kube-proxy:${proxy_version}
docker pull ${aliyuncs_uri}/pause:${pause_version}
docker pull ${aliyuncs_uri}/etcd:${etcd_version}
docker pull ${aliyuncs_uri}/coredns:${coredns_version}

#tag images
docker tag ${aliyuncs_uri}/kube-apiserver:${apiserver_version} ${grc_uri}/kube-apiserver:${apiserver_version}
docker tag ${aliyuncs_uri}/kube-controller-manager:${controller_version} ${grc_uri}/kube-controller-manager:${controller_version}
docker tag ${aliyuncs_uri}/kube-scheduler:${scheduler_version} ${grc_uri}/kube-scheduler:${scheduler_version}
docker tag ${aliyuncs_uri}/kube-proxy:${proxy_version} ${grc_uri}/kube-proxy:${proxy_version}
docker tag ${aliyuncs_uri}/pause:${pause_version} ${grc_uri}/pause:${pause_version}
docker tag ${aliyuncs_uri}/etcd:${etcd_version} ${grc_uri}/etcd:${etcd_version}
docker tag ${aliyuncs_uri}/coredns:${coredns_version} ${grc_uri}/coredns/coredns:${coredns_version}

#remove aliyun images
docker rmi ${aliyuncs_uri}/kube-apiserver:${apiserver_version}
docker rmi ${aliyuncs_uri}/kube-controller-manager:${controller_version}
docker rmi ${aliyuncs_uri}/kube-scheduler:${scheduler_version}
docker rmi ${aliyuncs_uri}/kube-proxy:${proxy_version}
docker rmi ${aliyuncs_uri}/pause:${pause_version}
docker rmi ${aliyuncs_uri}/etcd:${etcd_version}
docker rmi ${aliyuncs_uri}/coredns:${coredns_version}
