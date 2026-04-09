**需求**

ES集群Cluster_A里的数据（某个索引或某几个索引），需要迁移到另外一个ES集群Cluster_B中。

1.1.**ES数据迁移有三种方式**

（一）Rolling upgrades回滚

（二）snapshot快照

（三）elasticdump方式

三种方式对比如下

|          | Rolling upgrades                                             | snapshot                                                     | elasticdump                                                  |
| -------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **优点** | 数据迁移速度快，无必要可以选择在线升级，无需停机。           | 操作简单，使用ElasticSearch内部命令无需新增其他插件          | 1、该方式是对每条数据进行导入导出，有良好的数据完整性2、迁移数据的两个集群间安全设置可以不同。3、操作更灵活，可以将数据导出到本地也可以直接在两个集群间直接进行数据交换 |
| **缺点** | 1、升级期间会占用大量磁盘IO，在线升级时可能会影响es的查询效率。2、在升级前做好充分的数据备份，因为在升级失败后数据无法在导入低版本集群中（只能通过恢复备份的方式进行回滚，在新版本运行期间的数据将丢失）3、跨两个或两个大版本以上的集群升级时，可能需要多个中间版本进行过度。4、对新环境的安全设置需要与原集群保持一致，否者无法进行通讯，对于新的安全设置可以在集群升级完成后在进行。 | 1、数据在做快照期间，会占用大量磁盘IO，若数据量级很大的时候，快照时间较长。2、Es7版本由于typs类型的修改，在做数据迁移前要先对数据做处理，去除自定义索引，或修改自定义索引的type为_doc3、 | 1、速度慢。2、在Es跨版本数据迁移时需要注意新版本特性，对于ES7特别要注意索引的type类型，ES7只支持_doc3、若数据类型不一致，需要在新集群中重新创建索引，然后在导入数据。对于使用在集群中使用了分词器操作，该分词器也要单独导入。 |



1.2 **.三种数据迁移的具体方法介绍**

1.2.1 **.Rolling upgrades滚动升级**

**方法说明**

该方法更好的使用在跨版本ES集群迁移中，它允许 ES集群一次升级一个节点，因此在升级期间不会中断服务。不支持在升级持续时间之后在同一集群中运行多个版本的 ES，因为无法将分片从升级的节点复制到运行旧版本的节点。所以在升级前需要对当前使用版本进行备份，以便在升级出现异常时进行回滚。

同时在升级过程中优先选择data节点，在data节点升级完成后，在对集群中master节点进行升级。

支持滚动升级准则：

同一主要版本的次要版本之间

v 从 5.6 到 6.8

v 从 6.8 到 7.17.5

v 从 7.17.0 到 7.17.5 的任何版本

从 6.7 或更早版本直接升级到 7.17.5 需要 完全重启集群。

在做滚动升级时需要保证ElasticSearch间的集群节点通讯，所以要保证安全认证同步。

参考官方链接：

https://www.elastic.co/guide/en/elasticsearch/reference/7.17/rolling-upgrades.html

**具体步骤**

**升级前准备**

在开始将集群升级到版本 7.17.5 之前，您应该执行以下操作：

1、检查弃用日志以查看您是否正在使用任何弃用的功能并相应地更新您的代码。

2、查看重大更改并对版本 7.17.5 的代码和配置进行任何必要的更改。

3、如果您使用任何插件，请确保每个插件都有一个与 Elasticsearch 版本 7.17.5 兼容的版本。

4、在升级生产集群之前，在隔离环境中测试升级。

5、通过拍摄快照备份您的数据！（或对当前集群所有节点进行数据和安装包进行全量备份）

**升级集群**

****禁用自动分片功能****（若在升级过程中不考虑IO性能瓶颈，可以忽略）

关闭一个数据节点时，分配过程会等待

index.unassigned.node_left.delayed_timeout（默认为一分钟），然后才开始将该节点上的分片复制到集群中的其他节点，这可能涉及大量 I/O。由于节点很快将重新启动，因此此 I/O 是不必要的。您可以通过在关闭数据节点之前禁用副本分配来避免争分夺秒 ：

PUT _cluster/settings{ “persistent”: { “cluster.routing.allocation.enable”: “primaries” }}

****停止不必要的索引并执行同步刷新。****（可选的）

POST _flush/synced

****暂停要升级节点与集群间其他节点进行数据通讯****，避免有新的数据产生（可选的）

POST _ml/set_upgrade_mode?enabled=true

关闭当前节点，在当前服务器中升级该节点ElasticSearch版本，其中ElasticSeaarch参考原节点进行配置。

****升级ElasticSearch使用插件\****

使用elasticsearch-plugin脚本安装每个已安装的 Elasticsearch 插件的升级版本。升级节点时必须升级所有插件。

语法：$ES_HOME bin/elasticsearch-plugin install XXXX

****启动升级的节点\****

语法：$ES_HOME bin/nohup ./elasticsearch &

****重新启用分片分配****（若为禁用自动分片功能，无需执行此步骤）

PUT _cluster/settings{ “persistent”: { “cluster.routing.allocation.enable”: null }}

****等待节点恢复\****

GET _cat/health?v=true

注意：

 在滚动升级期间，分配给运行新版本的节点的主分片不能将其副本分配给使用旧版本的节点。新版本可能具有旧版本无法理解的不同数据格式。

如果无法将副本分片分配给另一个节点（集群中只有一个升级节点），则副本分片保持未分配状态，状态保持不变yellow。

在这种情况下，一旦没有初始化或重新定位分片，您就可以继续（检查init和relo列）。一但另一个节点升级，就可以分配副本并且状态将更改为green。

****重复任务\****

当节点恢复并且集群稳定后，对每个需要更新的节点重复这些步骤。

****重新启动********节点与集群间其他节点进行数据通讯****（若已经暂停该功能，若未暂停，忽略此操作）

POST _ml/set_upgrade_mode?enabled=false

****注意\****

在滚动升级期间，集群继续正常运行。但是，在升级集群中的所有节点之前，任何新功能都会被禁用或以向后兼容的模式运行。一旦升级完成并且所有节点都在运行新版本，新功能就会开始运行。一但发生这种情况，就无法返回以向后兼容模式运行。运行先前版本的节点将不允许加入完全更新的集群。

如果升级过程中出现网络故障，将所有剩余的旧节点与集群隔离开来，您必须使旧节点脱机并升级它们以使其能够加入集群。

如果您在升级过程中同时停止一半或更多符合主节点条件的节点，则集群将不可用，这意味着升级不再是滚动升级。如果发生这种情况，您应该升级并重新启动所有已停止的符合主节点资格的节点，以允许集群再次形成，就像执行全集群重启升级一样。可能还需要升级所有剩余的旧节点，然后它们才能在重新形成后加入集群。

1.2.2 **snapshot快照**

**首先创建快照仓库**

注意：对于快照仓库需要每个节点都对其有访问权限，所以在实际使用中需要使用nfs挂载。

a)使用Psotman方式创建仓库

Postman:PUT [http://192.168.115.130:9200/_snapshot/my_repository](http://192.168.115.130:9200/_snapshot/my_hdfs_repository){ “type”: “fs”, “settings”: { “location”: “/home/elastic/my_repo_floder”, “compress”: ****true****, “max_restore_bytes_per_sec”: “50mb”, “max_snapshot_bytes_per_sec”: “50mb” }}

说明：my_repository为镜像仓库名称

Location 为镜像路径

![wps19.jpg](https://oss-emcsprod-public.modb.pro/image/editor/20221121-6a004863-80ad-4c95-80b7-c1c3f6455cb9.jpg)

**b)使用Curl方式创建仓库**

| curl -XPUT ‘http://192.168.115.130:9200/_snapshot/my_repository’ -H ‘content-Type:application/json’ -d ‘{ “type”: “fs”, “settings”: { “location”: “/home/elastic/my_repo_floder”, “compress”: ****true****, “max_restore_bytes_per_sec”: “50mb”, “max_snapshot_bytes_per_sec”: “50mb” }}’ |
| ------------------------------------------------------------ |
| ![wps20.jpg](https://oss-emcsprod-public.modb.pro/image/editor/20221121-c3a466a6-e32d-4520-a8f9-d365a2197191.jpg) |



**备份索引（全量）**

**a)使用Psotman方式备份**

| Postman:PUT [http://192.168.115.130:9200/_snapshot/my_repository/snapshot_1?wait_for_completion=true](http://192.168.115.130:9200/_snapshot/my_hdfs_repository/snapshot_1?wait_for_completion=true) |
| ------------------------------------------------------------ |
| ![wps21.jpg](https://oss-emcsprod-public.modb.pro/image/editor/20221121-93ce21d5-10cb-4cc1-8d95-0d9292a7e858.jpg) |



**b)使用Curl方式备份**

| curl -XPUT ‘http://192.168.115.130:9200/_snapshot/my_repository/snapshot_1?wait_for_completion=true’ |
| ------------------------------------------------------------ |
| ![wps22.jpg](https://oss-emcsprod-public.modb.pro/image/editor/20221121-ed7a1012-eca7-4d31-baa6-ef916a71aaa4.jpg) |



日志显示 completed with state [SUCCESS]

![wps23.jpg](https://oss-emcsprod-public.modb.pro/image/editor/20221121-1b0dcb6e-ec4e-422f-a919-df0bc24d0cee.jpg)

**c)查看备份对应索引信息**

| Postman:**GET** http://192.168.115.130:9200/_snapshot/my_hdfs_repository/snapshot_1#snapshot_1是备份文件名称 |
| ------------------------------------------------------------ |
| ![wps24.jpg](https://oss-emcsprod-public.modb.pro/image/editor/20221121-e52efbb0-742a-4768-9db3-129d84db7f74.jpg) |



1.2.3 **.elasticdump方式**

Elasticdump工具是依赖于npm进行安装的，可以参考如下地址进行安装：

https://www.cnblogs.com/itniwota/p/16011503.html

```
导出分词器

[root@localhost ~]# elasticdump --input=http://ip:9200/my_index --output=http://127.0.0.1:9200/my_index --type=analyzer 

 

导出映射mapping

[root@localhost ~]# elasticdump --input=http://ip:9200/ --output=http://127.0.0.1:9200/ --all=true --type=mapping

 

导出全部数据

[root@localhost ~]# elasticdump --input=http://ip:9200/ --output=http://127.0.0.1:9200/ --all=true --type=data

如果集群配置了x-pack认证

[root@localhost ~]# elasticdump --input=http://user:password@ip:9200/ --output=http://user:password@127.0.0.1:9200/ --all=true --type=data
```

1 .3**.迁移注意事项**

```
ES数据迁移有两种情况：
```

 一、ES版本不做变更，只是数据进行迁移；

 二、ES版本升级，同时数据迁移至新版本ES中

 上述三种方法均能完成ES的数据迁移，在实际操作时，请根据实际生产环境进行选择，优先选择**Rolling upgrades滚动升级**，同时需要注意一下几点：

 1、ES版本发生变化，需要关注JAVA版本是否要随之变化，ES7版本时开始内嵌JAVA版本为17版本，由原1.8版本升级到17版本，jdk跨度较大，对API的调用挑战性较强。需要经过大量测试，必要时需要对代码进行重构。

 2、ES存储数据类型发生变化，ES6版本中为自定义手动创建的，但是在ES7中只有一种数据类型为“doc”;

 3、当迁移数据量较大时，数据迁移花费时间较长，建议在业务平滑起或者晚上进行;

第三方迁移工具有多个:

Elaticsearch-dump:  支持es7.x 及前期多个版本，安装使用简便，结合shell脚本可做成全自动备份, github 4千星，可见非常热门

[github.com/taskrabbit/…](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Ftaskrabbit%2Felasticsearch-dump)

Elaticsearch-migration:  支持不同版本间相互迁移和basic auth, 使用golang编写，博主最近也一直在写golang,对这个迁移工具还是蛮感兴趣。

[github.com/medcl/esm-v…](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Fmedcl%2Fesm-v1)

Elaticsearch-Exporter:  支持不同版本间相互迁移，不过最近代码提交是2年前，不知道支不支持es7.x版本，这里博主没有测试

[github.com/mallocator/…](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Fmallocator%2FElasticsearch-Exporter)

经上述简单研究，决定使用Elaticsearch-dump 做为本次迁移的工具

## 3. 迁移准备

原es7.0 迁移至 es7.4 (es最新版本), 提前去es官网下载好es rpm文件(测试的话建议使用docker安装，简单方便)

### 3.1 elasticsearch安装

```ruby
wget  https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.4.2-x86_64.rpm
rpm -ivh elasticsearch-7.4.2-x86_64.rpm
复制代码
```

docker安装(开启跨域)

```bash
docker run -d --rm --name elasticsearch -p 9200:9200 -p 9300:9300 -e discovery.type=single-node -e http.cors.enabled=true -e http.cors.allow-origin=* -e http.cors.allow-headers=X-Requested-With,X-Auth-Token,Content-Type,Content-Length,Authorization -e http.cors.allow-credentials=true docker.elastic.co/elasticsearch/elasticsearch-oss:7.4.2
复制代码
```

### 3.2 elaticsearch-dump

```bash
3.2.1 安装nodejs
cd /opt
wget https://npm.taobao.org/mirrors/node/v10.15.3/node-v10.15.3-linux-x64.tar.gz
tar xf node-v10.15.3-linux-x64.tar.gz
mv  node-v10.15.3-linux-x64 node 
echo "export NODE_HOME=/opt/node" >> /etc/profile
echo "export PATH=\${NODE_HOME}/bin:$PATH" >> /etc/profile
source /etc/profile
3.2.2 安装elasticdump 
npm install elasticdump -g     #全局安装
elasticdump --help             #查看帮助
复制代码
```

### 3.3 记录待迁移elasticsearch 索引数据内容和数据总量，以便迁移后核对

```bash
curl http://ip:9200/_cat/indices
复制代码
```

## 4. 索引迁移(导出导入操作)

### 4.0 选项

```diff
--input: 数据来源
--output: 接收数据的目标
--type: 导出的数据类型（settings, analyzer, data, mapping, alias, template）
复制代码
```

### 4.1 索引导出

```bash
elasticdump --input=http://旧es_ip:9200/索引名称  --output=/opt/es/索引名称.index.json --type=data
复制代码
```

### 4.2 索引导入

```javascript
elasticdump --input=/opt/es/索引名称.index.json --output=http://新es_ip:9200
复制代码
```

### 4.3 导出导入设置

导入导出时会显示 每次操作的 object数据（默认为100），1万条数据用时1分30秒，如果调大，设置--limit参数既可

### 4.4 直接从源es到迁移到新的es

```ini
# 备份 mapping
elasticdump --input="http://localhost:9200/MyIndex" --output="http://localhost:9200/MyIndex" --type=mapping
# 备份数据
elasticdump --input="http://localhost:9200/MyIndex" --output="http://localhost:9200/MyIndex" --type=data
复制代码
```

### 4.5 数据比对(使用shell命令diff比较既可)

数据对比方法:
 老数据: curl -s [http://172.1.1.6:9200/\_cat/indices](https://link.juejin.cn?target=http%3A%2F%2F172.1.1.6%3A9200%2F%5C_cat%2Findices) | awk '{print 3,3,3,7}' |sort -nr > es1.txt
 新数据: curl -s [http://127.0.0.1:9200/\_cat/indices](https://link.juejin.cn?target=http%3A%2F%2F127.0.0.1%3A9200%2F%5C_cat%2Findices) | awk '{print 3,3,3,7}' | sort -nr > es2.txt

比较数据结果:
 diff es1.txt es2.txt

### 4.6 部分字段导出

```vbnet
elasticdump --input=http://ip:9200/test  --output=test.json --sourceOnly --searchBody='
{
  "query": {
    "bool": {
      "must": [
        {
          "match_phrase": 
          {"xhdwsbh": "22222"}
          
        },
        {
          "range": {
            "kprq": {
              "gte": "20201105",
              "lte": "20201106"
            }
          }
        }
      ]
    }
    
    
  } ,
  "_source": ["fplxdm","fpdm","fphm","fpzt","kprq","xhdwsbh","xhdwmc","xhdwdzdh","xhdwyhzh","ghdwsbh","ghdwmc","ghdwdzdh"]
}' 
复制代码
```

## 5. 复杂索引导入导出

### 5.1 复制完索引 但是 setting 或 mapping 有问题

```ini
#这个执行会有一点小卡顿 且不能使用 settings模式，会导致数据写不进去
elasticdump --input="http://xxxxx:9200/xxx_test" --output="http://xxxx:9200/test5" --type=analyzer

elasticdump --input="http://xxxxx:9200/xxx_test" --output="http://xxxx:9200/test5" --type=mapping
复制代码
```

### 5.2 根据字段内容备份

```swift
elasticdump \
  --input=http://xxxxx:9200/my_index \
  --output=query.json \
  --searchBody="{\"query\":{\"term\":{\"username\": \"admin\"}}}"

# 帮助文档：https://github.com/elasticsearch-dump/elasticsearch-dump
复制代码
```

## 6. 可视化工具(es数据查看)

  目前流行的工具有elasticsearch-head, elaticsearch-HQ, kibana,dejavu

kibana为官方工具，提供了索引查看，管理和图表功能

head为es插件，提供了索引管理(删增), 数据查看功能(界面不够美观)

elaticsearch-HQ 官方介绍: Monitoring and Management Web Application for ElasticSearch instances and clusters

dejavu  界面美观，支持增删改查，可惜一次只能连接一个索引。需要页面多开

以上4个工具都提供了docker 一键安装,简单高效

这里使用dejavu工具，不尽界面美观，还支持数据增删改查功能，简单好用

```arduino
docker run -p 1358:1358 -d appbaseio/dejavu
复制代码
```

待启动完成后访:  [http://ip:1358](https://link.juejin.cn?target=http%3A%2F%2Fip%3A1358)

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/75eb0d8e9c294a6fa8020d8f938bc0dc~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/e81a7dfbcab148bca91819dbf23f375a~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

