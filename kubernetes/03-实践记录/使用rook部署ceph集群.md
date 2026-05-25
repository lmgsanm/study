不支持文件目录存储

https://rook.github.io/docs/rook/v1.19/Getting-Started/quickstart/#tldr

```
git clone --single-branch --branch v1.19.3 https://github.com/rook/rook.git
cd rook/deploy/examples

#修改operator.yaml，使支持文件目录方式
#将ROOK_CEPH_ALLOW_LOOP_DEVICES的配置修改为true
[root@kube-master examples]# kubectl -n rook-ceph logs -f deploy/rook-ceph-operator
2026-04-11 03:20:00.413929 I | op-k8sutil: ROOK_WATCH_FOR_NODE_FAILURE="true" (configmap)
2026-04-11 03:20:00.418382 I | op-k8sutil: ROOK_WATCH_FOR_NODE_FAILURE="true" (configmap)
2026-04-11 03:20:00.500636 I | op-k8sutil: ROOK_CEPH_COMMANDS_TIMEOUT_SECONDS="15" (configmap)
2026-04-11 03:20:00.500657 I | op-k8sutil: ROOK_LOG_LEVEL="INFO" (configmap)
2026-04-11 03:20:00.500664 I | op-k8sutil: ROOK_ENABLE_DISCOVERY_DAEMON="false" (configmap)
2026-04-11 03:20:00.502991 I | op-k8sutil: ROOK_CEPH_ALLOW_LOOP_DEVICES="true" (configmap)


kubectl create -f crds.yaml -f common.yaml -f csi-operator.yaml -f operator.yaml

kubectl delete -f crds.yaml -f common.yaml -f csi-operator.yaml -f operator.yaml

 wget https://github.com/rook/rook/archive/refs/tags/v1.12.11.tar.gz
git clone --branch v1.12.11 https://github.com/rook/rook.git
 kubectl create -f crds.yaml -f common.yaml -f operator.yaml
 
 kubectl -n rook-ceph logs -f deploy/rook-ceph-operator
 

wget https://github.com/rook/rook/archive/refs/tags/v1.12.0.tar.gz

#修改cluster.yaml配置,添加目录相关配置
  storage: # cluster level storage configuration and selection
    useAllNodes: false
    useAllDevices: false
    deviceFilter: ""
    devices: []
    directories:
      - path: /data/ceph
    #deviceFilter:
    config:
      # crushRoot: "custom-root" # specify a non-default root label for the CRUSH map
      # metadataDevice: "md0" # specify a non-rotational storage so ceph-volume will use it as block db device of bluestore.
      # databaseSizeMB: "1024" # uncomment if the disks are smaller than 100 GB
      # osdsPerDevice: "1" # this value can be overridden at the node or device level
      # encryptedDevice: "true" # the default value for this option is "false"
      # deviceClass: "myclass" # specify a device class for OSDs in the cluster
    allowDeviceClassUpdate: false # whether to allow changing the device class of an OSD after it is created
    allowOsdCrushWeightUpdate: false # whether to allow resizing the OSD crush weight after osd pvc is increased
    # Individual nodes and their config can be specified as well, but 'useAllNodes' above must be set to false. Then, only the named
    # nodes below will be used as storage resources.  Each node's 'name' field should match their 'kubernetes.io/hostname' label.
    nodes:
      - name: "172.23.171.172"
      - name: "172.23.171.173"

mkdir -p /data/ceph
chmod 777 /data/ceph

kubectl get no -o yaml | grep taint -A 5
kubectl taint node kube-master node.kubernetes.io/not-ready:NoSchedule-

kubectl create -f cluster.yaml
```

https://rook.github.io/docs/rook/v1.19/CRDs/Cluster/ceph-cluster-crd/

https://itho.cn/k8s/401.html



