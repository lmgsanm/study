

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring

helm show values prometheus-community/kube-prometheus-stack > values-default.yaml 
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f values.yaml
```





```
mkdir -p /data/grafana
chmod 777 /data/grafana
cat >>  /etc/exports << EOF
/data/grafana  *(rw,sync,no_root_squash,no_all_squash)
EOF
exportfs -rv
systemctl restart rpcbind
systemctl restart nfs-server
```

