https://artifacthub.io/packages/helm/phntom/docker-registry

使用minio作为对象存储



```
helm repo add stable https://charts.helm.sh/stable
helm repo add phntom https://phntom.kix.co.il/charts/
helm repo update
helm show values phntom/docker-registry > values.yaml

yum install -y httpd-tools -y
htpasswd -Bnb admin admin123

helm install docker-registry phntom/docker-registry -n registry -f values.yaml

vi /etc/docker/daemon.json
{
  "insecure-registries": ["your.registry.url:port"]
}
systemctl daemon-reload
systemctl restart docker

docker login registry.lmgsanm.test.com

```

