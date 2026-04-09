## 1.安装 Go

### 软件安装

https://go.dev/learn/

https://dl.google.com/go/go1.24.6.windows-amd64.msi

安装目录：C:\Program Files\Go

```
C:\Users\Administrator>go version
go version go1.24.6 windows/amd64
```

### 环境变量配置

![image-20250812202536480](D:\lmgsanm\03-个人总结\01-学习\Golang\image-20250812202536480.png)

```
C:\Users\Administrator>go env
set AR=ar
set CC=gcc
set CGO_CFLAGS=-O2 -g
set CGO_CPPFLAGS=
set CGO_CXXFLAGS=-O2 -g
set CGO_ENABLED=0
set CGO_FFLAGS=-O2 -g
set CGO_LDFLAGS=-O2 -g
set CXX=g++
set GCCGO=gccgo
set GO111MODULE=
set GOAMD64=v1
set GOARCH=amd64
set GOAUTH=netrc
set GOBIN=
set GOCACHE=C:\Users\Administrator\AppData\Local\go-build
set GOCACHEPROG=
set GODEBUG=
set GOENV=C:\Users\Administrator\AppData\Roaming\go\env
set GOEXE=.exe
set GOEXPERIMENT=
set GOFIPS140=off
set GOFLAGS=
set GOGCCFLAGS=-m64 -fno-caret-diagnostics -Qunused-arguments -Wl,--no-gc-sections -fmessage-length=0 -ffile-prefix-map=C:\Users\ADMINI~1\AppData\Local\Temp\go-build9779775=/tmp/go-build -gno-record-gcc-switches
set GOHOSTARCH=amd64
set GOHOSTOS=windows
set GOINSECURE=
set GOMOD=NUL
set GOMODCACHE=D:\lmgsanm\13-scripts\study\go\pkg\mod
set GONOPROXY=
set GONOSUMDB=
set GOOS=windows
set GOPATH=D:\lmgsanm\13-scripts\study\go
set GOPRIVATE=
set GOPROXY=https://proxy.golang.org,direct
set GOROOT=C:\Program Files\Go
set GOSUMDB=sum.golang.org
set GOTELEMETRY=local
set GOTELEMETRYDIR=C:\Users\Administrator\AppData\Roaming\go\telemetry
set GOTMPDIR=
set GOTOOLCHAIN=auto
set GOTOOLDIR=C:\Program Files\Go\pkg\tool\windows_amd64
set GOVCS=
set GOVERSION=go1.24.6
set GOWORK=
set PKG_CONFIG=pkg-config
```

### 配置国内下载源

C:\Users\Administrator>go env -w GOPROXY=https://goproxy.cn,direct

C:\Users\Administrator>go env -w GOSUMDB=sum.golang.google.cn



```
C:\Users\Administrator>go env
set AR=ar
set CC=gcc
set CGO_CFLAGS=-O2 -g
set CGO_CPPFLAGS=
set CGO_CXXFLAGS=-O2 -g
set CGO_ENABLED=0
set CGO_FFLAGS=-O2 -g
set CGO_LDFLAGS=-O2 -g
set CXX=g++
set GCCGO=gccgo
set GO111MODULE=on
set GOAMD64=v1
set GOARCH=amd64
set GOAUTH=netrc
set GOBIN=
set GOCACHE=C:\Users\Administrator\AppData\Local\go-build
set GOCACHEPROG=
set GODEBUG=
set GOENV=C:\Users\Administrator\AppData\Roaming\go\env
set GOEXE=.exe
set GOEXPERIMENT=
set GOFIPS140=off
set GOFLAGS=
set GOGCCFLAGS=-m64 -fno-caret-diagnostics -Qunused-arguments -Wl,--no-gc-sections -fmessage-length=0 -ffile-prefix-map=C:\Users\ADMINI~1\AppData\Local\Temp\go-build2484682492=/tmp/go-build -gno-record-gcc-switches
set GOHOSTARCH=amd64
set GOHOSTOS=windows
set GOINSECURE=
set GOMOD=NUL
set GOMODCACHE=D:\lmgsanm\13-scripts\study\go\pkg\mod
set GONOPROXY=
set GONOSUMDB=
set GOOS=windows
set GOPATH=D:\lmgsanm\13-scripts\study\go
set GOPRIVATE=
set GOPROXY=https://goproxy.cn,direct
set GOROOT=C:\Program Files\Go
set GOSUMDB=sum.golang.google.cn
set GOTELEMETRY=on
set GOTELEMETRYDIR=C:\Users\Administrator\AppData\Roaming\go\telemetry
set GOTMPDIR=
set GOTOOLCHAIN=auto
set GOTOOLDIR=C:\Program Files\Go\pkg\tool\windows_amd64
set GOVCS=
set GOVERSION=go1.24.6
set GOWORK=
set PKG_CONFIG=pkg-config
```



## 2.安装 Visual Studio Code

https://code.visualstudio.com/

https://vscode.download.prss.microsoft.com/dbazure/download/stable/e3550cfac4b63ca4eafca7b601f0d2885817fd1f/VSCodeUserSetup-x64-1.103.0.exe

安装目录：C:\Users\Administrator\AppData\Local\Programs\Microsoft VS Code

## 3.安装 Go 扩展

在 Visual Studio Code 中，通过单击活动栏中的“扩展”图标来显示“扩展”视图。 或使用键盘快捷方式（Ctrl+Shift+X）。

搜索 Go 扩展，然后选择“安装”。

## 4.更新 Go 工具

在 Visual Studio Code 中，打开 **命令面板**的 **“帮助**>**显示所有命令**”。 或使用键盘快捷方式（Ctrl+Shift+P）

`Go: Install/Update tools`搜索然后从托盘运行命令

出现提示时，选择所有可用的 Go 工具，然后选择“确定”。

等待 Go 工具完成更新。

## 5.编写示例 Go 程序

在 Visual Studio Code 中，打开 Go 应用程序的根目录。 若要打开文件夹，请在活动栏中选择资源管理器图标，然后选择“ **打开文件夹**”。

在资源管理器面板中选择 **“新建文件夹”**，然后创建您的示例 Go 应用程序的根目录，命名为 `sample-app`。

在资源管理器面板中选择 “新建文件 ”，然后为该文件命名 main.go	

打开终端 “终端 > 新终端”，然后运行以下命令 go mod init sample-app 以初始化示例 Go 应用。	

```
go: creating new go.mod: module sample-app
go: to add module requirements and sums:
        go mod tidy
```

![image-20250812205519928](D:\lmgsanm\03-个人总结\01-学习\Golang\image-20250812205519928.png)

将以下代码复制到 `main.go` 文件中。

```
package main

import "fmt"

func main() {
	name := "Hello World!!"
	fmt.Println("lmgsanm's first go  for", name)
}
```



## 6.运行调试器

单击编号行左侧，在第 7 行上创建断点。 （可选）将光标置于第 7 行并点击 F9。	

在 Visual Studio Code 左侧的活动栏中选择调试图标，打开“调试”视图。 （可选）使用键盘快捷方式（Ctrl+Shift+D）。	

选择 “运行和调试”，或选择 F5 运行调试器。 然后将鼠标悬停在第 7 行上的变量 name 上以查看其值。 单击调试器栏上的 “继续 ”或点击 F5 退出调试器。	

应用程序完成后，应在调试控制台中看到该语句的 fmt.Println() 输出。

![image-20250812205839365](D:\lmgsanm\03-个人总结\01-学习\Golang\image-20250812205839365.png)