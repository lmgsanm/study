https://goharbor.io/docs/2.13.0/install-config/download-installer/

https://github.com/goharbor/harbor/releases

```
wget https://github.com/goharbor/harbor/releases/download/v2.15.0/harbor-offline-installer-v2.15.0.tgz
tar xzf harbor-offline-installer-v2.15.0.tgz
cd harbor
cp harbor.yml.tmpl harbor.yml
./prepare
wget https://github.com/docker/compose/releases/download/v2.40.3/docker-compose-linux-x86_64
mv docker-compose-linux-x86_64 docker-compose
chmod u+x docker-compose
mv docker-compose /usr/bin/
./install.sh
docker-compose down -v
docker-compose up -v

```

