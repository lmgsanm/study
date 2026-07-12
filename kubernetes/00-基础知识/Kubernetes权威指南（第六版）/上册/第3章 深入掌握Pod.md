## 3.1 Pod定义详解

**YAML格式的Pod配置文件**

```YAML

```

**Pod配置文件中各属性详细说明**

| 属性名称 | 取值类型 | 是否必选 | 取值说明 |
| -------- | -------- | -------- | -------- |
|          |          |          |          |
|          |          |          |          |

## 3.2 Pod基本用法

Pod是Kubernetes中应用的最小管理单元，可以包含一个或多个容器，它们在Pod内共享网络配置和存储卷配置。

Pod中除了包含应用程序，还可以包含应用程序容器启动之前的初始化容器（Init Container），它们在运行结束后就停止了，通常用于为应用程序容器提供初始化的环境配置工作。

一个应用程序通常有两种运行方式：

* 长时间运行（服务型）
* 运行一次就结束（任务型）

对长时间运行容器的要求：其主程序需要一直在前台运行。如果容器镜像的主程序是在后台执行，则Kubernetes在创建这个容器的Pod之后，若其启动命令已运行完毕，就认为容器运行结束，会立刻结束运行该容器。

对一次性运行容器的要求：其主程序在运行完毕后应该退出，退出码可能为正确或者错误。

## 3.3 静态Pod

静态Pod是由kubelet管理的仅存在于kubelet所在Node节点上的Pod，不需要通过Kubenetes的Master（Controller Manager）管理。kubelet负责：

- 监控由它创建的静态Pod，并且在Pod失效时重建pod。
- 向Master注册在本Node创建的静态Pod：管理员可以通过API Server的接口查看静态Pod信息，只是不能䏍Master管理和控制。

静态Pod不能使用普通Pod可以使用的其它资源，如ConfigMap、Secret、ServiceAccount等。

创建静态Pod的两种方式：

- 基于本地配置文件
- 基本网络上的配置文件

### 1、基于本地配置文件

1. 在kubelet的主配置文件中设置staticPodPath，指定kubelet需要监控的配置文件所在目录
2. kubelet定期扫描staticPodPath指定的目录，根据该目录下的.yaml和.json文件创建静态Pod
3. 如想删除静态Pod，只能删除该目录下的.yaml或.json文件

**注：kubelet在扫描文件时会忽略以"."开头的隐藏文件**

### 2、基于网络上的配置文件

通过使用设置kubelet启动参数--manifest-url指向一个提供配置文件的网络URL地址，kubelet将会定期从该URL地址下载Pod的定义文件，并以.yaml或.json文件的格式进行解析，之后创建静态Pod。

## 3.4 容器共享Volume

同一个Pod中的多个容器能够共享Pod级别的存储卷Volume。

Volume可以被定义为各种类型，多个容器自行进行挂载操作，将Volume挂载为容器内需要的目录

## 3.5 Pod的配置管理

### 3.5.1	ConfigMap概述

ConfigMap用于保存应用程序运行时需要的配置数据，通过明文（不加密）及key:value形式存储

ConfigMap供容器使用的三种典型用法如下：

- 生成容器内的环境变量
- 设置容器启动命令的命令行参数（需要设置为环境变量）
- 以Volume的形式挂载为容器文件或目录

ConfigMap以一个或多个key:value的形式保存在Kubernetes系统中供应用使用，既可用于表示一个变量的值，也可用于表示一个完整配置文件的内容

由于ConfigMap受限于命名空间，所以在引用ConfigMap的Pod必须与ConfigMap处于相同的命名空间，才能引用成功。

在ConfigMap中不存在spec字段，它通过data或binaryData字段配置数据：

- data字段用于保存经过UTF-8编码的文本字符串
- binaryData字段用于保存经过base64编码的二进制数据
- immutable用于设置配置数据为不可修改（可选）

### 3.5.2	创建ConfigMap

创建ConfigMap的几种方式：

- 基于本地配置文件
- 基于kubectl命令行
- 基于kustomization配置文件及kustomize

**1.基于本地配置文件**

**2.基于kubectl命令行**

命令行：kubectl create configmap

参数如下：

- --from-file:表示基于指定的文件或目录
- --from-env-file：表示基于指定的env文件
- --from-literal：表示参数中指定的“key#=value#“创建为ConfigMap的数据内容

1） --from-file

默认情况下，key名会被设置为文件名，value会被设置为文件的内容

--from-file可以多次出现，用于在一个kubectl create 命令中创建多个ConfigMap

key命名规范：只能包含字段（A-Z和a-z）、数字（0-9）、'-'、'_'、'.'等

2）--from-env-file

env文件包含一组环境变量的配置数据，其内容需遵循如下语法规则

- 第行文件都为VAR=VALUE的格式，行号两边不能有空格
- 忽略以#开头的注释行
- 忽略空行
- 对文本中的引号不做转义处理，即保留原始文本并将其作为value值

支持通过多次使用参数--from-env-file创建一个包含多个源配置文件内容的ConfigMap。

3）--from-literal

### 3.5.3	在Pod中使用ConfigMap

容器应用通过以下两种方式将使用ConfigMap：

- 将ConfigMap的内容设置为容器内的环境变量
- 通过Volume将ConfigMap中的内容挂载为容器内的文件或目录

1）将ConfigMap的内容设置为容器内的环境变量

”envFrom“实现了在Pod环境下将ConfigMap中的所有key:value键值对都自动生成环境变量

2）通过Volume将ConfigMap（适用于Secret）中的内容挂载为容器内的文件或目录

### 3.5.4	ConfigMap的可选设置

在Pod的定义中，可以将对ConfigMap的引用设置为是否可选（optional），若设置主可选（optional=true），则表示如果ConfigMap不存在，或者引用的数据项在ConfigMap中不存在，那么 目标数据将被设置为空值。

当ConfigMap被设置为Volume存储卷时，也ConfigMap的引用设置为是否可选（optional），若设置为可选（optional=true），则表示当ConfigMap不存在时，目标挂载的文件内容是空的。

### 3.5.5	使用ConfigMap时的限制条件

1. ConfigMap必须在Pod之前创建，Pod才能引用它
   1. 如果ConfigMap不存在，或者被Pod引用的key不存在，Pod将无法启动
   2. 如果在Pod的配置中设置引用的ConfigMap为可选的（optional），系统则将正常创建和启动Pod，只是容器内引用ConfigMap的环境的值或挂载文件的内容会被设置为空
2.  如果Pod使用envFrom基于ConfigMap定义环境变量，则无效的环境变量名称（如名称以数字开头）将被忽略，并在事件中被记录为”InvalidVariableNames“。
3. ConfigMap受命名空间限制，只有相同命名空间的Pod才可以引用
4. ConfigMap无法用于静态Pod

## 3.6	在容器内获取Pod信息（Downward API）

Downward API通过以下两种方式将Pod的容器的元数据信息注入容器内：

- 环境变量方式：将Pod或Container的配置信息设置为容器内的环境变量
- Volume挂载方式：将Pod或Container的配置信息以文件的形式挂载到容器内

### 3.6.1	环境变量方式

1.将Pod的配置信息设置为容器内的环境变量

2.将Container的配置信息设置为容器内的环境变量

### 3.6.2	Volume方式

1.将Pod的配置信息以文件的形式挂载到容器内的文件

2.将Container的配置信息以文件的形式挂载到容器内的文件

### 3.6.3 Downward API支持设置的Pod和Container信息

**（1）通过fieldRef设置的字段**

- metadata.name：Pod的名称
- metadata.namespace：Pod所在的命名空间名称
- metadata.uid：Pod的UID
- metadata.labels['<KEY>']：Pod某个Label的值，通过<KEY>引用
- matadata.annotatations['<KEY>']：Pod某个Annotation的值，通过<KEY>引用

**（2）Pod的以下元数据信息可以被设置为容器内的环境变量，但是在设置downwardAPI为存储卷类型时不能再设置fieldRef字段内容**

- spec.serviceAccountName：Pod使用的ServiceAccount名称
- spec.nodeName：Pod所在的Node的名称
- status.hostIP：Pod所在Node的IP地址
- status.hostIPs：Pod所在Node的IPv4和IPv6双栈地址，需要启用特性门PodHostIPs
- status.podIP：Pod的IP地址
- status.podIPs：Pod的IPv4和IPv6双栈地址

**（3）在设置downwardAPI为存储卷类型时，可以在fieldRef字段设置以下信息，但是不能通过环境变量设置**

- metadata.labels：Pod的Label列表，每个Label都以key为文件名，value为文件的内容，每个Label各占一行
- metadata.annotations：Pod的Annotation列表，每个Annotation都以key为文件名，value为文件的内容，每个Annotation各占一行

**（4）可以通过resourceFieldRef设置的字段如下**

- limits.cpu：Container级别的CPU Limit
- requests.cpu：Container级别的CPU Request
- limits.memory：Container级别的Memory Limit
- requests.memory：Container级别的Memory Request
- limits.hugepages-*：Container级别的HugePage（巨页） Limit
- requests.hugepages-*：Container级别的Hugepage Request
- limits.ephemeral-storage：Container级别的临时存储空间Limit
- request.ephemeral-storage：Container级别的临时存储空间Request

**Downward API在volume subPath中的应用：**

当容器内挂载目录的子路径（volumeMounts.subPath）时需要使用Pod或Container的元数据信息，可以将Pod或Container的元数据信息先使用Downward API设置到环境变量上，再通过subPathExpr将其设置为subPath的名称

## 3.7 Pod的生命周期管理

### 3.7.1	Pod的阶段（Phase）

Pod的阶段是对Pod生命周期内所处阶段的简要说明，由**status.phase**字段体现，但并不代表每个容器的状态（Status）

**Pod的各个阶段：**

- **Pending**：创建该Pod的请求已被Master接受，但一个容器或多个容器没有创建也没有运行，包括等待调度和等待下载镜像的过程
- **Running**：Pod已完成调度到特定的Node，其包含的所有容器均已创建，并且至少有一个容器处于正在运行状态、正在启动状态或正在重启状态
- **Succeeded**：Pod内的所有容器均在成功执行后终止，且不会重启
- **Failed**：Pod内的所有容器均已终止，但至少一个容器为退出失败状态，即退出码不是0
- **Unknown**：由于某种原因无法获取Pod的状态，原因可能是从Master到Pod所在Node网络通信失败

在Pod生命周期内的各个阶段，Kubernetes会持续监控其中每个容器的状态，并根据重启策略和健康检查策略进行相应的操作。

在Pod生命周期内，调度操作只会完成一次，只要补系统成功调度到某个Node，Pod就会在其生命周期内一直在这个Node上运行，直到该Pod被终止或删除。当Pod被删除时，通过kubectl命令可以看到Pod的状态为”Terminating“（停止中），但这个状态并不是生命周期内的阶段之一。

除了静态Pod和没有设置Finalizer的Pod（意味着强制删除），kubelet会将已删除的Pod阶段设置为”Succeeded“或”Failed“，然后从Master中删除。

如果Pod所在的Node宕机或者无法与Master进行网络通信，Kuberenetes则将无法访问Node上所有运行Pod的阶段都设置为”failed“。之后一旦Node恢复正常，kubelet就会在指定的超时时间到达后，删除本Node上处于Failed阶段的Pod。

与Pod关联的其它类型资源对象（例如存储卷Volume）可以声明其生命周期与Pod相同，在Pod终止时也会被终止，在重建是也会被重建。

### 3.7.2 Pod的状况（Condition）

#### Pod的状况信息类型

Pod本身的状态信息由一组状况（Condition）信息从多方面体现，可能的状况如下：

- PodScheduled：已将Pod调度到某个Node
- PodReadyToStartContainers：Pod已创建并且完成网络配置，可以启动容器。
- ContainersReady：Pod中的全部容器都达到Ready状态
- Initialized：Pod中的全部初始化容器都成功运行
- Ready：Pod达到Ready状态，可以被加入相应Service的负载均衡后端（Endpoint）列表中

#### Pod的状况信息字段

对于每种类型的状况，Kubernetes都会提供以下字段对其状态和详细信息进行说明：

- type：状况名称，包括上述名称
- status：该状况是否适用，可能的取值包括True、False或Unknown
- lastProbeTime：上一次探测Pod状况的时间戳
- lastTransitionTime：Pod人上一种状态转换到当前状态的时间戳
- reason：上一次状况发生变更的原因，为以驼峰命名格式（UpperCamelCase）表示字符串，用于机器读取
- message：上一次状况发生变化的详细信息，提供给用户读取

#### 状况类型Ready的补充说明

​	支持Pod注入额外的状况类型的信息，以供系统评估Pod是否处于Ready状态。这通常需要先单独开发额外的控制器来设置新的Condition类型，然后在Pod的声明中设置spec.readinessGates加入额外Condition配置，供系统使用，Kubernetes将在status的Condition列表中查找指定的状况类型，如果无法找到，就认为该状况的状态值为”False“。

​	注：新的Condition名称需要符合标签（Label）的键（Key）的命名规范

#### 状况类型PodReadyToStartContainers的补充说明

​	该状况个表示：在Pod完成调度后，kubelet调用容器运行时（CRI）为该Pod创建了运行时沙箱（Sandbox）并完成了网络配置（如通过CNI插件进行网络配置），处于可以启动容器的环境Ready状态，PodReadyToStartContainers的状态会被设置为”True“。之后，kubelet就可以根据容器的配置进行镜像拉取、创建和启动容器的操作了。

​	在Pod生命周期前，kubelete还未开始创建Pod沙箱时，PodReadyToStartContainers的状态被设置为”False“，在Pod生命周期后期，若Node重启时Pod没有被驱逐，或者Pod沙箱被重启后需要重建，则ReadyToStartContainers的状态也会被设置为”False“。

#### 状况类型PodScheduled的补充说明

支持在Pod的spec.schedulingGates中设置一些条件，用于控制何时将Pod设置为可供调度的状态。

在默认情况下，Pod一旦创建，Master的调度器就会无限尝试国它寻找最合适的Node，如果在某种情况下（如Pod一直在等待某种外部资源就绪）很长时间内都无法完成调度，就会浪费调度器的资源 ，从而影响到调度器的工作性能。

SchedulingGates允许声明Pod还未处于可调度状态，Master的调度器在监控到Pod的配置存在一个或多个SchedulingGates时，就不会尝试进行调度了。直到外部控制器清除了Pod的SchedulingGates，调度器才认为该Pod可调度。

在设置了SchedulingGates条件的情况下，新增了如下修改Pod的NodeSelector和NodeAffinity配置的特性（只允许调整为更小的目标调度Node范围，而不能调整为更大的范围），调整规则如下 ：

- spec.nodeSelector：只能增加新的Selector选项，如果之前未设置过，则允许增加该配置
- spec.affinity.nodeAffinity：如果之前未设置，则允许将其设置为任意值
- 如果之前未设置过NodeSelectorTerms字段，则允许新增该字段；如果之前设置过NodeSelectorTerms字段且值不为空，则仅允许在NodeSelectorRequirements的matchExpressions或fieldExpressions中增加表达式，而不能修改matchExpressions或fieldExpressions中已经存在的表达式条件。因为.requiredDuringSchedulingIgnoredDuringExecution.NodeSelectorTerms字段中的多个表达式条件执行的逻辑OR运算，而nodeSelectorTerms[].mathExpressions和nodeSelectorTerms[].fieldExpressions的多个表达式条件执行的是逻辑AND运算。
- .preferredDruingSchedulingIngnoredDuringExecution：允许更新该字段下的全部配置条件，因为调度器不会验证这里的配置条件。

### 3.7.3 容器的状态（State）

​	容器的状态包括以下几种：

- Waiting（等待运行）：Kubernetes在能够运行该容器之前需要执行某些操作，如下载容器镜像、为容器设置存储卷、等待依赖资源 （如ConfigMap或Secret）达到就绪状态，因此系统设置容器的状态为等待运行。
- Running（运行中）：表示容器处于正常的运行过程中，并且没有发生错误。如果容器设置了回调钩子，则可以确认kubelet已对执行了回调方法并且成功完成。
- Terminated（运行结束）：表示容器运行结束，可能是正常结束，也可能是因为失败结束。如果容器设置了preStop回调钩子，kubelet会在容器进入Terminated状态之前执行回调方法。

### 3.7.54Pod的重启策略（RestartPolicy）

#### Pod的重启策略

- Always：当容器失败时，由kubelet自动重启该容器。
- Onfailure：当容器终止运行且退出码不为0时，由kubelet自动重启该容器。
- Never：不认容器处于哪种运行状态，kubelet都不会重启该容器。

#### 控制器对Pod的重启策略要求

- Deployment、RC、DaemonSet和StatefulSet：必须设置为”Always”，需要保证该容器持续运行。
- Job：OnFailure或Never，确保容器执行完成后不再重启。
- kubelet：在静态Pod失败时自动重启它，不论将RestartPolicy设置为何值，也不会对Pod进行健康检查。

#### 常见的阶段转换场景

![image-20260707103225723](%E7%AC%AC3%E7%AB%A0%20%E6%B7%B1%E5%85%A5%E6%8E%8C%E6%8F%A1Pod.assets/image-20260707103225723.png)

### 3.7.5 Pod的终止和垃圾清理

在Pod不再需要运行时通常需要将其优雅的终止，而不是直接使用kill命令强制将其结束。在Kuberenetes中，用户可以为Pod的终止提供preStop回调方法供kubelet调用，也可以设置优雅终止的宽限期，更好的控制容器应用的正常终止。

#### 终止Pod的工作流程

​	kubelet先向容器的主进程发送一个带有宽限期的TERM（SIGTERM）信号；容器运行时异步处理停止容器的请求。在某些容器中如果配置了STOPSIGNAL变量且其值不为“TERM”，kubelet会在先向容器运行时发送STOPSIGNAL变量设置的值。在终止宽限期内，kubelet会等待容器自行退出，如果到期后容器还未退出，容器运行时就向容器内剩余的进程发送KILL信号，直接终止容器，并从控制平台删除该Pod。

​	如果kubelet或容器运行时等管理程序在等待Pod终止的过程中发生了重启，那么从头开始重试，包括完整的宽限期。

#### 终止Pod的工作流详细说明

（1）通过kubectl delete pod <pod_name>命令手动删除一个pod，优雅终止的宽限期默认为30s

（2）控制平台更新Pod的状态，kubelet一旦探测到Pod的状态为“Terminating”，就开始对Pod进行如下终止操作：

- 如果容器配置了preStop回调钩子（命令或脚本），并且配置了非0的终止宽限期（terminationGracePriodSeconds），kubelet就会调用preStop回调钩子。如果preStop回调钩子在终止宽限期之后还未执行完成，kubelet就会给宽限期增加2s。用户需要根据程序的preStop处理时间合理设置终止宽限期的时长。
- 如果容器没有配置preStop，或者终止宽限期已过，kubelet就调用容器运行时给容器的主进程（1号进程）发送TERM信号，也可能发送容器镜像中STOPSIGNAL变量配置的信息

（3）在kubelet启动Pod的优雅终止流程的同时，控制平面会评估是否将正在的终止的Pod从对应服务的后端列表（EndPoint或EndpointSlice）中移除。通常系统不会立刻从后端列表中移除这个Pod，而在后面资源对象上标记其状态为“Terminating”，同时设置Pod的Ready状态为“False”，服务的负载均衡器将不会再给该Pod转发新的请求。（这个机制由EndpoingSliceTerminatingConditon特性门提供。）

（4）在超过了优雅终止期限期之后，kubelet首先会启动强制终止容器进程的操作，通过容器进行时向剩余的进程发送KILL（SIGKILL）信号。kubelet也会删除Pod的基础Pause容器。之后，kubelet先将Pod的阶段设置为“Succeeded”或“Failed”，然后向平面发起删除Pod资源对象的操作，并将宽限期设置为“0”，表示立刻删除。最后控制平台会（从etcd中）彻底删除该Pod资源。

#### 手动强制删除Pod

通过kubectl delete 命令的命令行参数--force和--grace-period=0进行操作。

在发起强制删除的指令之后，控制平台将不再等等kubelet执行终止操作的结果通知，而是直接删除Pod资源对象。

在被控制器管理的情况下，一个新的同名Pod会被立刻创建。在原Pod所在NOde，kubelet仍然会为其设置一个短时间的终止宽限期。

#### Pod的垃圾清理机制

Kubernetes的控制平面提供了一个Pod垃圾清理器PodGC（Garbage Collector），在监控到Pod数量超过阈值（由kube-controller-manager的terminated-pod-gc-threshold参数设置允许存在的最大Pod数量）时，会进行删除已终止的Pod的操作。

 PodGC会清理满足以下条件的Pod：

- 孤儿Pod：已完成调度，但Node不再存在
- 在计划外终止的Pod
- 终止过程中的Pod。如果kube-controller-manager服务启动了NodeOutOfServiceVolumeDetach特性门控，并且一个Node被标记了“node.kubernetes.io/out-of-service”污点（表示无法提供服务），则在该Node上的Pod没有对应的容忍度配置时，系统将强制删除这个Pod，同时清理该Node上的Pod挂载的存储卷。

​	在启用了PodDisruptionConditions特性门控时，Kuberenetes如果要清理Pod，而该Pod处理非终止阶段，PodGC垃圾清理器就会将其阶段标记为“Failed”。此外，PodGC垃圾器在清理孤儿Pod时，会设置名为“DisruptionTarget”的状况（Condition），以说明该Pod是因为发生了某种干扰（Disruption）而被删除，并在reason字段给出终止的原因。

## 3.8 容器的探针和健康检查机制

#### （1）三种探针

1. LivenessProbe探针
2. ReadinessProbe探针
3. StartupProbe探针

#### （2）三种探针的作用

1. LivenessProbe探针：用于判断容器是否存活（Running状态），如果LivenessProbe探针探测到容器不健康，则kubelet将“杀掉”该容器，并根据容器的重启策略做相应的处理。如果容器未设置LivenessProbe探针，那么kubelet认为容器的LivenessProbe探针返回的值永远是Success。
2. ReadinessProbe探针：用于判断容器服务是否处于Ready状态，处于Ready状态的Pod才可以接收请求。对于被Service管理的Pod，Service和Pod Endpoint的关联系统也将基于Pod是否为Ready状态进行设置。如果在运行过程中状态由“Ready”变为“False”，则系统自动将其从Service的后端Endpoint列表中隔离，后续再恢复到Ready状态的Pod加回后端Endpoint列表。ReadinessProbe探针也是定期触发执行的，存在于Pod的整个生命周期内。如果容器未设置ReadinessProbe探针，则kubelet认为该容器的ReadinessProbe探针返回的值永远是“Success”。
3. StartupProbe探针：属于“有且仅有一次”的超长延时，使用StartupProbe不解决。在设置了StartupProbe探针的情况下，LivenessProbe探针和ReadinessProbe探针都将被禁用，直到StartupProbe探针返回成功为止。如果StartupProbe探针探测失败，kubelet将“杀掉”该容器，并根据 容器的重启策略做相应的处理。如果容器未设置StartupProbe探针，kubelet则认为该容器的StartupProbe探针返回的值永远是“Success”

#### 	（3）三种探针的应用场景

1. LivenessProbe探针：容器应该在运行过程中由于存在bug或者主程序进程无法怎么退出，kubelet将借助LivenessProbe探针来判断容器进程是否处于不健康（或僵死）状态。根据配置的条件判断容器处于不健康状态时，将对容器发起重启操作，以实现容器应用的自动恢复。如果希望kubelet在探测失败时自动重启容器，则可以设置Pod的重启策略为Always或OnFailure。如果容器应该能够在遇到严重问题时自动崩溃退出，kubelet则会根据Pod的重启策略重启该容器，无须设置LivenessProbe探针。
2. ReadinessProbe探针：对于提供服务类型的容器应用，若其处于Ready状态时不能接收请求时，则需要为容器应该配置ReadinessProbe探针。容器应该在运行过程中，可能在某段时间无法提供服务（可能是由于性能问题），但是不希望LivenessProbe探测失败，这里可以设置一个与LivenessProbe不同的ReadinessProbe探针，以实现在无法提供时，将Pod从Service的后端列表中暂时移除，不再接收新的请求，等到服务恢复到可以接收请求之后，再恢复到Ready状态，继续接收新的请求。在这个过程可以允许LivenessProbe探针探测成功，容器不会被kubelet杀掉重启
3. StartupProbe探针：对于需要需要较长时间启动的容器，可以设置StartupProbe探针，支持暂时阻止LivenessProbe探针和ReadinessProbe探针的探测，等容器启动成功后，再启动后续的健康检查探测

#### （4）四种探测机制

- exec：在容器内运行指定的 ，如果该命令运行的返回码为0，则说明探测成功
- tcpSocket：通过容器的IP地址和端口号执行TCP检查，如果能够建立TCP连接，则说明探测成功
- httGet：通过容器的IP地址，端口号及路径调用HTTP Get方法，如果响应状态码大于或等于200且小于400，则说明探测成功。
- grpc：通过gRPC执行一个Health Check的远程调用，要求应用程序实现gRPC健康检查协议，如果响应的status为”SERVING“，则说明探测成功。需开启GRPCcontainerProbe特性门控。

#### （5）每种探测方式可配置的字段

- initialDelaySeconds：启动容器后进行首次探测的等待时间，单位为s，默认为0，最小值为0。如果设置periodSeconds的值大于该值，则initialDelaySeconds将被忽略。
- periodSeconds：周期性探测的时间间隔，单位为s，默认值为10，最小值为1。
- timeoutSeconds：发出探测请求后等待结果的超时时间，单位为s。当超时发生时，kubelet认为探测失败。
- successThreshold：探测失败后，判定探测成功的最小连续探测成功的次数，默认为1，最小值为1，LivenessProbe和StartupProbe的这个值必须被测试为1。
- failureThreshold：判定为探测失败的连续探测失败的次数，达到这个数量后，kubelet会认为容器不健康或者服务未就绪，并将基于Pod的重启策略对容器进行重启操作。在杀掉容器前，kubelet会等待terminationGracePeriodSeconds配置的宽限期，若等到该期限时容器仍未能自行结束，才会执行”杀掉“容器的操作。在处于探测失败的状态时，kubelet也会交付Pod的Ready状态设置为“False”
- terminationGracePeriodSeconds：探测失败后，kubelet触发终止容器命令之后等待容器自行结束的宽限期，单位为s，默认值为30，最小值为1。探针级别的terminationGracePeriodSeconds配置不能用于ReadinessProbe探针。

#### （6）HTTP类型探针可配置的额外字段

- host：主机名，默认为Pod的IP地址，可以使用HTTP头的“Host”指定。
- scheme：连接协议，值可以为http或者https，默认为http，对于https，kubelet会跳过证书校验的逻辑。
- path：访问路径，默认为“/”。
- httpHeaders：定义HTTP的头，允许重复。
- port：容器的端口号或者端口名称，数值范围为1~65535.

#### （7）kubelet会设置的两个HTTP头

- User-Agent：默认为“kube-probe/1.35"，其中1.35为kubelet的版本号
- Accept：默认为\*/\*

#### （8）探针探测的三种结果

- Success：探测成功
- Failure：探测失败
- Unknown：探测失败，但是kubelet不会采取任何行动，kubelet将会持续进行后续的探测。

#### （9）探测机制示例

## 3.9	初始化容器

### 3.9.1 初始化容器概述

#### 初始化容器也应用容器的区别

（1）运行方式不同：初始化容器必须先于应用容器运行成功。在设置了多个初始化容器旱，将按顺序逐个运行初始化容器，并且只有前一个初始化容器运行成功，才能运行其之后的一个初始化容器，如果运行失败，则kubelet在默认情况下会不断重启它，直到初始化容器运行成功。但是，如果Pod的重启策略（restartPolicy）补设置为”Never“，则一旦初始化容器运行失败，系统就认为整个Pod运行失败。在所有初始化运行成功后，Kubernetes才会初始化Pod的各种信息，并开始创建和运行应用容器。

（2）对资源限制的设置不同：

- 如果有多个初始化容器定义了资源请求或资源限制，则取最大的值作为所有初始化容器的资源请求值或资源限制值。
- Pod的有效（effective）资源请求值或资源限制值取以下二个中较大值：①所有应用容器的资源请求值或资源限制值之和；②初始化容器的有效资源请求值或资源限制值。
- 调度算法将基于Pod的有效资源请求值或资源限制值进行计算，也就是说，初始化容器可以为初始化操作预留系统资源，即使后续的应用容器无须使用这些资源。
- Pod的有效QoS等级适用于初始化容器和应用容器。
- 资源配额和限制将根据Pod的有效资源请求或资源限制值计算且生效。
- Pod级别的cgroup将基于Pod的有效资源请求或资源限制值，与调度机制一致。

（3）生命周期管理和健康检查机制不同：初始化容器不支持对生命周期（postStart、preStop）及健康检查（LivenessProbe、ReadinessProbe、StartupProbe）进行配置，因为必须在他们成功运行后才能运行在Pod内定义的普通容器。

#### Pod可能重启的场景

- Pod的infrastructure容器（pause）更新
- Pod中的所有应用容器都终止，并且RestartPolicy=Always
- 初始化容器的镜像被更新，则初始化容器将会重新运行。（此场景适用于v1.20及以前版本）

#### 初始化容器的实现原理

Kubernetes通过Pod中的initContainers字段配置初始化容器，以实现在启动应用容器（app container）之前运行初始化容器，并且允许配置一个或多个初始化容器，以完成应用容器所需的预置条件。系统会在Pod的状态信息（Status）的initContainerStatus字段中显示初始化容器的运行状态信息

### 3.9.2 初始化容器示例

1、通过初始化容器为应用容器准备数据

2、通过初始化容器等待应用容器依赖的一个服务处理Ready状态

3、通过初始化容器将Pod作为一个服务实例注册到外部的某个服务注册中心

4、设置两个初始化容器

### 3.9.3 使用初始化容器时的注意事项

- 如果初始化容器运行失败，系统会根据Pod的重启策略进行重启。当restartPolicy为Always时，系统会以”restartPolicy=OnFailure“的逻辑重启初始化容器。
- 在所有初始化容器都成功运行完毕之前，Pod不会进行Ready状态
- 在重启Pod时会重启所有初始化容器
- 在创建之后，如果需要修改初始化容器的定义，则只允许修改image字段，更改镜像名称会触发重启Pod的操作
- Kubernetes在创建Pod时，会强制检查在初始化容器的定义中是否存在readinessProbe，如果存在，则将拒绝创建，因为初始化容器需要运行完毕，不能处于持续运行Ready的状态
- 如果Pod设置了activeDeadlineSeconds，则可以避免初始化容器持续运行失败并且无限重启，需要注意的是，启动时长上限通常应仅适用于Job类型的工作负载，对于长期运行的工作负载（如Deployment）的Pod，超过这个时限也会终止在运行中的正常Pod。
- 在Pod中，每个容器的名称都必须唯一，包括初始化容器的名称。

### 3.9.4 将初始化容器作为长时间运行的边车容器

​	可以将某个初始化容器当作一个长时间运行的边车容器来使用，并且允许为该初始化容器设置独立的重启策略和健康检查探针，这种容器为边车初始化容器。此功能需要开启SidecarContainers特性门控。

​	与常规初始化容器不同的是，在边车初始化容器中，系统只要判定边车初始化容器启动完成（started=true）,就运行后续的其它容器，不会等到边车初始化容器成功运行完毕后再继续。对于配置了startupProbe的边车初始化容器，系统会确保startupProbe成功运行完毕后再继续运行后续的容器。边车初始化容器的重启策略只能被设置为”Always“。

​	边车初始化容器也适用于Job类型的工作负载，不过如果主容器运行结束，Job就运行完成了。边车初始化容器需要设置了"restartPolicy=Always"，但它也会随着Job的运行结束而终止，不会长期运行。
