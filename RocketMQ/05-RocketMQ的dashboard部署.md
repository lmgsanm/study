# java环境部署

## 软件安装

tar xzf jdk-17.0.17_linux-x64_bin.tar.gz -C /usr/local/

ln -s /usr/local/jdk-17.0.17 /usr/local/java

## 环境变量配置

```
export JAVA_HOME=/usr/local/java
export CLASSPATH=.:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar
export PATH=$JAVA_HOME/bin:$PATH
```

## 加载环境变量

source /etc/profile

# maven部署

```
tar xzf apache-maven-3.9.11-bin.tar.gz -C /usr/local/
ln -s /usr/local/apache-maven-3.9.11/ /usr/local/maven
#添加maven环境变量，
cat << EOF >> /etc/profile
export MAVEN_HOME=/usr/local/maven
export PATH=\$MAVEN_HOME/bin:\$PATH
EOF
mvn -v
```



# git安装

```
yum -y install git
```

# dashboard编译

## 源码下载

```
git clone https://github.com/apache/rocketmq-dashboard.git
```

## 源码编译

```
cd rocketmq-dashboard/
mvn clean package -Dmaven.test.skip=true

```

![image-20251030202855983](D:\lmgsanm\03-个人总结\03-中间件\RocketMQ\image-20251030202855983.png)



编译后jar包为：rocketmq-dashboard-2.1.1-SNAPSHOT.jar

# dashboard安装

scp rocketmq-dashboard-2.1.1-SNAPSHOT.jar 192.168.1.14:/root/soft/

[root@broker-b-s ~]# mkdir -p /mid/rocketmq/rocketmq-dashboard

[root@broker-b-s ~]# cp /root/soft/rocketmq-dashboard-2.1.1-SNAPSHOT.jar /mid/rocketmq/rocketmq-dashboard

# dashboard配置

[root@broker-b-s ~]# mkdir -p /mid/rocketmq/rocketmq-dashboard/data

[root@broker-b-s ~]# cd /mid/rocketmq/rocketmq-dashboard

## application.yml

[root@broker-b-s rocketmq-dashboard]# cat application.yml

```yaml
server:
  port: 8082
  servlet:
    encoding:
      charset: UTF-8
      enabled: true
      force: true
spring:
  application:
    name: rocketmq-dashboard

  security:
    user:
      name: rocketmq
      password: 1234567
      roles: ADMIN

management:
  endpoints:
    web:
      exposure:
        include: "*"

logging:
  config: classpath:logback.xml

rocketmq:
  config:
    namesrvAddrs:
      - node01:9876;node02:9876;node03:9876
    dataPath: /mid/rocketmq/rocketmq-dashboard/data
    enableDashBoardCollect: true
    msgTrackTopicName:
    ticketKey: ticket
    loginRequired: false
threadpool:
  config:
    coreSize: 10
    maxSize: 10
    keepAliveTime: 3000
    queueSize: 5000

```

##  logback.xml

[root@broker-b-s rocketmq-dashboard]# cat logback.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!--
  ~ Licensed to the Apache Software Foundation (ASF) under one or more
  ~ contributor license agreements.  See the NOTICE file distributed with
  ~ this work for additional information regarding copyright ownership.
  ~ The ASF licenses this file to You under the Apache License, Version 2.0
  ~ (the "License"); you may not use this file except in compliance with
  ~ the License.  You may obtain a copy of the License at
  ~
  ~     http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS,
  ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  ~ See the License for the specific language governing permissions and
  ~ limitations under the License.
  -->

<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder charset="UTF-8">
            <pattern>[%d{yyyy-MM-dd HH:mm:ss.SSS}] %p %t - %m%n</pattern>
        </encoder>
    </appender>

    <appender name="FILE"
              class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${user.home}/logs/dashboardlogs/rocketmq-dashboard.log</file>
        <append>true</append>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${user.home}/logs/dashboardlogs/rocketmq-dashboard-%d{yyyy-MM-dd}.%i.log
            </fileNamePattern>
            <timeBasedFileNamingAndTriggeringPolicy
                    class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>104857600</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
            <MaxHistory>10</MaxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>[%d{yyyy-MM-dd HH:mm:ss.SSS}] %p %t - %m%n</pattern>
            <charset class="java.nio.charset.Charset">UTF-8</charset>
        </encoder>
    </appender>

    <root level="INFO">
        <appender-ref ref="STDOUT"/>
        <appender-ref ref="FILE"/>
    </root>

</configuration>

```

## users.properties

[root@broker-b-s rocketmq-dashboard]# cat users.properties

```shell
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# This file supports hot change, any change will be auto-reloaded without Dashboard restarting.
# Format: a user per line, username=password[,N] #N is optional, 0 (Normal User); 1 (Admin)
# Define Admin
super=admin,1
# Define Users
user1=user
user2=user

```



# dashboard启动



[root@broker-b-s rocketmq-dashboard]#  nohup jdk-17.0.17/bin/java  -jar rocketmq-dashboard-2.1.1-SNAPSHOT.jar &

[root@broker-b-s rocketmq-dashboard]# tail nohup.out

```
        at org.apache.rocketmq.dashboard.service.ClusterInfoService.refresh(ClusterInfoService.java:60)
        at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:539)
        at java.base/java.util.concurrent.FutureTask.runAndReset(FutureTask.java:305)
        at java.base/java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:305)
        at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1136)
        at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:635)
        at java.base/java.lang.Thread.run(Thread.java:842)
[2025-10-30 08:56:11.342] INFO main - Starting ProtocolHandler ["http-nio-8082"]
[2025-10-30 08:56:11.388] INFO main - Tomcat started on port 8082 (http) with context path '/'
[2025-10-30 08:56:11.453] INFO main - Started App in 16.795 seconds (process running for 19.205)
```

[root@broker-b-s rocketmq-dashboard]# ps aux | grep dashboard | grep java | grep -v color

```
root        1259 73.6 12.4 3017960 225712 pts/0  Sl   08:55   0:39 jdk-17.0.17/bin/java -jar rocketmq-dashboard-2.1.1-SNAPSHOT.jar
```

[root@broker-b-s rocketmq-dashboard]# netstat -tupnl | grep 1259

```
tcp6       0      0 :::8082                 :::*                    LISTEN      1259/jdk-17.0.17/bi
```

# dashboard访问

## 访问地址

http://192.168.1.14:8082/

![image-20251103202115154](D:\lmgsanm\03-个人总结\03-中间件\RocketMQ\image-20251103202115154.png)



# 问题处理



## 问题一现象

### BUILD FAILURE

```
main:
     [copy] Copying 12 files to /root/rocketmq-dashboard/target/classes/public
[INFO] Executed tasks
[INFO]
[INFO] --- resources:2.7:resources (default-resources) @ rocketmq-dashboard ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] Copying 5 resources
[INFO] Copying 3 resources
[INFO]
[INFO] --- compiler:3.11.0:compile (default-compile) @ rocketmq-dashboard ---
[INFO] Changes detected - recompiling the module! :source
[INFO] Compiling 137 source files with javac [debug deprecation target 17] to target/classes
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  04:02 min
[INFO] Finished at: 2025-10-30T00:23:19-04:00
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.11.0:compile (default-compile) on project rocketmq-dashboard: Fatal error compiling: invalid target release: 17 -> [Help 1]
[ERROR]
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR]
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException

```

### 报错2

![image-20251030125320888](D:\lmgsanm\03-个人总结\03-中间件\RocketMQ\image-20251030125320888.png)



```
[INFO] --- compiler:3.11.0:compile (default-compile) @ rocketmq-dashboard ---
[INFO] Changes detected - recompiling the module! :source
[INFO] Compiling 137 source files with javac [debug deprecation target 18] to target/classes
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  03:42 min
[INFO] Finished at: 2025-10-30T00:51:08-04:00
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.11.0:compile (default-compile) on project rocketmq-dashboard: Fatal error compiling: invalid target release: 18 -> [Help 1]
org.apache.maven.lifecycle.LifecycleExecutionException: Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.11.0:compile (default-compile) on project rocketmq-dashboard: Fatal error compiling
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute2 (MojoExecutor.java:333)
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute (MojoExecutor.java:316)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:212)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:174)
    at org.apache.maven.lifecycle.internal.MojoExecutor.access$000 (MojoExecutor.java:75)
    at org.apache.maven.lifecycle.internal.MojoExecutor$1.run (MojoExecutor.java:162)
    at org.apache.maven.plugin.DefaultMojosExecutionStrategy.execute (DefaultMojosExecutionStrategy.java:39)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:159)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:105)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:73)
    at org.apache.maven.lifecycle.internal.builder.singlethreaded.SingleThreadedBuilder.build (SingleThreadedBuilder.java:53)
    at org.apache.maven.lifecycle.internal.LifecycleStarter.execute (LifecycleStarter.java:118)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:261)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:173)
    at org.apache.maven.DefaultMaven.execute (DefaultMaven.java:101)
    at org.apache.maven.cli.MavenCli.execute (MavenCli.java:906)
    at org.apache.maven.cli.MavenCli.doMain (MavenCli.java:283)
    at org.apache.maven.cli.MavenCli.main (MavenCli.java:206)
    at sun.reflect.NativeMethodAccessorImpl.invoke0 (Native Method)
    at sun.reflect.NativeMethodAccessorImpl.invoke (NativeMethodAccessorImpl.java:62)
    at sun.reflect.DelegatingMethodAccessorImpl.invoke (DelegatingMethodAccessorImpl.java:43)
    at java.lang.reflect.Method.invoke (Method.java:498)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launchEnhanced (Launcher.java:255)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launch (Launcher.java:201)
    at org.codehaus.plexus.classworlds.launcher.Launcher.mainWithExitCode (Launcher.java:361)
    at org.codehaus.plexus.classworlds.launcher.Launcher.main (Launcher.java:314)
Caused by: org.apache.maven.plugin.MojoExecutionException: Fatal error compiling
    at org.apache.maven.plugin.compiler.AbstractCompilerMojo.execute (AbstractCompilerMojo.java:1143)
    at org.apache.maven.plugin.compiler.CompilerMojo.execute (CompilerMojo.java:193)
    at org.apache.maven.plugin.DefaultBuildPluginManager.executeMojo (DefaultBuildPluginManager.java:126)
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute2 (MojoExecutor.java:328)
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute (MojoExecutor.java:316)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:212)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:174)
    at org.apache.maven.lifecycle.internal.MojoExecutor.access$000 (MojoExecutor.java:75)
    at org.apache.maven.lifecycle.internal.MojoExecutor$1.run (MojoExecutor.java:162)
    at org.apache.maven.plugin.DefaultMojosExecutionStrategy.execute (DefaultMojosExecutionStrategy.java:39)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:159)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:105)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:73)
    at org.apache.maven.lifecycle.internal.builder.singlethreaded.SingleThreadedBuilder.build (SingleThreadedBuilder.java:53)
    at org.apache.maven.lifecycle.internal.LifecycleStarter.execute (LifecycleStarter.java:118)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:261)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:173)
    at org.apache.maven.DefaultMaven.execute (DefaultMaven.java:101)
    at org.apache.maven.cli.MavenCli.execute (MavenCli.java:906)
    at org.apache.maven.cli.MavenCli.doMain (MavenCli.java:283)
    at org.apache.maven.cli.MavenCli.main (MavenCli.java:206)
    at sun.reflect.NativeMethodAccessorImpl.invoke0 (Native Method)
    at sun.reflect.NativeMethodAccessorImpl.invoke (NativeMethodAccessorImpl.java:62)
    at sun.reflect.DelegatingMethodAccessorImpl.invoke (DelegatingMethodAccessorImpl.java:43)
    at java.lang.reflect.Method.invoke (Method.java:498)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launchEnhanced (Launcher.java:255)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launch (Launcher.java:201)
    at org.codehaus.plexus.classworlds.launcher.Launcher.mainWithExitCode (Launcher.java:361)
    at org.codehaus.plexus.classworlds.launcher.Launcher.main (Launcher.java:314)
Caused by: org.codehaus.plexus.compiler.CompilerException: invalid target release: 18
    at org.codehaus.plexus.compiler.javac.JavaxToolsCompiler.compileInProcess (JavaxToolsCompiler.java:198)
    at org.codehaus.plexus.compiler.javac.JavacCompiler.performCompile (JavacCompiler.java:183)
    at org.apache.maven.plugin.compiler.AbstractCompilerMojo.execute (AbstractCompilerMojo.java:1140)
    at org.apache.maven.plugin.compiler.CompilerMojo.execute (CompilerMojo.java:193)
    at org.apache.maven.plugin.DefaultBuildPluginManager.executeMojo (DefaultBuildPluginManager.java:126)
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute2 (MojoExecutor.java:328)
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute (MojoExecutor.java:316)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:212)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:174)
    at org.apache.maven.lifecycle.internal.MojoExecutor.access$000 (MojoExecutor.java:75)
    at org.apache.maven.lifecycle.internal.MojoExecutor$1.run (MojoExecutor.java:162)
    at org.apache.maven.plugin.DefaultMojosExecutionStrategy.execute (DefaultMojosExecutionStrategy.java:39)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:159)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:105)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:73)
    at org.apache.maven.lifecycle.internal.builder.singlethreaded.SingleThreadedBuilder.build (SingleThreadedBuilder.java:53)
    at org.apache.maven.lifecycle.internal.LifecycleStarter.execute (LifecycleStarter.java:118)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:261)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:173)
    at org.apache.maven.DefaultMaven.execute (DefaultMaven.java:101)
    at org.apache.maven.cli.MavenCli.execute (MavenCli.java:906)
    at org.apache.maven.cli.MavenCli.doMain (MavenCli.java:283)
    at org.apache.maven.cli.MavenCli.main (MavenCli.java:206)
    at sun.reflect.NativeMethodAccessorImpl.invoke0 (Native Method)
    at sun.reflect.NativeMethodAccessorImpl.invoke (NativeMethodAccessorImpl.java:62)
    at sun.reflect.DelegatingMethodAccessorImpl.invoke (DelegatingMethodAccessorImpl.java:43)
    at java.lang.reflect.Method.invoke (Method.java:498)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launchEnhanced (Launcher.java:255)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launch (Launcher.java:201)
    at org.codehaus.plexus.classworlds.launcher.Launcher.mainWithExitCode (Launcher.java:361)
    at org.codehaus.plexus.classworlds.launcher.Launcher.main (Launcher.java:314)
Caused by: java.lang.IllegalArgumentException: invalid target release: 18
    at com.sun.tools.javac.main.OptionHelper$GrumpyHelper.error (OptionHelper.java:103)
    at com.sun.tools.javac.main.Option$12.process (Option.java:216)
    at com.sun.tools.javac.api.JavacTool.processOptions (JavacTool.java:217)
    at com.sun.tools.javac.api.JavacTool.getTask (JavacTool.java:156)
    at com.sun.tools.javac.api.JavacTool.getTask (JavacTool.java:107)
    at com.sun.tools.javac.api.JavacTool.getTask (JavacTool.java:64)
    at org.codehaus.plexus.compiler.javac.JavaxToolsCompiler.compileInProcess (JavaxToolsCompiler.java:135)
    at org.codehaus.plexus.compiler.javac.JavacCompiler.performCompile (JavacCompiler.java:183)
    at org.apache.maven.plugin.compiler.AbstractCompilerMojo.execute (AbstractCompilerMojo.java:1140)
    at org.apache.maven.plugin.compiler.CompilerMojo.execute (CompilerMojo.java:193)
    at org.apache.maven.plugin.DefaultBuildPluginManager.executeMojo (DefaultBuildPluginManager.java:126)
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute2 (MojoExecutor.java:328)
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute (MojoExecutor.java:316)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:212)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:174)
    at org.apache.maven.lifecycle.internal.MojoExecutor.access$000 (MojoExecutor.java:75)
    at org.apache.maven.lifecycle.internal.MojoExecutor$1.run (MojoExecutor.java:162)
    at org.apache.maven.plugin.DefaultMojosExecutionStrategy.execute (DefaultMojosExecutionStrategy.java:39)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:159)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:105)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:73)
    at org.apache.maven.lifecycle.internal.builder.singlethreaded.SingleThreadedBuilder.build (SingleThreadedBuilder.java:53)
    at org.apache.maven.lifecycle.internal.LifecycleStarter.execute (LifecycleStarter.java:118)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:261)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:173)
    at org.apache.maven.DefaultMaven.execute (DefaultMaven.java:101)
    at org.apache.maven.cli.MavenCli.execute (MavenCli.java:906)
    at org.apache.maven.cli.MavenCli.doMain (MavenCli.java:283)
    at org.apache.maven.cli.MavenCli.main (MavenCli.java:206)
    at sun.reflect.NativeMethodAccessorImpl.invoke0 (Native Method)
    at sun.reflect.NativeMethodAccessorImpl.invoke (NativeMethodAccessorImpl.java:62)
    at sun.reflect.DelegatingMethodAccessorImpl.invoke (DelegatingMethodAccessorImpl.java:43)
    at java.lang.reflect.Method.invoke (Method.java:498)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launchEnhanced (Launcher.java:255)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launch (Launcher.java:201)
    at org.codehaus.plexus.classworlds.launcher.Launcher.mainWithExitCode (Launcher.java:361)
    at org.codehaus.plexus.classworlds.launcher.Launcher.main (Launcher.java:314)
[ERROR]
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR]
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException

```



### 依赖树

[root@base rocketmq-dashboard]# mvn dependency:tree

```
[INFO] Scanning for projects...
Downloading from central: https://repo.maven.apache.org/maven2/com/spotify/docker-maven-plugin/0.4.11/docker-maven-plugin-0.4.11.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/spotify/docker-maven-plugin/0.4.11/docker-maven-plugin-0.4.11.pom (13 kB at 11 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/spotify/docker-maven-plugin/0.4.11/docker-maven-plugin-0.4.11.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/spotify/docker-maven-plugin/0.4.11/docker-maven-plugin-0.4.11.jar (47 kB at 128 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/mojo/findbugs-maven-plugin/3.0.4/findbugs-maven-plugin-3.0.4.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/mojo/findbugs-maven-plugin/3.0.4/findbugs-maven-plugin-3.0.4.pom (22 kB at 106 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/mojo/mojo-parent/35/mojo-parent-35.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/mojo/mojo-parent/35/mojo-parent-35.pom (25 kB at 119 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/codehaus-parent/4/codehaus-parent-4.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/codehaus-parent/4/codehaus-parent-4.pom (4.8 kB at 23 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/mojo/findbugs-maven-plugin/3.0.4/findbugs-maven-plugin-3.0.4.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/mojo/findbugs-maven-plugin/3.0.4/findbugs-maven-plugin-3.0.4.jar (146 kB at 360 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/eluder/coveralls/coveralls-maven-plugin/4.3.0/coveralls-maven-plugin-4.3.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/eluder/coveralls/coveralls-maven-plugin/4.3.0/coveralls-maven-plugin-4.3.0.pom (10 kB at 48 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/eluder/eluder-parent/8/eluder-parent-8.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/eluder/eluder-parent/8/eluder-parent-8.pom (15 kB at 72 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/eluder/coveralls/coveralls-maven-plugin/4.3.0/coveralls-maven-plugin-4.3.0.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/eluder/coveralls/coveralls-maven-plugin/4.3.0/coveralls-maven-plugin-4.3.0.jar (90 kB at 297 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/rat/apache-rat-plugin/0.12/apache-rat-plugin-0.12.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/rat/apache-rat-plugin/0.12/apache-rat-plugin-0.12.pom (10 kB at 46 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/rat/apache-rat-project/0.12/apache-rat-project-0.12.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/rat/apache-rat-project/0.12/apache-rat-project-0.12.pom (24 kB at 120 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/rat/apache-rat-plugin/0.12/apache-rat-plugin-0.12.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/rat/apache-rat-plugin/0.12/apache-rat-plugin-0.12.jar (47 kB at 185 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-install-plugin/2.5.2/maven-install-plugin-2.5.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-install-plugin/2.5.2/maven-install-plugin-2.5.2.pom (6.4 kB at 6.2 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-install-plugin/2.5.2/maven-install-plugin-2.5.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-install-plugin/2.5.2/maven-install-plugin-2.5.2.jar (33 kB at 148 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-deploy-plugin/2.8.2/maven-deploy-plugin-2.8.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-deploy-plugin/2.8.2/maven-deploy-plugin-2.8.2.pom (7.1 kB at 36 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-deploy-plugin/2.8.2/maven-deploy-plugin-2.8.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-deploy-plugin/2.8.2/maven-deploy-plugin-2.8.2.jar (34 kB at 145 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-assembly-plugin/2.6/maven-assembly-plugin-2.6.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-assembly-plugin/2.6/maven-assembly-plugin-2.6.pom (16 kB at 79 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-assembly-plugin/2.6/maven-assembly-plugin-2.6.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-assembly-plugin/2.6/maven-assembly-plugin-2.6.jar (246 kB at 589 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-compiler-plugin/3.5.1/maven-compiler-plugin-3.5.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-compiler-plugin/3.5.1/maven-compiler-plugin-3.5.1.pom (10 kB at 46 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-compiler-plugin/3.5.1/maven-compiler-plugin-3.5.1.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-compiler-plugin/3.5.1/maven-compiler-plugin-3.5.1.jar (50 kB at 205 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-dependency-plugin/2.10/maven-dependency-plugin-2.10.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-dependency-plugin/2.10/maven-dependency-plugin-2.10.pom (12 kB at 52 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-dependency-plugin/2.10/maven-dependency-plugin-2.10.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-dependency-plugin/2.10/maven-dependency-plugin-2.10.jar (160 kB at 488 kB/s)
[INFO]
[INFO] ---------------< org.apache.rocketmq:rocketmq-dashboard >---------------
[INFO] Building rocketmq-dashboard 2.1.1-SNAPSHOT
[INFO]   from pom.xml
[INFO] --------------------------------[ jar ]---------------------------------
[INFO]
[INFO] --- dependency:2.10:tree (default-cli) @ rocketmq-dashboard ---
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/reporting/maven-reporting-impl/2.2/maven-reporting-impl-2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/reporting/maven-reporting-impl/2.2/maven-reporting-impl-2.2.pom (4.7 kB at 20 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-archiver/2.9/plexus-archiver-2.9.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-archiver/2.9/plexus-archiver-2.9.pom (4.4 kB at 21 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-components/1.3/plexus-components-1.3.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-components/1.3/plexus-components-1.3.pom (3.1 kB at 14 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-io/2.4/plexus-io-2.4.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-io/2.4/plexus-io-2.4.pom (3.7 kB at 19 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-components/1.2/plexus-components-1.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-components/1.2/plexus-components-1.2.pom (3.1 kB at 15 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/commons-io/commons-io/2.2/commons-io-2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/commons-io/commons-io/2.2/commons-io-2.2.pom (11 kB at 53 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/commons/commons-parent/24/commons-parent-24.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/commons/commons-parent/24/commons-parent-24.pom (47 kB at 238 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/commons/commons-compress/1.9/commons-compress-1.9.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/commons/commons-compress/1.9/commons-compress-1.9.pom (11 kB at 59 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-dependency-analyzer/1.6/maven-dependency-analyzer-1.6.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-dependency-analyzer/1.6/maven-dependency-analyzer-1.6.pom (5.4 kB at 25 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/ow2/asm/asm/5.0.2/asm-5.0.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/ow2/asm/asm/5.0.2/asm-5.0.2.pom (1.9 kB at 10 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/ow2/asm/asm-parent/5.0.2/asm-parent-5.0.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/ow2/asm/asm-parent/5.0.2/asm-parent-5.0.2.pom (5.5 kB at 29 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-utils/1.5.1/plexus-utils-1.5.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-utils/1.5.1/plexus-utils-1.5.1.pom (2.3 kB at 11 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-project/2.0.5/maven-project-2.0.5.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-project/2.0.5/maven-project-2.0.5.pom (1.8 kB at 8.8 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven/2.0.5/maven-2.0.5.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven/2.0.5/maven-2.0.5.pom (5.7 kB at 25 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-settings/2.0.5/maven-settings-2.0.5.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-settings/2.0.5/maven-settings-2.0.5.pom (1.7 kB at 8.5 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-model/2.0.5/maven-model-2.0.5.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-model/2.0.5/maven-model-2.0.5.pom (2.7 kB at 11 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-profile/2.0.5/maven-profile-2.0.5.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-profile/2.0.5/maven-profile-2.0.5.pom (1.7 kB at 6.7 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-artifact-manager/2.0.5/maven-artifact-manager-2.0.5.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-artifact-manager/2.0.5/maven-artifact-manager-2.0.5.pom (1.8 kB at 9.4 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-repository-metadata/2.0.5/maven-repository-metadata-2.0.5.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-repository-metadata/2.0.5/maven-repository-metadata-2.0.5.pom (1.5 kB at 7.5 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-artifact/2.0.5/maven-artifact-2.0.5.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-artifact/2.0.5/maven-artifact-2.0.5.pom (727 B at 3.5 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-dependency-tree/2.2/maven-dependency-tree-2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-dependency-tree/2.2/maven-dependency-tree-2.2.pom (7.3 kB at 34 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/eclipse/aether/aether-util/0.9.0.M2/aether-util-0.9.0.M2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/eclipse/aether/aether-util/0.9.0.M2/aether-util-0.9.0.M2.pom (2.0 kB at 10 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/eclipse/aether/aether/0.9.0.M2/aether-0.9.0.M2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/eclipse/aether/aether/0.9.0.M2/aether-0.9.0.M2.pom (28 kB at 135 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-invoker/2.1.1/maven-invoker-2.1.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-invoker/2.1.1/maven-invoker-2.1.1.pom (5.6 kB at 28 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/reporting/maven-reporting-impl/2.2/maven-reporting-impl-2.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/reporting/maven-reporting-impl/2.2/maven-reporting-impl-2.2.jar (17 kB at 83 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/commons-beanutils/commons-beanutils/1.7.0/commons-beanutils-1.7.0.jar
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-velocity/1.1.7/plexus-velocity-1.1.7.jar
Downloading from central: https://repo.maven.apache.org/maven2/antlr/antlr/2.7.2/antlr-2.7.2.jar
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-archiver/2.9/plexus-archiver-2.9.jar
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/commons/commons-compress/1.9/commons-compress-1.9.jar
Downloaded from central: https://repo.maven.apache.org/maven2/commons-beanutils/commons-beanutils/1.7.0/commons-beanutils-1.7.0.jar (189 kB at 305 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-io/2.4/plexus-io-2.4.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-velocity/1.1.7/plexus-velocity-1.1.7.jar (7.7 kB at 9.1 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-dependency-analyzer/1.6/maven-dependency-analyzer-1.6.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-io/2.4/plexus-io-2.4.jar (81 kB at 79 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/ow2/asm/asm/5.0.2/asm-5.0.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/ow2/asm/asm/5.0.2/asm-5.0.2.jar (53 kB at 38 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-dependency-tree/2.2/maven-dependency-tree-2.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-dependency-analyzer/1.6/maven-dependency-analyzer-1.6.jar (32 kB at 22 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/eclipse/aether/aether-util/0.9.0.M2/aether-util-0.9.0.M2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/antlr/antlr/2.7.2/antlr-2.7.2.jar (358 kB at 227 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-invoker/2.1.1/maven-invoker-2.1.1.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-archiver/2.9/plexus-archiver-2.9.jar (145 kB at 81 kB/s)
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-dependency-tree/2.2/maven-dependency-tree-2.2.jar (64 kB at 35 kB/s)
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-invoker/2.1.1/maven-invoker-2.1.1.jar (30 kB at 16 kB/s)
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/commons/commons-compress/1.9/commons-compress-1.9.jar (378 kB at 185 kB/s)
Downloaded from central: https://repo.maven.apache.org/maven2/org/eclipse/aether/aether-util/0.9.0.M2/aether-util-0.9.0.M2.jar (134 kB at 59 kB/s)
[INFO] org.apache.rocketmq:rocketmq-dashboard:jar:2.1.1-SNAPSHOT
[INFO] +- org.springframework.boot:spring-boot-starter-web:jar:3.4.5:compile
[INFO] |  +- org.springframework.boot:spring-boot-starter:jar:3.4.5:compile
[INFO] |  |  +- org.springframework.boot:spring-boot:jar:3.4.5:compile
[INFO] |  |  +- org.springframework.boot:spring-boot-autoconfigure:jar:3.4.5:compile
[INFO] |  |  +- org.springframework.boot:spring-boot-starter-logging:jar:3.4.5:compile
[INFO] |  |  |  +- ch.qos.logback:logback-classic:jar:1.5.18:compile
[INFO] |  |  |  |  \- ch.qos.logback:logback-core:jar:1.5.18:compile
[INFO] |  |  |  \- org.apache.logging.log4j:log4j-to-slf4j:jar:2.24.3:compile
[INFO] |  |  |     \- org.apache.logging.log4j:log4j-api:jar:2.24.3:compile
[INFO] |  |  \- jakarta.annotation:jakarta.annotation-api:jar:2.1.1:compile
[INFO] |  +- org.springframework.boot:spring-boot-starter-json:jar:3.4.5:compile
[INFO] |  |  +- com.fasterxml.jackson.core:jackson-databind:jar:2.18.3:compile
[INFO] |  |  |  +- com.fasterxml.jackson.core:jackson-annotations:jar:2.18.3:compile
[INFO] |  |  |  \- com.fasterxml.jackson.core:jackson-core:jar:2.18.3:compile
[INFO] |  |  +- com.fasterxml.jackson.datatype:jackson-datatype-jdk8:jar:2.18.3:compile
[INFO] |  |  +- com.fasterxml.jackson.datatype:jackson-datatype-jsr310:jar:2.18.3:compile
[INFO] |  |  \- com.fasterxml.jackson.module:jackson-module-parameter-names:jar:2.18.3:compile
[INFO] |  +- org.springframework.boot:spring-boot-starter-tomcat:jar:3.4.5:compile
[INFO] |  |  +- org.apache.tomcat.embed:tomcat-embed-core:jar:10.1.40:compile
[INFO] |  |  \- org.apache.tomcat.embed:tomcat-embed-websocket:jar:10.1.40:compile
[INFO] |  +- org.springframework:spring-web:jar:6.2.6:compile
[INFO] |  \- org.springframework:spring-webmvc:jar:6.2.6:compile
[INFO] |     +- org.springframework:spring-context:jar:6.2.6:compile
[INFO] |     \- org.springframework:spring-expression:jar:6.2.6:compile
[INFO] +- org.springframework.boot:spring-boot-starter-actuator:jar:3.4.5:compile
[INFO] |  +- org.springframework.boot:spring-boot-actuator-autoconfigure:jar:3.4.5:compile
[INFO] |  |  \- org.springframework.boot:spring-boot-actuator:jar:3.4.5:compile
[INFO] |  +- io.micrometer:micrometer-observation:jar:1.14.6:compile
[INFO] |  |  \- io.micrometer:micrometer-commons:jar:1.14.6:compile
[INFO] |  \- io.micrometer:micrometer-jakarta9:jar:1.14.6:compile
[INFO] |     \- io.micrometer:micrometer-core:jar:1.14.6:compile
[INFO] |        +- org.hdrhistogram:HdrHistogram:jar:2.2.2:runtime
[INFO] |        \- org.latencyutils:LatencyUtils:jar:2.0.3:runtime
[INFO] +- org.springframework.data:spring-data-commons:jar:3.4.5:compile
[INFO] |  +- org.springframework:spring-core:jar:6.2.6:compile
[INFO] |  |  \- org.springframework:spring-jcl:jar:6.2.6:compile
[INFO] |  +- org.springframework:spring-beans:jar:6.2.6:compile
[INFO] |  \- org.slf4j:slf4j-api:jar:2.0.2:compile
[INFO] +- org.springframework.boot:spring-boot-starter-test:jar:3.4.5:test
[INFO] |  +- org.springframework.boot:spring-boot-test:jar:3.4.5:test
[INFO] |  +- org.springframework.boot:spring-boot-test-autoconfigure:jar:3.4.5:test
[INFO] |  +- com.jayway.jsonpath:json-path:jar:2.9.0:test
[INFO] |  +- net.minidev:json-smart:jar:2.5.2:test
[INFO] |  |  \- net.minidev:accessors-smart:jar:2.5.2:test
[INFO] |  +- org.assertj:assertj-core:jar:3.26.3:test
[INFO] |  |  \- net.bytebuddy:byte-buddy:jar:1.14.18:test
[INFO] |  +- org.awaitility:awaitility:jar:4.2.2:compile
[INFO] |  +- org.hamcrest:hamcrest:jar:2.2:compile
[INFO] |  +- org.junit.jupiter:junit-jupiter:jar:5.11.4:test
[INFO] |  |  +- org.junit.jupiter:junit-jupiter-api:jar:5.11.4:test
[INFO] |  |  |  +- org.opentest4j:opentest4j:jar:1.3.0:test
[INFO] |  |  |  +- org.junit.platform:junit-platform-commons:jar:1.11.4:test
[INFO] |  |  |  \- org.apiguardian:apiguardian-api:jar:1.1.2:test
[INFO] |  |  +- org.junit.jupiter:junit-jupiter-params:jar:5.11.4:test
[INFO] |  |  \- org.junit.jupiter:junit-jupiter-engine:jar:5.11.4:test
[INFO] |  |     \- org.junit.platform:junit-platform-engine:jar:1.11.4:test
[INFO] |  +- org.mockito:mockito-junit-jupiter:jar:5.14.2:test
[INFO] |  +- org.skyscreamer:jsonassert:jar:1.5.3:test
[INFO] |  |  \- com.vaadin.external.google:android-json:jar:0.0.20131108.vaadin1:test
[INFO] |  +- org.springframework:spring-test:jar:6.2.6:test
[INFO] |  \- org.xmlunit:xmlunit-core:jar:2.10.0:test
[INFO] +- org.springframework.boot:spring-boot-starter-validation:jar:3.4.5:compile
[INFO] |  +- org.apache.tomcat.embed:tomcat-embed-el:jar:10.1.40:compile
[INFO] |  \- org.hibernate.validator:hibernate-validator:jar:8.0.2.Final:compile
[INFO] |     +- jakarta.validation:jakarta.validation-api:jar:3.0.2:compile
[INFO] |     +- org.jboss.logging:jboss-logging:jar:3.4.3.Final:compile
[INFO] |     \- com.fasterxml:classmate:jar:1.5.1:compile
[INFO] +- org.springframework.boot:spring-boot-starter-security:jar:3.4.5:compile
[INFO] |  +- org.springframework:spring-aop:jar:6.2.6:compile
[INFO] |  +- org.springframework.security:spring-security-config:jar:6.4.5:compile
[INFO] |  |  \- org.springframework.security:spring-security-core:jar:6.4.5:compile
[INFO] |  |     \- org.springframework.security:spring-security-crypto:jar:6.4.5:compile
[INFO] |  \- org.springframework.security:spring-security-web:jar:6.4.5:compile
[INFO] +- commons-collections:commons-collections:jar:3.2.2:compile
[INFO] +- org.apache.rocketmq:rocketmq-tools:jar:5.3.3:compile
[INFO] |  +- org.apache.rocketmq:rocketmq-client:jar:5.3.3:compile
[INFO] |  +- org.apache.rocketmq:rocketmq-auth:jar:5.3.3:compile
[INFO] |  |  +- org.apache.rocketmq:rocketmq-proto:jar:2.0.4:compile
[INFO] |  |  +- commons-codec:commons-codec:jar:1.13:compile
[INFO] |  |  +- com.google.protobuf:protobuf-java-util:jar:3.20.1:compile
[INFO] |  |  |  \- com.google.protobuf:protobuf-java:jar:3.20.1:compile
[INFO] |  |  \- com.github.ben-manes.caffeine:caffeine:jar:2.9.3:compile
[INFO] |  +- org.apache.rocketmq:rocketmq-srvutil:jar:5.3.3:compile
[INFO] |  |  +- org.apache.rocketmq:rocketmq-common:jar:5.3.3:compile
[INFO] |  |  |  +- com.alibaba.fastjson2:fastjson2:jar:2.0.43:compile
[INFO] |  |  |  +- io.netty:netty-all:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-buffer:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-codec:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-codec-dns:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-codec-haproxy:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-codec-http:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-codec-http2:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-codec-memcache:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-codec-mqtt:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-codec-redis:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-codec-smtp:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-codec-socks:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-codec-stomp:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-codec-xml:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-common:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-handler:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-transport-native-unix-common:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-handler-proxy:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-handler-ssl-ocsp:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-resolver:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-resolver-dns:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-transport:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-transport-rxtx:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-transport-sctp:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-transport-udt:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-transport-classes-epoll:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-transport-classes-kqueue:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-resolver-dns-classes-macos:jar:4.1.114.Final:compile
[INFO] |  |  |  |  +- io.netty:netty-transport-native-epoll:jar:linux-x86_64:4.1.114.Final:runtime
[INFO] |  |  |  |  +- io.netty:netty-transport-native-epoll:jar:linux-aarch_64:4.1.114.Final:runtime
[INFO] |  |  |  |  +- io.netty:netty-transport-native-epoll:jar:linux-riscv64:4.1.114.Final:runtime
[INFO] |  |  |  |  +- io.netty:netty-transport-native-kqueue:jar:osx-x86_64:4.1.114.Final:runtime
[INFO] |  |  |  |  +- io.netty:netty-transport-native-kqueue:jar:osx-aarch_64:4.1.114.Final:runtime
[INFO] |  |  |  |  +- io.netty:netty-resolver-dns-native-macos:jar:osx-x86_64:4.1.114.Final:runtime
[INFO] |  |  |  |  \- io.netty:netty-resolver-dns-native-macos:jar:osx-aarch_64:4.1.114.Final:runtime
[INFO] |  |  |  +- commons-validator:commons-validator:jar:1.7:compile
[INFO] |  |  |  |  +- commons-beanutils:commons-beanutils:jar:1.9.4:compile
[INFO] |  |  |  |  +- commons-digester:commons-digester:jar:2.1:compile
[INFO] |  |  |  |  \- commons-logging:commons-logging:jar:1.2:compile
[INFO] |  |  |  +- com.github.luben:zstd-jni:jar:1.5.2-2:compile
[INFO] |  |  |  +- org.lz4:lz4-java:jar:1.8.0:compile
[INFO] |  |  |  +- io.opentelemetry:opentelemetry-exporter-otlp:jar:1.29.0:compile
[INFO] |  |  |  |  +- io.opentelemetry:opentelemetry-sdk-trace:jar:1.29.0:compile
[INFO] |  |  |  |  |  \- io.opentelemetry:opentelemetry-semconv:jar:1.29.0-alpha:runtime
[INFO] |  |  |  |  +- io.opentelemetry:opentelemetry-sdk-metrics:jar:1.29.0:compile
[INFO] |  |  |  |  |  \- io.opentelemetry:opentelemetry-extension-incubator:jar:1.29.0-alpha:runtime
[INFO] |  |  |  |  +- io.opentelemetry:opentelemetry-sdk-logs:jar:1.29.0:compile
[INFO] |  |  |  |  |  \- io.opentelemetry:opentelemetry-api-events:jar:1.29.0-alpha:runtime
[INFO] |  |  |  |  +- io.opentelemetry:opentelemetry-exporter-otlp-common:jar:1.29.0:runtime
[INFO] |  |  |  |  |  \- io.opentelemetry:opentelemetry-exporter-common:jar:1.29.0:runtime
[INFO] |  |  |  |  +- io.opentelemetry:opentelemetry-exporter-sender-okhttp:jar:1.29.0:runtime
[INFO] |  |  |  |  |  \- com.squareup.okhttp3:okhttp:jar:4.11.0:runtime
[INFO] |  |  |  |  |     +- com.squareup.okio:okio:jar:3.2.0:runtime
[INFO] |  |  |  |  |     +- org.jetbrains.kotlin:kotlin-stdlib:jar:1.6.20:runtime
[INFO] |  |  |  |  |     |  +- org.jetbrains.kotlin:kotlin-stdlib-common:jar:1.6.20:runtime
[INFO] |  |  |  |  |     |  \- org.jetbrains:annotations:jar:13.0:runtime
[INFO] |  |  |  |  |     \- org.jetbrains.kotlin:kotlin-stdlib-jdk8:jar:1.6.20:runtime
[INFO] |  |  |  |  |        \- org.jetbrains.kotlin:kotlin-stdlib-jdk7:jar:1.6.20:runtime
[INFO] |  |  |  |  \- io.opentelemetry:opentelemetry-sdk-extension-autoconfigure-spi:jar:1.29.0:runtime
[INFO] |  |  |  +- io.opentelemetry:opentelemetry-exporter-prometheus:jar:1.29.0-alpha:compile
[INFO] |  |  |  +- io.opentelemetry:opentelemetry-exporter-logging:jar:1.29.0:compile
[INFO] |  |  |  +- io.opentelemetry:opentelemetry-sdk:jar:1.29.0:compile
[INFO] |  |  |  |  +- io.opentelemetry:opentelemetry-api:jar:1.29.0:compile
[INFO] |  |  |  |  |  \- io.opentelemetry:opentelemetry-context:jar:1.29.0:compile
[INFO] |  |  |  |  \- io.opentelemetry:opentelemetry-sdk-common:jar:1.29.0:compile
[INFO] |  |  |  +- io.opentelemetry:opentelemetry-exporter-logging-otlp:jar:1.29.0:compile
[INFO] |  |  |  +- io.grpc:grpc-stub:jar:1.53.0:compile
[INFO] |  |  |  |  \- io.grpc:grpc-api:jar:1.53.0:compile
[INFO] |  |  |  |     \- io.grpc:grpc-context:jar:1.53.0:compile
[INFO] |  |  |  +- io.grpc:grpc-netty-shaded:jar:1.53.0:compile
[INFO] |  |  |  |  +- io.perfmark:perfmark-api:jar:0.25.0:runtime
[INFO] |  |  |  |  \- io.grpc:grpc-core:jar:1.53.0:compile (version selected from constraint [1.53.0,1.53.0])
[INFO] |  |  |  |     +- com.google.code.gson:gson:jar:2.9.0:runtime
[INFO] |  |  |  |     +- com.google.android:annotations:jar:4.1.1.4:runtime
[INFO] |  |  |  |     \- org.codehaus.mojo:animal-sniffer-annotations:jar:1.21:runtime
[INFO] |  |  |  +- com.squareup.okio:okio-jvm:jar:3.4.0:compile
[INFO] |  |  |  +- org.apache.tomcat:annotations-api:jar:6.0.53:compile
[INFO] |  |  |  \- org.apache.rocketmq:rocketmq-rocksdb:jar:1.0.2:compile
[INFO] |  |  \- commons-cli:commons-cli:jar:1.5.0:compile
[INFO] |  +- com.alibaba:fastjson:jar:1.2.83:compile
[INFO] |  \- org.apache.commons:commons-lang3:jar:3.12.0:compile
[INFO] +- org.apache.rocketmq:rocketmq-namesrv:jar:5.3.3:test
[INFO] |  \- org.apache.rocketmq:rocketmq-controller:jar:5.3.3:test
[INFO] |     +- io.openmessaging.storage:dledger:jar:0.3.1.2:test
[INFO] |     \- com.alipay.sofa:jraft-core:jar:1.3.14:test
[INFO] |        +- org.jctools:jctools-core:jar:2.1.1:test
[INFO] |        +- com.lmax:disruptor:jar:3.3.7:test
[INFO] |        +- commons-lang:commons-lang:jar:2.6:test
[INFO] |        +- com.alipay.sofa:bolt:jar:1.6.4:test
[INFO] |        |  \- com.alipay.sofa.common:sofa-common-tools:jar:1.0.12:test
[INFO] |        +- com.alipay.sofa:hessian:jar:3.3.6:test
[INFO] |        \- io.dropwizard.metrics:metrics-core:jar:4.0.2:test
[INFO] +- org.apache.rocketmq:rocketmq-broker:jar:5.3.3:test
[INFO] |  +- org.apache.rocketmq:rocketmq-remoting:jar:5.3.3:compile
[INFO] |  |  \- org.reflections:reflections:jar:0.9.11:compile
[INFO] |  +- org.apache.rocketmq:rocketmq-store:jar:5.3.3:test
[INFO] |  |  +- net.java.dev.jna:jna:jar:4.2.2:test
[INFO] |  |  \- com.conversantmedia:disruptor:jar:1.2.10:test
[INFO] |  +- org.apache.rocketmq:rocketmq-tiered-store:jar:5.3.3:test
[INFO] |  +- io.github.aliyunmq:rocketmq-slf4j-api:jar:1.0.1:compile
[INFO] |  +- io.github.aliyunmq:rocketmq-logback-classic:jar:1.0.1:compile
[INFO] |  +- org.apache.rocketmq:rocketmq-filter:jar:5.3.3:test
[INFO] |  +- commons-io:commons-io:jar:2.14.0:test
[INFO] |  +- org.javassist:javassist:jar:3.20.0-GA:compile
[INFO] |  +- com.googlecode.concurrentlinkedhashmap:concurrentlinkedhashmap-lru:jar:1.4.2:compile
[INFO] |  +- io.github.aliyunmq:rocketmq-shaded-slf4j-api-bridge:jar:1.0.0:test
[INFO] |  \- org.slf4j:jul-to-slf4j:jar:2.0.6:compile
[INFO] +- com.google.guava:guava:jar:29.0-jre:compile
[INFO] |  +- com.google.guava:failureaccess:jar:1.0.1:compile
[INFO] |  +- com.google.guava:listenablefuture:jar:9999.0-empty-to-avoid-conflict-with-guava:compile
[INFO] |  +- com.google.code.findbugs:jsr305:jar:3.0.2:compile
[INFO] |  +- org.checkerframework:checker-qual:jar:2.11.1:compile
[INFO] |  +- com.google.errorprone:error_prone_annotations:jar:2.3.4:compile
[INFO] |  \- com.google.j2objc:j2objc-annotations:jar:1.3:compile
[INFO] +- org.aspectj:aspectjrt:jar:1.9.6:compile
[INFO] +- org.aspectj:aspectjweaver:jar:1.9.6:compile
[INFO] +- cglib:cglib:jar:2.2.2:compile
[INFO] |  \- asm:asm:jar:3.3.1:compile
[INFO] +- org.jooq:joor:jar:0.9.6:compile
[INFO] +- org.bouncycastle:bcpkix-jdk15on:jar:1.68:compile
[INFO] |  \- org.bouncycastle:bcprov-jdk15on:jar:1.68:compile
[INFO] +- jakarta.xml.bind:jakarta.xml.bind-api:jar:4.0.0:compile
[INFO] |  \- jakarta.activation:jakarta.activation-api:jar:2.1.0:compile
[INFO] +- org.projectlombok:lombok:jar:1.18.22:provided
[INFO] +- org.mockito:mockito-inline:jar:3.3.3:test
[INFO] |  \- org.mockito:mockito-core:jar:3.3.3:test
[INFO] |     +- net.bytebuddy:byte-buddy-agent:jar:1.10.5:test
[INFO] |     \- org.objenesis:objenesis:jar:2.6:test
[INFO] +- org.apache.commons:commons-pool2:jar:2.4.3:compile
[INFO] +- com.alibaba:easyexcel:jar:2.2.10:compile
[INFO] |  +- org.apache.poi:poi:jar:3.17:compile
[INFO] |  |  \- org.apache.commons:commons-collections4:jar:4.1:compile
[INFO] |  +- org.apache.poi:poi-ooxml:jar:3.17:compile
[INFO] |  |  \- com.github.virtuald:curvesapi:jar:1.04:compile
[INFO] |  +- org.apache.poi:poi-ooxml-schemas:jar:3.17:compile
[INFO] |  |  \- org.apache.xmlbeans:xmlbeans:jar:2.6.0:compile
[INFO] |  |     \- stax:stax-api:jar:1.0.1:compile
[INFO] |  \- org.ehcache:ehcache:jar:3.4.0:compile
[INFO] +- org.ow2.asm:asm:jar:4.2:compile
[INFO] +- junit:junit:jar:4.12:test
[INFO] |  \- org.hamcrest:hamcrest-core:jar:1.3:test
[INFO] \- org.yaml:snakeyaml:jar:2.0:compile
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  21.000 s
[INFO] Finished at: 2025-10-30T00:59:58-04:00
[INFO] ------------------------------------------------------------------------

```

### 报错3

```
main:
     [copy] Copying 12 files to /root/rocketmq-dashboard/target/classes/public
[INFO] Executed tasks
[INFO]
[INFO] --- resources:2.7:resources (default-resources) @ rocketmq-dashboard ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] Copying 5 resources
[INFO] Copying 3 resources
[INFO]
[INFO] --- compiler:3.11.0:compile (default-compile) @ rocketmq-dashboard ---
[INFO] Changes detected - recompiling the module! :source
[INFO] Compiling 137 source files with javac [debug deprecation target 17] to target/classes
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  03:40 min
[INFO] Finished at: 2025-10-30T01:19:30-04:00
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.11.0:compile (default-compile) on project rocketmq-dashboard: Fatal error compiling: invalid target release: 17 -> [Help 1]
org.apache.maven.lifecycle.LifecycleExecutionException: Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.11.0:compile (default-compile) on project rocketmq-dashboard: Fatal error compiling
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute2 (MojoExecutor.java:333)
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute (MojoExecutor.java:316)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:212)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:174)
    at org.apache.maven.lifecycle.internal.MojoExecutor.access$000 (MojoExecutor.java:75)
    at org.apache.maven.lifecycle.internal.MojoExecutor$1.run (MojoExecutor.java:162)
    at org.apache.maven.plugin.DefaultMojosExecutionStrategy.execute (DefaultMojosExecutionStrategy.java:39)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:159)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:105)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:73)
    at org.apache.maven.lifecycle.internal.builder.singlethreaded.SingleThreadedBuilder.build (SingleThreadedBuilder.java:53)
    at org.apache.maven.lifecycle.internal.LifecycleStarter.execute (LifecycleStarter.java:118)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:261)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:173)
    at org.apache.maven.DefaultMaven.execute (DefaultMaven.java:101)
    at org.apache.maven.cli.MavenCli.execute (MavenCli.java:906)
    at org.apache.maven.cli.MavenCli.doMain (MavenCli.java:283)
    at org.apache.maven.cli.MavenCli.main (MavenCli.java:206)
    at sun.reflect.NativeMethodAccessorImpl.invoke0 (Native Method)
    at sun.reflect.NativeMethodAccessorImpl.invoke (NativeMethodAccessorImpl.java:62)
    at sun.reflect.DelegatingMethodAccessorImpl.invoke (DelegatingMethodAccessorImpl.java:43)
    at java.lang.reflect.Method.invoke (Method.java:498)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launchEnhanced (Launcher.java:255)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launch (Launcher.java:201)
    at org.codehaus.plexus.classworlds.launcher.Launcher.mainWithExitCode (Launcher.java:361)
    at org.codehaus.plexus.classworlds.launcher.Launcher.main (Launcher.java:314)
Caused by: org.apache.maven.plugin.MojoExecutionException: Fatal error compiling
    at org.apache.maven.plugin.compiler.AbstractCompilerMojo.execute (AbstractCompilerMojo.java:1143)
    at org.apache.maven.plugin.compiler.CompilerMojo.execute (CompilerMojo.java:193)
    at org.apache.maven.plugin.DefaultBuildPluginManager.executeMojo (DefaultBuildPluginManager.java:126)
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute2 (MojoExecutor.java:328)
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute (MojoExecutor.java:316)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:212)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:174)
    at org.apache.maven.lifecycle.internal.MojoExecutor.access$000 (MojoExecutor.java:75)
    at org.apache.maven.lifecycle.internal.MojoExecutor$1.run (MojoExecutor.java:162)
    at org.apache.maven.plugin.DefaultMojosExecutionStrategy.execute (DefaultMojosExecutionStrategy.java:39)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:159)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:105)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:73)
    at org.apache.maven.lifecycle.internal.builder.singlethreaded.SingleThreadedBuilder.build (SingleThreadedBuilder.java:53)
    at org.apache.maven.lifecycle.internal.LifecycleStarter.execute (LifecycleStarter.java:118)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:261)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:173)
    at org.apache.maven.DefaultMaven.execute (DefaultMaven.java:101)
    at org.apache.maven.cli.MavenCli.execute (MavenCli.java:906)
    at org.apache.maven.cli.MavenCli.doMain (MavenCli.java:283)
    at org.apache.maven.cli.MavenCli.main (MavenCli.java:206)
    at sun.reflect.NativeMethodAccessorImpl.invoke0 (Native Method)
    at sun.reflect.NativeMethodAccessorImpl.invoke (NativeMethodAccessorImpl.java:62)
    at sun.reflect.DelegatingMethodAccessorImpl.invoke (DelegatingMethodAccessorImpl.java:43)
    at java.lang.reflect.Method.invoke (Method.java:498)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launchEnhanced (Launcher.java:255)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launch (Launcher.java:201)
    at org.codehaus.plexus.classworlds.launcher.Launcher.mainWithExitCode (Launcher.java:361)
    at org.codehaus.plexus.classworlds.launcher.Launcher.main (Launcher.java:314)
Caused by: org.codehaus.plexus.compiler.CompilerException: invalid target release: 17
    at org.codehaus.plexus.compiler.javac.JavaxToolsCompiler.compileInProcess (JavaxToolsCompiler.java:198)
    at org.codehaus.plexus.compiler.javac.JavacCompiler.performCompile (JavacCompiler.java:183)
    at org.apache.maven.plugin.compiler.AbstractCompilerMojo.execute (AbstractCompilerMojo.java:1140)
    at org.apache.maven.plugin.compiler.CompilerMojo.execute (CompilerMojo.java:193)
    at org.apache.maven.plugin.DefaultBuildPluginManager.executeMojo (DefaultBuildPluginManager.java:126)
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute2 (MojoExecutor.java:328)
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute (MojoExecutor.java:316)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:212)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:174)
    at org.apache.maven.lifecycle.internal.MojoExecutor.access$000 (MojoExecutor.java:75)
    at org.apache.maven.lifecycle.internal.MojoExecutor$1.run (MojoExecutor.java:162)
    at org.apache.maven.plugin.DefaultMojosExecutionStrategy.execute (DefaultMojosExecutionStrategy.java:39)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:159)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:105)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:73)
    at org.apache.maven.lifecycle.internal.builder.singlethreaded.SingleThreadedBuilder.build (SingleThreadedBuilder.java:53)
    at org.apache.maven.lifecycle.internal.LifecycleStarter.execute (LifecycleStarter.java:118)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:261)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:173)
    at org.apache.maven.DefaultMaven.execute (DefaultMaven.java:101)
    at org.apache.maven.cli.MavenCli.execute (MavenCli.java:906)
    at org.apache.maven.cli.MavenCli.doMain (MavenCli.java:283)
    at org.apache.maven.cli.MavenCli.main (MavenCli.java:206)
    at sun.reflect.NativeMethodAccessorImpl.invoke0 (Native Method)
    at sun.reflect.NativeMethodAccessorImpl.invoke (NativeMethodAccessorImpl.java:62)
    at sun.reflect.DelegatingMethodAccessorImpl.invoke (DelegatingMethodAccessorImpl.java:43)
    at java.lang.reflect.Method.invoke (Method.java:498)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launchEnhanced (Launcher.java:255)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launch (Launcher.java:201)
    at org.codehaus.plexus.classworlds.launcher.Launcher.mainWithExitCode (Launcher.java:361)
    at org.codehaus.plexus.classworlds.launcher.Launcher.main (Launcher.java:314)
Caused by: java.lang.IllegalArgumentException: invalid target release: 17
    at com.sun.tools.javac.main.OptionHelper$GrumpyHelper.error (OptionHelper.java:103)
    at com.sun.tools.javac.main.Option$12.process (Option.java:216)
    at com.sun.tools.javac.api.JavacTool.processOptions (JavacTool.java:217)
    at com.sun.tools.javac.api.JavacTool.getTask (JavacTool.java:156)
    at com.sun.tools.javac.api.JavacTool.getTask (JavacTool.java:107)
    at com.sun.tools.javac.api.JavacTool.getTask (JavacTool.java:64)
    at org.codehaus.plexus.compiler.javac.JavaxToolsCompiler.compileInProcess (JavaxToolsCompiler.java:135)
    at org.codehaus.plexus.compiler.javac.JavacCompiler.performCompile (JavacCompiler.java:183)
    at org.apache.maven.plugin.compiler.AbstractCompilerMojo.execute (AbstractCompilerMojo.java:1140)
    at org.apache.maven.plugin.compiler.CompilerMojo.execute (CompilerMojo.java:193)
    at org.apache.maven.plugin.DefaultBuildPluginManager.executeMojo (DefaultBuildPluginManager.java:126)
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute2 (MojoExecutor.java:328)
    at org.apache.maven.lifecycle.internal.MojoExecutor.doExecute (MojoExecutor.java:316)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:212)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:174)
    at org.apache.maven.lifecycle.internal.MojoExecutor.access$000 (MojoExecutor.java:75)
    at org.apache.maven.lifecycle.internal.MojoExecutor$1.run (MojoExecutor.java:162)
    at org.apache.maven.plugin.DefaultMojosExecutionStrategy.execute (DefaultMojosExecutionStrategy.java:39)
    at org.apache.maven.lifecycle.internal.MojoExecutor.execute (MojoExecutor.java:159)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:105)
    at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject (LifecycleModuleBuilder.java:73)
    at org.apache.maven.lifecycle.internal.builder.singlethreaded.SingleThreadedBuilder.build (SingleThreadedBuilder.java:53)
    at org.apache.maven.lifecycle.internal.LifecycleStarter.execute (LifecycleStarter.java:118)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:261)
    at org.apache.maven.DefaultMaven.doExecute (DefaultMaven.java:173)
    at org.apache.maven.DefaultMaven.execute (DefaultMaven.java:101)
    at org.apache.maven.cli.MavenCli.execute (MavenCli.java:906)
    at org.apache.maven.cli.MavenCli.doMain (MavenCli.java:283)
    at org.apache.maven.cli.MavenCli.main (MavenCli.java:206)
    at sun.reflect.NativeMethodAccessorImpl.invoke0 (Native Method)
    at sun.reflect.NativeMethodAccessorImpl.invoke (NativeMethodAccessorImpl.java:62)
    at sun.reflect.DelegatingMethodAccessorImpl.invoke (DelegatingMethodAccessorImpl.java:43)
    at java.lang.reflect.Method.invoke (Method.java:498)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launchEnhanced (Launcher.java:255)
    at org.codehaus.plexus.classworlds.launcher.Launcher.launch (Launcher.java:201)
    at org.codehaus.plexus.classworlds.launcher.Launcher.mainWithExitCode (Launcher.java:361)
    at org.codehaus.plexus.classworlds.launcher.Launcher.main (Launcher.java:314)
[ERROR]
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR]
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException

```



## 问题一解决方法

使用jdk17
