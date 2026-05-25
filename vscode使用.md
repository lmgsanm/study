# 配置国外 VSCode 官方源

## 打开setting.json

### 方法 1：快捷键（推荐，最快）

1. 按下：

   - **Windows/Linux**：`Ctrl + Shift + P`
   - **Mac**：`Cmd + Shift + P`

   

2. 输入：`Open Settings (JSON)`

3. 回车，直接打开配置文件

------

### 方法 2：菜单点击

1. 文件 → 首选项 → 设置
2. 右上角点击 **打开设置（JSON）** 图标（一个 `{}` 符号）

## 添加vscode源

复制下面整段进去，**解决 VSCode Server 下载慢 / 失败**：

```
{
    "remote.SSH.serverDownloadUrlTemplate": "https://mirrors.tuna.tsinghua.edu.cn/vscode-server/stable/${commit}/${filename}",
    "remote.SSH.useLocalServer": false
}
```

# 配置kubernete连接

## 安装 2 个插件

1. **Kubernetes**（微软官方）
2. **YAML**

效果：

- 输入 `apiVersion:` 自动提示
- 输入 `spec:` 自动弹出字段
- 不会写错关键字

## 安装kubectl

https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/

- ```powershell
  curl.exe -LO "https://dl.k8s.io/release/v1.36.0/bin/windows/amd64/kubectl.exe"
  ```

  将kubectl.exe拷贝到C:\Windows\System32目录下

## 配置可执行策略

以管理员身份打开 PowerShell，执行这条命令：

```
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```



## 执行自动补全配置

```
# 创建配置文件
if (!(Test-Path -Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }

# 写入 kubectl 自动补全
kubectl completion powershell | Out-File $PROFILE -Encoding utf8

# 立即生效
. $PROFILE
```

## kubeconfig配置

将k8s集群中.kube下的config文件拷贝到C:\Users\Administrator\\.kube目录下

