# **1** ***\*组件\****

## **1.1** ***\*Broker\****

用于producer和consumer接收和发送消息。broker会定时向nameserver提交自己的信息，每个Broker节点，在启动时，都会遍历NameServer列表，与每个NameServer建立长连接，注册自己的信息，之后定时上报。是消息中间件的消息存储、转发服务器。

## **1.2** ***\*Nameserver\****

NameServer是一个非常简单的Topic路由注册中心，其角色类似Dubbo中的zookeeper，支持Broker的动态注册与发现。

主要包括两个功能：Broker管理，NameServer接受Broker集群的注册信息并且保存下来作为路由信息的基本数据。然后提供心跳检测机制，检查Broker是否还存活；路由信息管理，每个NameServer将保存关于Broker集群的整个路由信息和用于客户端查询的队列信息。然后Producer和Conumser通过NameServer就可以知道整个Broker集群的路由信息，从而进行消息的投递和消费。

NameServer通常也是集群的方式部署，各实例间相互不进行信息通讯。Broker是向每一台NameServer注册自己的路由信息，所以每一个NameServer实例上面都保存一份完整的路由信息。当某个NameServer因某种原因下线了，Broker仍然可以向其它NameServer同步其路由信息，Producer,Consumer仍然可以动态感知Broker的路由的信息。

## **1.3** ***\*Producer\****

消息的生产者。随机选择其中一个NameServer节点建立长连接，获得Topic路由信息（包括topic下的queue，这些queue分布在哪些broker上等等），接下来向提供topic服务的master建立长连接（因为rocketmq只有master才能写消息），且定时向master发送心跳。

 

## **1.4** ***\*Consumer\****

消息的消费者。通过NameServer集群获得Topic的路由信息，连接到对应的Broker上消费消息。由于Master和Slave都可以读取消息，因此Consumer会与Master和Slave都建立连接进行消费消息。

## **1.5** ***\*环境服务启动\****

1、启动mq的namesrver服务；

2、启动mq的broker服务；

3、控制台安装，可以查看消息相关内容

 

## **1.6** ***\*整个流程\****

1、启动NameServer，NameServer起来后监听端口，等待Broker、Producer、Consumer连上来，相当于一个路由控制中心。

2、Broker启动，跟所有的NameServer保持长连接，定时发送心跳包。心跳包中包含当前Broker信息(IP+端口等)以及存储所有Topic信息。注册成功后，NameServer集群中就有Topic跟Broker的映射关系。

3、收发消息前，先创建Topic，创建Topic时需要指定该Topic要存储在哪些Broker上，也可以在发送消息时自动创建Topic。

4、Producer发送消息，启动时先跟NameServer集群中的其中一台建立长连接，并从NameServer中获取当前发送的Topic存在哪些Broker上，轮询从队列列表中选择一个队列，然后与队列所在的Broker建立长连接从而向Broker发消息。

5、Consumer跟Producer类似，跟其中一台NameServer建立长连接，获取当前订阅Topic存在哪些Broker上，然后直接跟Broker建立连接通道，开始消费消息。

# **2** ***\*核心概念\****

## **2.1** ***\*Message\****

消息载体。Message发送或者消费的时候必须指定Topic。Message有一个可选的Tag项用于过滤消息，还可以添加额外的键值对。

## **2.2** ***\*topic\****

消息的逻辑分类，发消息之前必须要指定一个topic才能发，就是将这条消息发送到这个topic上。消费消息的时候指定这个topic进行消费。就是逻辑分类。

## **2.3** ***\*queue\****

1个Topic会被分为N个Queue，数量是可配置的。message本身其实是存储到queue上的，消费者消费的也是queue上的消息。多说一嘴，比如1个topic4个queue，有5个Consumer都在消费这个topic，那么会有一个consumer浪费掉了，因为负载均衡策略，每个consumer消费1个queue，5>4，溢出1个，这个会不工作。

## **2.4** ***\*Tag\****

Tag 是 Topic 的进一步细分，顾名思义，标签。每个发送的时候消息都能打tag，消费的时候可以根据tag进行过滤，选择性消费。RocketMQ的消费者可以根据Tag进行消息过滤，也支持自定义属性过滤。消息过滤目前是在Broker端实现的，优点是减少了对于Consumer无用消息的网络传输，缺点是增加了Broker的负担、而且实现相对复杂。

## **2.5** ***\*Message Model\****

消息模型：集群（Clustering）和广播（Broadcasting）

## **2.6** ***\*Message Order\****

消息顺序：顺序（Orderly）和并发（Concurrently）

## **2.7** ***\*Producer Group\****

消息生产者组。

group含义：代表具有相同角色的生产者组合或消费者组合，称为生产者组或消费者组。

如果不指定，就会使用默认的名字：DEFAULT_PRODUCER。作用是在集群HA的情况下，一个生产者down之后，本地事务回滚后，可以继续联系该组下的另外一个生产者实例，不至于导致业务走不下去。在消费者组中，可以实现消息消费的负载均衡和消息容错目标。

## **2.8** ***\*Consumer Group\****

消息消费者组。

消费组可以消费不同生产组生产的同一topic的消息。

## **2.9** ***\*ACK\****

ACK机制是发生在Consumer端的，不是在Producer端的。也就是说Consumer消费完消息后要进行ACK确认，如果未确认则代表是消费失败，这时候Broker会进行重试策略（仅集群模式会重试）。ACK的意思就是：Consumer说：ok，我消费成功了。这条消息给我标记成已消费吧。

# **3** ***\*消费模式\****

## **3.1** ***\*消费模式\****

### **3.1.1** ***\*集群模式（Clustering）\****

每条消息只需要被处理一次，broker只会把消息发送给 消费集群中 的一个消费者（不是满足条件的topic的一个消费者，是某个消费集群中的一个消费者）；

在消息重投时，不能保证路由到同一台机器上；

消费状态由broker维护；

默认就是集群模式；

### **3.1.2** ***\*广播模式（Broadcasting）\****

消费进度由consumer维护。

保证每个消费者都消费一次消息。

消费失败的消息不会重投。

consumer.setMessageModel(MessageModel.BROADCASTING); 

 

## **3.2** ***\*消费方式\****

### **3.2.1** ***\*拉取式消费\****

Consumer消费的一种类型，应用通常主动调用Consumer的拉消息方法从Broker服务器拉消息、主动权由应用控制。一旦获取了批量消息，应用就会启动消费过程。

### **3.2.2** ***\*推动式消费\****

Consumer消费的一种类型，该模式下Broker收到数据后会主动推送给消费端，该消费模式一般实时性较高。

## **3.3** ***\*消息发送模式\****

### **3.3.1** ***\*send（同步）\****

//同步获取到结果

 SendResult result = producer.send(msg);

### **3.3.2** ***\*send（批量）\****

 // 批量发送的api的也是send()，只是他的重载方法支持List<Message>，同样是同步发送。

 SendResult result = producer.send(msgs);

### **3.3.3** ***\*sendCallBack（异步）\****

 producer.send(msg, new SendCallback() {

​      // 发送成功的回调接口

​      @Override

​      public void onSuccess(SendResult sendResult) {

​        System.out.println("发送消息成功！result is : " + sendResult);

​      }

​      // 发送失败的回调接口

​      @Override

​      public void onException(Throwable throwable) {

​        throwable.printStackTrace();

​        System.out.println("发送消息失败！result is : " + throwable.getMessage());

​      }

​    });

### **3.3.4** ***\*sendOneway\****

 // 效率最高，因为oneway不关心是否发送成功，我就投递一下我就不管了。所以返回是void

producer.sendOneway(msg);

### **3.3.5** ***\*效率对比\****

sendOneway > sendCallBack > send批量 > send单条

 

# **4** ***\*Java API\****

## **4.1** ***\*Producer\****

发消息肯定要必备如下几个条件：

指定生产组名（不能用默认的，会报错）

配置namesrv地址（必须）

指定topic name（必须）

指定tag/key（可选）

 

验证消息是否发送成功：消息发送完后可以启动消费者进行消费，也可以去管控台上看消息是否存在。

消息可以发同步的，也可以发异步的消息（异步的有sendCallBack回调方法，然后onSuccess/onException方法），还有单向发送的无须关注结果的方法（producer.sendOneway(msg)）。

## **4.2** ***\*Consumer\****

发消息肯定要必备如下几个条件：

指定消费组名（不能用默认的，会报错）

配置namesrv地址（必须）

指定topic name（必须）

指定tag/key（可选）

每个consumer只能关注一个topic。

## **4.3** ***\*TAG&&KEY\****

发送/消费 消息的时候可以指定tag/key来进行过滤消息，支持通配符。*代表消费此topic下的全部消息，不进行过滤。

# **5** ***\*事务消息\****

## **5.1** ***\*案例\****

 

小明购买一个100元的东西，账户扣款100元的同时需要保证在下游的积分系统给小明这个账号增加100积分。账号系统（accountService）和积分系统（memberService）是两个独立是系统，一个要减少100元，一个要增加100积分。

问题：

1、账号服务扣款成功了，通知积分系统也成功了，但是积分增加的时候失败了，数据不一致了。

2、账号服务扣款成功了，但是通知积分系统失败了，所以积分不会增加，数据不一致了。

## **5.2** ***\*方案及原理\****

### **5.2.1** ***\*方案\****

问题1 解决方案：如果消费失败了，是会自动重试的，如果重试几次后还是消费失败，那么这种情况就需要人工解决了，比如放到死信队列里然后手动查原因进行处理等。

问题2 解决方案：如果你扣款成功了，但是往mq写消息的时候失败了，那么RocketMQ会进行回滚消息的操作，这时候我们也能回滚我们扣款的操作。

### **5.2.2** ***\*原理过程\****

step1、Producer发送半消息（Half Message）到broker。（其实这就是prepare message，预发送消息）

Half Message发送成功后开始执行本地事务。

如果本地事务执行成功的话则返回commit，如果执行失败则返回rollback。（这个是在事务消息的回调方法里由开发者自己决定commit or rollback）

 

step2、Producer发送上一步的commit还是rollback到broker，broke进行处理

a、如果broker收到了commit/rollback消息 ：

如果收到了commit，则broker认为整个事务是没问题的，执行成功的。那么会下发消息给Consumer端消费。

如果收到了rollback，则broker认为本地事务执行失败了，broker将会删除Half Message，不下发给Consumer端。

b、如果broker未收到消息（如果执行本地事务突然宕机了，相当本地事务执行结果返回unknow，则和broker未收到确认消息的情况一样处理）;

broker会定时回查本地事务的执行结果：如果回查结果是本地事务已经执行则返回commit，若未执行，则返回rollback。

Producer端回查的结果发送给Broker。Broker接收到的如果是commit，则broker视为整个事务执行成功，如果是rollback，则broker视为本地事务执行失败，broker删除Half Message，不下发给consumer。如果broker未接收到回查的结果（或者查到的是unknow），则broker会定时进行重复回查，以确保查到最终的事务结果。重复回查的时间间隔和次数都可配。

### **5.2.3** ***\*实现\****

实现流程：

正常情况：事务消息是个监听器，有回调函数，回调函数里我们进行业务逻辑的操作，比如给账户-100元，然后发消息到积分的mq里，这时候如果账户-100成功了，且发送到mq成功了，则设置消息状态为commit，这时候broker会将这个半消息发送到真正的topic中。一开始发送他是存到半消息队列里的，并没存在真实topic的队列里。只有确认commit后才会转移。

补救方案：如果事务因为中断，或是其他的网络原因，导致无法立即响应的，RocketMQ当做UNKNOW处理，RocketMQ事务消息还提供了一个补救方案：定时查询事务消息的事务状态。这也是一个回调函数，这里面可以做补偿，补偿逻辑开发者自己写，成功的话自己返回commit就完事了。

### **5.2.4** ***\*相关类\****

TransactionMQProducer ： 创建事务性生产者，返回如下三种状态

TransactionStatus.CommitTransaction: 提交事务，它允许消费者消费此消息。

TransactionStatus.RollbackTransaction: 回滚事务，它代表该消息将被删除，不允许被消费。

TransactionStatus.Unknown: 中间状态，它代表需要检查消息队列来确定状态。

TransactionListener ：实现事务的监听接口

### **5.2.5** ***\*代码\****

public class ProducerTransaction2 {

 

  public static void main(String[] args) throws Exception {

​    TransactionMQProducer producer = new TransactionMQProducer("my-transaction-producer");

​    producer.setNamesrvAddr("127.0.0.1:9876");

 

​    // 回调

​    producer.setTransactionListener(new TransactionListener() {

​      @Override

​      public LocalTransactionState executeLocalTransaction(Message message, Object arg) {

​        System.out.println("执行方法 executeLocalTransaction");

​        LocalTransactionState state = null;

​        //msg-1返回COMMIT_MESSAGE

​        if (message.getKeys().equals("msg-1")) {

​          state = LocalTransactionState.COMMIT_MESSAGE;

​        }

​        //msg-5返回ROLLBACK_MESSAGE

​        else if (message.getKeys().equals("msg-2")) {

​          state = LocalTransactionState.ROLLBACK_MESSAGE;

​        } else {

​          //这里返回unknown的目的是模拟执行本地事务突然宕机的情况（或者本地执行成功发送确认消息失败的场景）

​          state = LocalTransactionState.UNKNOW;

​        }

​        System.out.println(message.getKeys() + ",state:" + state);

​        return state;

​      }

 

​      /**

​       \* 事务消息的回查方法

​       */

​      @Override

​      public LocalTransactionState checkLocalTransaction(MessageExt messageExt) {

​        System.out.println("执行方法checkLocalTransaction");

​        if (null != messageExt.getKeys()) {

​          switch (messageExt.getKeys()) {

​            case "msg-3":

​              System.out.println("msg-3 unknow");

​              return LocalTransactionState.UNKNOW;

​            case "msg-4":

​              System.out.println("msg-4 COMMIT_MESSAGE");

​              return LocalTransactionState.COMMIT_MESSAGE;

​            case "msg-5":

​              //查询到本地事务执行失败，需要回滚消息。

​              System.out.println("msg-5 ROLLBACK_MESSAGE");

​              return LocalTransactionState.ROLLBACK_MESSAGE;

​          }

​        }

​        return LocalTransactionState.COMMIT_MESSAGE;

​      }

​    });

 

​    producer.start();

 

​    //模拟发送5条消息

​    for (int i = 1; i < 6; i++) {

​      try {

​        Message msg = new Message("transactionTopic", null, "msg-" + i, ("测试，这是事务消息！ " + i).getBytes());

​        System.out.println("发送消息开始：-----------" + i);

​        producer.sendMessageInTransaction(msg, null);

​        System.out.println("发送消息结束：-----------" + i);

​      } catch (Exception e) {

​        e.printStackTrace();

​      }

​    }

  }

 

}

输出内容为：

 

发送消息开始：-----------1

执行方法 executeLocalTransaction

msg-1,state:COMMIT_MESSAGE

发送消息结束：-----------1

发送消息开始：-----------2

执行方法 executeLocalTransaction

msg-2,state:ROLLBACK_MESSAGE

发送消息结束：-----------2

发送消息开始：-----------3

执行方法 executeLocalTransaction

msg-3,state:UNKNOW

发送消息结束：-----------3

发送消息开始：-----------4

执行方法 executeLocalTransaction

msg-4,state:UNKNOW

发送消息结束：-----------4

发送消息开始：-----------5

执行方法 executeLocalTransaction

msg-5,state:UNKNOW

发送消息结束：-----------5

执行方法checkLocalTransaction

msg-5 ROLLBACK_MESSAGE

执行方法checkLocalTransaction

msg-4 COMMIT_MESSAGE

执行方法checkLocalTransaction

msg-3 unknow

总结：先发消息，然后执行executeLocalTransaction回掉，再执行checkLocalTransaction回查；

# **6** ***\*顺序消息\****

## **6.1** ***\*问题\****

 

RocketMQ的消息是存储到Topic的queue里面的，queue本身是FIFO（First Int First Out）先进先出队列。所以单个queue是可以保证有序性的。

 

但问题是1个topic有N个queue，作者这么设计的好处也很明显，天然支持集群和负载均衡的特性，将海量数据均匀分配到各个queue上，你发了10条消息到同一个topic上，这10条消息会自动分散在topic下的所有queue中，所以消费的时候不一定是先消费哪个queue，后消费哪个queue，这就导致了无序消费。

 

## **6.2** ***\*解决方案\****

### **6.2.1** ***\*方案一\****

问题产生的关键在于多个队列都有消息，我消费的时候又不知道哪个队列的消息是最新的。那么思路就有了，发消息的时候你要想保证有序性的话，就都给我发到一个queue上，然后消费的时候因为只有那一个queue上有消息且queue是FIFO，先进先出，所以正常消费就完了。

 

api:MessageQueueSelector

 

producer.send(

​          // 要发的那条消息

​          message,

​          // queue 选择器 ，向 topic中的哪个queue去写消息

​          new MessageQueueSelector() {

​            // 手动 选择一个queue

​            @Override

​            public MessageQueue select(

​                // 当前topic 里面包含的所有queue

​                List<MessageQueue> mqs, 

​                // 具体要发的那条消息

​                Message msg,

​                // 对应到 send（） 里的 args，也就是2000前面的那个0

​                // 实际业务中可以把0换成实际业务系统的主键，比如订单号啥的，然后这里做hash进行选择queue等。能做的事情很多，我这里做演示就用第一个queue，所以不用arg。

​                Object arg) {

​              // 向固定的一个queue里写消息，比如这里就是向第一个queue里写消息

​              MessageQueue queue = mqs.get(0);

​              // 选好的queue

​              return queue;

​            }

​          },

​          // 自定义参数：0

​          // 2000代表2000毫秒超时时间

​          0, 2000);

​    }

方案二

 

比如你新需求：把未支付的订单都放到queue1里，已支付的订单都放到queue2里，支付异常的订单都放到queue3里，然后你消费的时候要保证每个queue是有序的，不能消费queue1一条直接跑到queue2去了，要逐个queue去消费。

 

这时候思路是发消息的时候利用自定义参数arg，消息体里肯定包含支付状态，判断是未支付的则选择queue1，以此类推。这样就保证了每个queue里只包含同等状态的消息。那么消费者目前是多线程消费的，肯定乱序。三个queue随机消费。解决方案更简单，直接将消费端的线程数改为1个，这样队列是FIFO，他就逐个消费了。RocketMQ也为我们提供了这样的api，如下两句

 

// 最大线程数1

consumer.setConsumeThreadMax(1);

// 最小线程数

consumer.setConsumeThreadMin(1);

# **7** ***\*怎么保证的消息不丢失\****

## **7.1** ***\*概叙\****

1、我们将消息流程分为如下三大部分，每一部分都有可能会丢失数据。

生产阶段：Producer通过网络将消息发送给Broker，这个发送可能会发生丢失，比如网络延迟不可达等。

存储阶段：Broker肯定是先把消息放到内存的，然后根据刷盘策略持久化到硬盘中，刚收到Producer的消息，再内存中了，但是异常宕机了，导致消息丢失。

消费阶段：消费失败了其实也是消息丢失的一种变体吧。

## **7.2** ***\*Producer生产阶段\****

Producer通过网络将消息发送给Broker，这个发送可能会发生丢失，比如网络延迟不可达等。

### **7.2.1** ***\*解决方案1\****

 

有三种send方法，同步发送、异步发送、单向发送。我们可以采取同步发送的方式进行发送消息，发消息的时候会同步阻塞等待broker返回的结果，如果没成功，则不会收到SendResult，这种是最可靠的。其次是异步发送，再回调方法里可以得知是否发送成功。单向发送（OneWay）是最不靠谱的一种发送方式，我们无法保证消息真正可达。

 

// 同步发送

public SendResult send(Message msg) throws MQClientException, RemotingException,    MQBrokerException, InterruptedException {}

// 异步发送，sendCallback作为回调

public void send(Message msg,SendCallback sendCallback) throws MQClientException, RemotingException, InterruptedException {}

// 单向发送，不关心发送结果，最不靠谱

public void sendOneway(Message msg) throws MQClientException, RemotingException, InterruptedException {}

### **7.2.2** ***\*解决方案2\****

发送消息如果失败或者超时了，则会自动重试。默认是重试三次，可以根据api进行更改，比如改为10次：

 

producer.setRetryTimesWhenSendFailed(10);

### **7.2.3** ***\*解决方案3\****

假设Broker宕机了，但是生产环境一般都是多M多S的，所以还会有其他master节点继续提供服务，这也不会影响到我们发送消息，我们消息依然可达。因为比如恰巧发送到broker的时候，broker宕机了，producer收到broker的响应发送失败了，这时候producer会自动重试，这时候宕机的broker就被踢下线了， 所以producer会换一台broker发送消息。

 

### **7.2.4** ***\*总结\****

Producer怎么保证发送阶段消息可达？

失败会自动重试，即使重试N次也不行后，那客户端也会知道消息没成功，这也可以自己补偿等，不会盲目影响到主业务逻辑。再比如即使Broker挂了，那还有其他Broker再提供服务了，高可用，不影响。

总结为几个字就是：同步发送+自动重试机制+多个Master节点；

## **7.3** ***\*roker存储阶段\****

 

Broker肯定是先把消息放到内存的，然后根据刷盘策略持久化到硬盘中，刚收到Producer的消息，再内存中了，但是异常宕机了，导致消息丢失。

### **7.3.1** ***\*解决方案一\****

MQ持久化消息分为两种：同步刷盘和异步刷盘。

默认情况是异步刷盘，Broker收到消息后会先存到cache里然后立马通知Producer说消息我收到且存储成功了，你可以继续你的业务逻辑了，然后Broker起个线程异步的去持久化到磁盘中，但是Broker还没持久化到磁盘就宕机的话，消息就丢失了。

同步刷盘的话是收到消息存到cache后并不会通知Producer说消息已经ok了，而是会等到持久化到磁盘中后才会通知Producer说消息完事了。这也保障了消息不会丢失，但是性能不如异步高。看业务场景取舍。

修改刷盘策略为同步刷盘。默认情况下是异步刷盘的，如下配置

\## 默认情况为 ASYNC_FLUSH，修改为同步刷盘：SYNC_FLUSH，实际场景看业务，同步刷盘效率肯定不如异步刷盘高。

flushDiskType = SYNC_FLUSH 

### **7.3.2** ***\*解决方案二\****

集群部署，主从模式，高可用。

即使Broker设置了同步刷盘策略，但是Broker刷完盘后磁盘坏了，这会导致盘上的消息全TM丢了。但是如果即使是1主1从了，但是Master刷完盘后还没来得及同步给Slave就磁盘坏了，不也是GG吗？没错！

所以我们还可以配置不仅是等Master刷完盘就通知Producer，而是等Master和Slave都刷完盘后才去通知Producer说消息ok了。

\## 默认为 ASYNC_MASTER

brokerRole=SYNC_MASTER

### **7.3.3** ***\*总结\****

若想很严格的保证Broker存储消息阶段消息不丢失，则需要如下配置，但是性能肯定远差于默认配置。

\# master 节点配置

flushDiskType = SYNC_FLUSH

brokerRole=SYNC_MASTER

\# slave 节点配置

brokerRole=slave

flushDiskType = SYNC_FLUSH

 

上面这个配置含义是：

Producer发消息到Broker后，Broker的Master节点先持久化到磁盘中，然后同步数据给Slave节点，Slave节点同步完且落盘完成后才会返回给Producer说消息ok了。

 

## **7.4** ***\*Consumer消费阶段\****

消费失败了其实也是消息丢失的一种变体。

### **7.4.1** ***\*解决方案一\****

消费者会先把消息拉取到本地，然后进行业务逻辑，业务逻辑完成后手动进行ack确认，这时候才会真正的代表消费完成。而不是说pull到本地后消息就算消费完了。

 

consumer.registerMessageListener(new MessageListenerConcurrently() {

   @Override

   public ConsumeConcurrentlyStatus consumeMessage(List<MessageExt> msgs, ConsumeConcurrentlyContext consumeConcurrentlyContext) {

​     for (MessageExt msg : msgs) {

​       String str = new String(msg.getBody());

​       System.out.println(str);

​     }

​     // ack，只有等上面一系列逻辑都处理完后，到这步CONSUME_SUCCESS才会通知broker说消息消费完成，如果上面发生异常没有走到这步ack，则消息还是未消费状态。而不是像比如redis的blpop，弹出一个数据后数据就从redis里消失了，并没有等我们业务逻辑执行完才弹出。

​     return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;

   }

 });

### **7.4.2** ***\*解决方案二\****

消息消费失败自动重试。如果消费消息失败了，没有进行ack确认，则会自动重试，重试策略和次数（默认15次）；

 

# **8** ***\*RocketMQ是如何发消息\****

1、首先需要配置好生产者组名、namesrv地址和topic以及要发送的消息内容，然后启动Producer的start()方法，启动完成后调用send()方法进行发送。

2、start()方法内部会进行检查namesrv、生产者组名等参数验证，然后内部会获取一个mQClientFactory对象，此对象内包含了所有与Broker进行通信的api，然后通过mQClientFactory启动请求响应通道，主要是netty，接下来启动一些定时任务，比如与broker的心跳等，还会启动负载均衡服务等，最后都启动成功的话将服务的状态标记为RUNNING。

3、启动完成后调用send()方法发消息，有三种发送方式，同步、异步、oneWay，都大同小异，唯一的区别的就是异步的多个线程池去异步调用发送请求，而同步则是当前请求线程直接同步调用的，核心流程都是：先选择一个合适的queue来存储消息，选择完后拼凑一个header参数对象，通过netty的形式发送给broker。

这里值得注意的是：如果发送失败的话他会自动重试，默认同步发送的次数是3次，也就是失败后会自动重试2次。

# **9** ***\*Broker收到消息后如何持久化\****

有两种方式：同步和异步。一般选择异步，同步效率低，但是更可靠。

消息存储大致原理是：

核心类MappedFile对应的是每个commitlog文件，MappedFileQueue相当于文件夹，管理所有的文件，还有一个管理者CommitLog对象，他负责提供一些操作。具体的是Broker端拿到消息后先将消息、topic、queue等内容存到ByteBuffer里，然后去持久化到commitlog文件中。commitlog文件大小为1G，超出大小会新创建commitlog文件来存储。

# **10** ***\*发消息的时候选择queue的算法有哪些\****

分为两种，一种是直接发消息，client内部有选择queue的算法，不允许外界改变。还有一种是可以自定义queue的选择算法（内置了三种算法，不喜欢的话可以自定义算法实现）。

 

有时候我们不希望默认的queue选择算法，而是需要自定义，一般最常用的场景在顺序消息，顺序消息的发送一般都会指定某组特征的消息都发当同一个queue里，这样才能保证顺序，因为单queue是有序的。

### **10.0.1** ***\*send(msg,queue)\****

内置了三种算法，三种算法都实现了一个共同的接口，很典型的策略模式，不同算法不同实现类，有个顶层接口。要想自定义逻辑的话，直接实现接口重写select方法即可：

 

org.apache.rocketmq.client.producer.MessageQueueSelector

SelectMessageQueueByRandom

SelectMessageQueueByHash

SelectMessageQueueByMachineRoom

### **10.0.2** ***\*send(msg)\****

在不开启容错的情况下，轮询队列进行发送，如果失败了，重试的时候过滤失败的Broker

如果开启了容错策略，会通过RocketMQ的预测机制来预测一个Broker是否可用

如果上次失败的Broker可用那么还是会选择该Broker的队列

如果上述情况失败，则随机选择一个进行发送

在发送消息的时候会记录一下调用的时间与是否报错，根据该时间去预测broker的可用时间

### **10.0.3** ***\*发消息的时候选择queue的算法有哪些\****

分为两种，一种是直接发消息，不能选择queue，这种的queue选择算法如下：

在不开启容错的情况下，轮询队列进行发送，如果失败了，重试的时候过滤失败的Broker

如果开启了容错策略，会通过RocketMQ的预测机制来预测一个Broker是否可用

如果上次失败的Broker可用那么还是会选择该Broker的队列

如果上述情况失败，则随机选择一个进行发送

在发送消息的时候会记录一下调用的时间与是否报错，根据该时间去预测broker的可用时间

另外一种是发消息的时候可以选择算法甚至还可以实现接口自定义算法。

# **11** ***\*举例说明消息队列应用场景及ActiveMQ、RocketMQ、Kafka等的对比\****

1、异步处理

2、应用解耦

3、流量削峰

4、消息通讯

RocketMQ支持事务，Kafka不支持事务；

 

# **12** ***\*消息积压\****

## **12.1** ***\*思考消息积压的的原因和现象\****

1、是什么导致了消息积压？是consumer程序bug？是consumer消费的速度落后于消息生产的速度？

2、积压了多长时间，积压了多少量？

3、对业务的影响？

## **12.2** ***\*解决方法\****

a、consumer消费的速度落后于消息生产的速度的话

解决方法：可以考虑采用扩容消费者群组的方式。

b、 如果积压比较严重，积压了上百万、上千万的消息。

解决方法：

1、修复现有consumer的问题，并将其停掉。

2、重新创建一个容量更大的topic，比如patition是原来的10倍。

3、编写一个临时consumer程序，消费原来积压的队列。该consumer不做任何耗时的操作，将消息均匀写入新创建的队列里。

4、将修复好的consumer部署到原来10倍的机器上消费新队列。

5、消息积压解决后，恢复原有架构。