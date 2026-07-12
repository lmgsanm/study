## 4.1 Pod的工作负载管理机制概述

RC（ReplicationController）设计实现方式：RC独立于所控制的Pod，并通过标签这个检耦合关联关系控制目标Pod实例的创建和销毁。

RC的继任者是ReplicaSet。ReplicaSet进一步增强了RC标签选择器的灵活性，之前RC的标签选择器只能选择一个Pod标签，而ReplicaSet拥有集合式的标签选择器，可以选择多个Pod标签。

ReplicaSet被设计成能控制多个不同标签的Pod副本。

Kubernetes的滚动更新就是巧妙的运行ReplicaSet这个特性来实现，同时Deployment也通过ReplicaSet实现Pod副本自动控制功能。	

## 4.2 Deployment：面向无状态应用的Pod副本集管理

Deployment是一种面向无状态应用的多个Pod副本进行自动化管理的工作负载控制器。无状态应用通常要求每个Pod副本的工作机制相同，提供的服务也相同。

Deployment在部署Pod之后会持续监控副本的运行状态和数量，始终保证用户指定的副本数量的Pod正常运行。

常见Deployment的应用场景如下：

- 部署一个多副本的无状态应用。
- 多副本Pod的版本更新，以及部署过程的暂停和回滚。
- Pod副本数量的水平扩缩容。

### 4.2.1 Deployment提供的管理功能

#### kubectl get deployment命令的关键字段说明

- NAME：Deployment的名称
- READY：处理Ready状态的Pod副本数量，“/”右侧为期望的Pod副本数量，即sepc.replicas字段的设置值
- UP-TO-DATE：更新到最新Pod模板的Pod副本数量
- AVAILBLE：可代用户使用的Pod副本数量
- AGE：Deployment的运行时间

#### kubectl get replicasets命令的关键字段说明

- NAME：ReplicaSet的名称
- DESIRED：期望的Pod副本数量，即spec.replicas字段设置的值
- CURRENT：当前处于运行状态的Pod副本数量
- READY：处理Ready状态的副本数量
- AGE：Deployment的运行时间

### 4.2.2 Deployment的配置信息

#### Deployment配置中spec部分的核心配置字段

- selector：标签选择器，用于关联具有指定标签的Pod列表
- template：Pod模板，其中的配置项就是Pod的定义。作为Deployment资源 的一部分夏存，无须再设置apiVersion和kin这两个元数据
- replicas：期望的Pod副本数量，默认值为1。通过kubectl scale命令调整后的副本数量将会覆盖初始设置的值。如果使用自动扩缩容（HorizontalPodAutoscale）来自动调整Pod副本数量，则不需要设置这个值。
- strategy：更新策略，可选项包括Recreate和RollingUpdate
- minReadySeconds：Pod最短就绪时间，至少要达到这个时间，系统才会设置Pod状态为Ready状态。
- progressDeadlineSeconds
- revisionHistoryLimit
- paused：

## 4.3 DaemonSet：每个Node仅运行一个Pod

## 4.4 StatefulSet：：面向有状态应用的Pod副本集管理

## 4.5 Pod水平扩容机制

## 4.6 Job批处理任务

## 4.7 CronJob定时任务

