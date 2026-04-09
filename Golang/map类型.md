

### 一、map创建和初始化

1、使用make创建

​	map[KeyType]ValueType

```go
package main

import "fmt"

func main() {
	var userinfo = make(map[string]string)
	userinfo["name"] = "张三"
	userinfo["age"] = "20岁"
	userinfo["sex"] = "男"
	fmt.Println(userinfo)         //map[age:20岁 name:张三 sex:男]
	fmt.Println(userinfo["name"]) //张三
}

```

2、声明的时候填充元素

```go
package main

import "fmt"

func main() {
	var userinfo = map[string]string{
		"name": "李四",
		"age":  "30岁",
		"sex":  "女",
	}
	fmt.Println(userinfo)         //map[age:30岁 name:李四 sex:女]
	fmt.Println(userinfo["name"]) //李四
}

```

3、使用类型推导方式

```go
package main

import "fmt"

func main() {
	userinfo := map[string]string{
		"name": "李四",
		"age":  "30岁",
		"sex":  "女",
	}
	fmt.Println(userinfo)         //map[age:30岁 name:李四 sex:女]
	fmt.Println(userinfo["name"]) //李四
}

```

### 二、map的遍历

```go
package main

import "fmt"

func main() {
	userinfo := map[string]string{
		"name": "李四",
		"age":  "30岁",
		"sex":  "女",
	}

	for key, value := range userinfo {
		fmt.Printf("key is %s,value is %s\n", key, value)
	}
	// key is name,value is 李四
	// key is age,value is 30岁
	// key is sex,value is 女
}

```

### 三、map数据的操作

#### 1、判断键值是否存在

```go
package main

import "fmt"

func main() {
	userinfo := map[string]string{
		"name": "李四",
		"age":  "30岁",
		"sex":  "女",
	}
	v, ok := userinfo["name"]
	fmt.Println(v, ok) //李四 true

	v2, ok2 := userinfo["xxx"]
	fmt.Println(v2, ok2) // false
}

```

#### 2、删除数据键值对

​	使用delete()内建函数删除map的键值对

​	delete(map对象，key)，其中：

​	map对象：表示要删除键值对的map对象

​	key：表示要删除键值对的map对象中的键名称

```go
package main

import "fmt"

func main() {
	userinfo := map[string]string{
		"name": "李四",
		"age":  "30岁",
		"sex":  "女",
	}
	fmt.Println(userinfo)	//map[age:30岁 name:李四 sex:女]
	delete(userinfo, "sex")
	fmt.Println(userinfo)	map[age:30岁 name:李四]
}

```

### 四、元素为map类型的切片

```go
package main

import "fmt"

func main() {
	var userinfo = make([]map[string]string, 4, 4)
	if userinfo[0] == nil {
		userinfo[0] = make(map[string]string)
		userinfo[0]["name"] = "张三"
		userinfo[0]["age"] = "20岁"
		userinfo[0]["sex"] = "男"
	}
	if userinfo[1] == nil {
		userinfo[1] = make(map[string]string)
		userinfo[1]["name"] = "李四"
		userinfo[1]["age"] = "28岁"
		userinfo[1]["sex"] = "女"
	}
	if userinfo[2] == nil {
		userinfo[2] = make(map[string]string)
		userinfo[2]["name"] = "王五"
		userinfo[2]["age"] = "30岁"
		userinfo[2]["sex"] = "未知"
	}
	// fmt.Println(userinfo)
	for _, v := range userinfo {
		// fmt.Println(v)
		for key, value := range v {
			fmt.Printf("key:%v,value:%v\n", key, value)
		}
	}
	// 	key:name,value:张三
	// key:age,value:20岁
	// key:sex,value:男
	// key:sex,value:女
	// key:name,value:李四
	// key:age,value:28岁
	// key:name,value:王五
	// key:age,value:30岁
	// key:sex,value:未知
}

```

### 五、值为切片类型的map

```go
package main

import "fmt"

func main() {
	var userinfo = make(map[string][]string)
	userinfo["hobby"] = []string{
		"吃饭",
		"睡觉",
		"打游戏",
	}
	userinfo["work"] = []string{
		"shell",
		"php",
		"golang",
		"python",
	}

	fmt.Println(userinfo) //map[hobby:[吃饭 睡觉 打游戏] work:[shell php golang python]]

}

```

