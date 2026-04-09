iota 是 Go 语言的一个保留字，用作常量计数器。由于 iota 具有自增特性，所以可以简化数字增长的常量定义。

iota 是一个具有魔法的关键字，往往令初学者难以理解其原理和使用方法。

本文会从书写方法、使用场景、实现原理以及优缺点等各方面剖析 iota 关键字。 

## 1. 书写方法

正确写法：

```
const (
  FirstItem = iota
  SecondItem
  ThirdItem
)
// 或者
const SingleItem = iota
```

错误写法：

```
var FirstItem = iota
// 或者
println(iota)
```

**iota 只能用于常量表达式，而且必须在 const 代码块中出现，不允许出现在其它位置。**

 

## 2. 使用场景

iota 的主要使用场景用于枚举。Go 语言的设计原则追求极尽简化，所以没有枚举类型，没有 enum关键字。

Go 语言通常使用常量定义代替枚举类型，于是 iota 常常用于其中，用于简化代码。

例如：

```
package main

const (
  B  = 1 << (10 * iota) // 1 << (10*0)
  KB                    // 1 << (10*1)
  MB                    // 1 << (10*2)
  GB                    // 1 << (10*3)
  TB                    // 1 << (10*4)
  PB                    // 1 << (10*5)
  EB                    // 1 << (10*6)
  ZB                    // 7 << (10*5)
)

func main() {
  println(B, KB, MB, GB, TB)
}
```

输出结果：

```
1 1024 1048576 1073741824
```

我们也可以直接这样书写这段代码：

```
  const (
    B  = 1
    KB = 1024
    MB = 1048576
    GB = 1073741824
    ...
  )
```

两段代码对比来看，使用 iota 的代码显然简洁优雅很多。不使用 iota 的代码，对于代码洁癖者来说，简直就是一坨，不可接受。

而 Go 语言的发明者，恰恰具有代码洁癖，而且还是深度洁癖。Go 语言设计初衷之一：追求简洁优雅。 

## 3. iota 原理

iota 源码在 Go 语言代码库中，只有一句定义语句，位于内建文件 go/src/builtin/builtin.go 中：

```
const iota = 0 // Untyped int.
```

iota 是一个预声明的标识符，它的值是 0。 在 const 常量声明中，作为当前 const 代码块中的整数序数。

从 Go 语言代码库的代码看，iota 只是一个简单的整数 0，为什么能够作为常量计数器，进行常量自增呢？它的源码到底在哪里？

我们做一个小试验，就会理解其中的道理，看一段代码：

```
package main

const (
  FirstItem = iota
  SecondItem
  ThirdItem
)

func main() {
  println(FirstItem)
  println(SecondItem)
  println(ThirdItem)
}
```

非常简单，就是打印 FirstItem，SecondItem，ThirdItem。

编译上述代码：

```
go tool compile -N -l main.go
```

使用 -N -l 编译参数用于禁止内联和优化，防止编译器优化和简化代码，弄乱次序。这样便于阅读汇编代码。

导出汇编代码：

```
go tool objdump main.o
```

截取部分结果如下：

```
TEXT %22%22.main(SB) gofile../Users/wangzebin/test/test/main.go
...
main.go:10    MOVQ $0x0, 0(SP)  // 对应源码 println(FirstItem)
main.go:10    CALL 0x33b [1:5]R_CALL:runtime.printint
...
main.go:11    MOVQ $0x1, 0(SP)  // 对应源码 println(SecondItem)
main.go:11    CALL 0x357 [1:5]R_CALL:runtime.printint
...
main.go:11    MOVQ $0x2, 0(SP)  // 对应源码 println(ThirdItem)
main.go:11    CALL 0x373 [1:5]R_CALL:runtime.printint
...
```

编译之后，对应的常量 FirstItem、SecondItem 和 ThirdItem，分别替换为$0x0、$0x1 和 $0x2。

这说明：Go代码中定义的常量，在编译时期就会被替换为对应的常量。当然 iota，也不可避免地在编译时期，按照一定的规则，被替换为对应的常量。

所以，Go 语言源码库中是不会有 iota 源码了，它的魔法在编译时期就已经施展完毕。也就是说，解释 iota 的代码包含在 go 这个命令和其调用的组件中。

如果你要阅读它的源码，准确的说，阅读处理 iota 关键字的源码，需要到 Go 工具源码库中寻找，而不是 Go 核心源码库。

 

## 4. iota 规则

使用 iota，虽然可以书写简洁优雅的代码，但对于不熟悉规则的人来讲，又带来的很多不必要的麻烦和误解。

对于引入 iota，到底好是不好，每个人都有自己的评价。实际上，有些不常用的写法，甚至有些卖弄编写技巧的的写法，并不是设计者的初衷。

大多数情况下，我们还是使用最简单最明确的写法，iota 只是提供了一种选择而已。一个工具使用的好坏，取决于使用它的人，而不是工具本身。

以下是 iota 编译规则：

### 1) 依赖 const

iota 依赖于 const 关键字，每次新的 const 关键字出现时，都会让 iota 初始化为0。

```
const a = iota // a=0
const (
  b = iota     // b=0
  c            // c=1
)
```

### 2) 按行计数

iota 按行递增加 1。

```
const (
  a = iota     // a=0
  b            // b=1
  c            // c=2
)
```

### 3) 多个iota

同一 const 块出现多个 iota，只会按照行数计数，不会重新计数。

```
  const (
    a = iota     // a=0
    b = iota     // b=1
    c = iota     // c=2
  )
```

与上面的代码完全等同，b 和 c 的 iota 通常不需要写。

### 4) 空行处理

空行在编译时期首先会被删除，所以空行不计数。

```
  const (
    a = iota     // a=0


    b            // b=1
    c            // c=2
  )
```

### 5) 跳值占位

占位 "_"，它不是空行，会进行计数，起到跳值作用。

```
  const (
    a = iota     // a=0
    _            // _=1
    c            // c=2
  )
```

### 6) 开头插队

开头插队会进行计数。

```
const (
    i = 3.14 // i=3.14
    j = iota // j=1
    k = iota // k=2
    l        // l=3
)
```

### 7) 中间插队

中间插队会进行计数。

```
const (
    i = iota // i=0
    j = 3.14 // j=3.14
    k = iota // k=2
    l        // l=3
)
```

### 8) 一行多个iota

一行多个iota，分别计数。

```
const (
    i, j = iota, iota // i=0,j=0
    k, l              // k=1,l=1
)
```