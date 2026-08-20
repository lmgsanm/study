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
- progressDeadlineSeconds：设置未能处于部署完成状态的超时时间，默认值为600s（10min）。达到这个时间后，系统将设置Progressing的状态（Status）为False，并将Reason设置为ProgressDeadlineExeceeded。
- revisionHistoryLimit：修订历史最大数量，第个修订都有一个对应的ReplicaSet资源，保存得过多将消耗更多资源，默认值为10.
- paused：设置为true来表示部署过程处于暂停状态。设置false来表示处于正常部署过程。Kubernetes对处于暂停状态的Deployment资源将不会监控Pod模板变化，而对于非暂停状态的Pod模板变化会触发新的rollout操作。

其中spec.selector是与目标Pod关联的核心字段，可以通过matchLabels或matchExpressions字段进行设置，Pod的标签则在spec.template.matadata.labels[]字段中进行设置。它们的用法和处理逻辑如下：

- matchLabels：设置一个或多个（Pod需要具有的）标签的值，以key:value格式表示，如果设置了多个标签，相互为逻辑与（AND）关系，即需要满足全部条件（Pod具有全部标签）才能与Pod关联成功。
- matchExpressions：设置一个或多个（Pod需要具有的）标签的值，以（key,operator,values）三元组格式进行设置，其中values可以设置多个值，可以使用的运行符包括In、NotIng、Exists和DoseNotExist，使用In和NotIng运行符时，需要values的值不能为空

如果matchLabels或matchExpressions两组配置都设置了，则要求Pod的标签满足全部的条件（逻辑与运算）才能完成关联。

另外，Deployment的标签选择器配置在创建后是不能修改的，如果需要修改，只能删除Development后重新创建。

### 4.2.3	Deployment的更新机制

Deployment支持对Pod进行自动更新，通过以滚动更新的方式通过多个ReplicaSet版本完成对Pod的自动更新，适用于容器镜像更新后自动部署新版本应用的场景。

#### 常用查看滚动更新状态命令

- kubectl rollout status：查看Deployment的更新过程
- kubectl describe：查看Deployment的详细事件信息
- kubectl get replicasets：查看两个ReplicaSet的最终状态

#### 滚动更新过程中的原则

- 在整个更新过程中，系统会保证至少有2个Pod可用，并且最多同时运行4个Pod。Deployment需要确保在整个更新过程中只有一定数量的Pod可能处于不可用状态。

- 在默认情况下，Deployment确保可用的Pod总数量至少为期望副本数量（DESIRED）减1，也就是最多1个可用用（maxUnavailable=1）。Deployment还需要确保整个更新过程中的总数量不会超过所需要的Pod副本数量太多。
- Deployment确保Pod的总数量最多比所需的Pod数量多1个，也就是最多1个浪涌值（maxSurge=1）。
- maxUnavailable和maxSurger的默认值为所需Pod副本数量的25%、25%。

#### Pod的更新策略（默认为RollingUpdate）

- Recreate：设置spec.strategy.type=Recreate来表示Deployment在更新Pod时，会先“杀掉”所有正在运行的旧版本Pod，等到旧版本Pod全部终止后，才开始创建新版本的Pod。
- RollingUpdate：spec.strategy.type=RollingUpdate来表示Deployment会以滚动更新的方式逐个更新Pod，同时可以设置spec.strategy.rolingUpdate下的两个参数（maxUnavailable和maxSurge）来控制滚动更新的过程

#### 滚动更新的两个主要参数

- spec.strategy.rolingUpdate.maxUnavailable：用于指定Deployment在更新过程中不可用状态的Pod数量上限。该参数值可以是绝对值或Pod期望副本数量的百分比，如果该参数被设置为百分比，那么系统会先以向下的方式计算出绝对值（整数）。当maxSurge被设置为0时，maxUnavailable则必须被设置国绝对值大于0.
- spec.strategy.rolingUpdate.maxSurge：用于指定在Deployment更新Pod的过程中Pod总数量超过Pod期望副本部分的最大值。该参数值可以是绝对值或Pod期望副本数量的百分比，如果该参数被设置为百分比，那么系统会先以向上的方式计算出绝对值（整数）。

#### 多重更新

​	如果Deployment的上一次更新正在进行，此时用户两次发起Deployment的更新操作，那么 Deployment会为每一次更新都创建一个ReplicaSet，而每次在新的ReplicaSet创建成功后，会逐个增加Pod副本数量，同时将之前正在扩容的ReplicaSet停止扩容（更新），并将其加入旧版本ReplicaSet列表中，然后开始缩容至0的操作。

### 4.2.4 Deployment的回滚

#### 常用的回滚命令

- kubectl rollout history：查看检查部署这个Deployment的历史记录
- kubectl rollout ondo：撤消本次发布并回滚到上一个部署版本

​	使用--to-revision参数指定部署版本号。

### 4.2.5 Deployment部署的暂停和恢复

- kubectl rollout pause：暂停Deployment的更新操作
- kubectl rollout resume：恢复Deployment的更新操作

### 4.2.6 Deployment的生命周期

​	Deployment资源的生命周期有如下几种状态：

- Progressing（部署进行中）
- Complete（部署完成）
- Failed（部署失败）

#### Progressing情形

- 正在创建新的ReplicaSet
- 正在为最新的ReplicaSet进行水平扩容操作
- 正在为旧的ReplicaSet进行水平缩容操作
- 亲的Pod处理Ready状态或Availiable状态

#### Complete情形

- 最新版本的ReplicaSet已部署完成
- Pod副本数量达到期望副本数量，并且都处于可用状态
- 没有旧的Pod副本还在运行

#### Failed情形

- 容器镜像下载失败
- Pod所需的资源配额一直不足
- 启动Pod所需的权限不足
- 资源限制范围LimitRange配置不正确
- Pod的服务就绪探针（ReadinessProbe）一直失败
- 容器应用启动一直失败

## 4.3 DaemonSet：每个Node仅运行一个Pod

### 4.3.1	DeamonSet概述

应用场景如下：

- 在每个Node上都运行一个共享存储驱动守护进程
- 在每个Node上都运行一个日志采集程序，采集Node上全部容器的日志
- 在每个Node上都运行一个性能监控程序，采集Node上容器和操作系统的运行性能数据

4.3.2	DeamonSet的配置信息

- selector：标签选择器，用于关联具有指定标签的Pod列表
- template：Pod模板，其中的配置项就是Pod的定义。作为Deployment资源 的一部分夏存，无须再设置apiVersion和kin这两个元数据
- updateStrategy：更新策略，可选项包括OnDelete和RollingUpdate
- minReadySeconds：Pod最短就绪时间，至少要达到这个时间，系统才会设置Pod状态为Ready状态。默认为0。
- revisionHistoryLimit：修订历史最大数量，默认值为10。

## 4.4 StatefulSet：：面向有状态应用的Pod副本集管理

## 4.5 Pod水平扩容机制

## 4.6 Job批处理任务

## 4.7 CronJob定时任务

