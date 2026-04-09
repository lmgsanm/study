  

## JSON 解析为结构体

JSON 的结构是 key-value，最直观的就是将 JSON 解析为结构体，如下 JSON 

```
{
  "name": yuzhou1u,
  "age": 18
}
```

Go 语言中，提供了一个专门的包 `encoding/json` ，所以我们在使用这个 JSON 包之前需要在头文件导入：

```
package main
 
import (
	 "encoding/json"
  "fmt"
)

```

然后，我们需要定义一个 Go 语言的结构体以便我们能与 JSON 一一对应，比如在 JSON 中我们定义了姓名 `name` 和年龄 `age` ，所以需要定义一个结构体（命名可以随意，但最好通俗易懂）的字段与 JSON 字符串中的键相匹配

```
type Person struct {
  Name string
  Age int
}
```

然后使用 `json.Umarshal()` 函数来解析 JSON 字符串，完整代码如下：

```
package main

import (
	"encoding/json"
	"fmt"
)

type Person struct {
	Name string
	Age  int
}

func main() {
	var p Person
	jsonString := `{"name": "yuzhou1su",
	"age" : 18}`
	err := json.Unmarshal([]byte(jsonString), &p)
	if err == nil {
		fmt.Println(p.Name)
		fmt.Println(p.Age)
	} else {
		fmt.Println(err)
	}
}
```

现在来解释一下上面 main 函数的代码：

- 定义一个 Person 的 p 对象
- 因为我们没有把文件系统使用上，所以是定义了一个 `jsonString` 的 JSON 数据
- 使用 `json.Unmarshal()` 函数能够解析 JSON 格式的数据。但需要将 JSON 字符串转换为字节切片，并将结果存储到 p 对象中。 使用需要使用 & 地址运算符传入人员的地址。
- 如果解析有效，则 `json.Unmarshal()` 函数返回 nil，您现在可以找到存储在 person 变量中的值。
- 确保将 Person 结构中每个字段的第一个字符大写。 如果字段名称以小写字母开头，则不会导出到当前包之外，并且字段对 `json.Unmarshal()` 函数不可见。

运行上述代码，打印在控制台中结果为：

```
yuzhou1su
18
```

## JSON 解析为数组

通常 JSON 数据会包括一系列的对象数组，就像这样一个班级的数据：

```
[
  {
    "id": 1,
    "name": "张三"
    "age": 20
  },
  {
    "id": 2,
    "name": "李翠花"
    "age": 18
  },
  {
    "id": 3,
    "name": "王老五"
    "age": 25
  }
]
```

我们只需要定义一个 `students[]` 的数组，代码如下：

```
package main

import (
	"encoding/json"
	"fmt"
)

type Student struct {
	Id   int
	Name string
	Age  int
}

func main() {
	var students []Student
	myInfo := `[
		{
		  "id": 1,
		  "name": "张三",
		  "age": 20
		},
		{
		  "id": 2,
		  "name": "李翠花",
		  "age": 18
		},
		{
		  "id": 3,
		  "name": "王老五",
		  "age": 25
		}
	]`
	err := json.Unmarshal([]byte(myInfo), &students)
	if err == nil {
		for _, student := range students {
			fmt.Print("\t\n", student.Id)
			fmt.Print("\t", student.Name)
			fmt.Print("\t", student.Age)
		}
	} else {
		fmt.Println(err)
	}
}

```

使用 `for...range` 迭代数组，然后运行上述代码，结果如下：

```
	
1	张三	20	
2	李翠花	18	
3	王老五	25
```

## 解析 JSON 嵌入对象

JSON 字符串有时包含嵌入对象，比如：

```
{
  "name": "yuzhou1su",
  "age": 18,
  "address": {
    "road": "renmin south road",
    "street": "123 street",
    "city": "cs",
    "province": "hn",
    "country": "cn"
  }
}
```

`address` 就是属于内嵌对象，我们同样需要创建另一个 `Address` 结构体：

```
package main

import (
	"encoding/json"
	"fmt"
)

type Person struct {
	Name    string
	Age     int
	Address struct {
		Road     string
		Street   string
		City     string
		Province string
		Country  string
	}
}

func main() {
	var p Person
	jsonString := `{
		"name": "yuzhou1su",
		"age": 18,
		"address": {
		  "road": "renmin south road",
		  "street": "123 street",
		  "city": "cs",
		  "province": "hn",
		  "country": "cn"
		}
	  }`
	err := json.Unmarshal([]byte(jsonString), &p)
	if err == nil {
		fmt.Printf("p.Name: %v\n", p.Name)
		fmt.Printf("p.Age: %v\n", p.Age)
		fmt.Printf("p.Address.City: %v\n", p.Address.City)
		fmt.Printf("p.Address.Road: %v\n", p.Address.Road)
		fmt.Printf("p.Address.Street: %v\n", p.Address.Street)
		fmt.Printf("p.Address.Province: %v\n", p.Address.Province)
		fmt.Printf("p.Address.Country: %v\n", p.Address.Country)
	} else {
		fmt.Printf("err: %v\n", err)
	}
}

```

运行结果如下：

```
p.Name: yuzhou1su
p.Age: 18
p.Address.City: cs
p.Address.Road: renmin south road
p.Address.Street: 123 street
p.Address.Province: hn
p.Address.Country: cn
```

## 自定义属性名称的映射

有时 JSON 字符串中的键不能直接映射到 Go 中结构的成员。 比如：

```
{
  "base currency": "USD",
  "destination currency": "CNY"
}
```

请注意，此 JSON 字符串中的键中有空格。 如果你尝试将它直接映射到一个结构，你会遇到问题，因为 Go 中的变量名不能有空格。 要解决此问题，您可以使用结构字段标记（在结构中的每个字段之后放置的字符串文字），如下所示

```
type Rates stuct {
  Base string `json:"base currency"`
  Symbol string `json:"destination currency"`
}
```

- JSON 的 `base currency` 映射到 Go 中的 `Base` 字段
- JSON 的 `destination currency` 映射到 Go 中 `Symbol`

```
package main

import (
	"encoding/json"
	"fmt"
)

type Rates struct {
	Base   string `json:"base currency"`
	Symbol string `json:"destination currency"`
}

func main() {
	var rates Rates

	myJsonString := `{
		"base currency": "USD",
		"destination currency": "CNY"
	  }`
	err := json.Unmarshal([]byte(myJsonString), &rates)
	if err == nil {
		fmt.Println(rates.Base)
		fmt.Println(rates.Symbol)
	} else {
		fmt.Println(err)
	}
}

```

运行结果如下：

```
USD
CNY
```

## 非结构化数据的映射

前面几节展示了相对简单的 JSON 字符串。 然而，在现实世界中，您要操作的 JSON 字符串通常很大且非结构化。 此外，您可能只需要从 JSON 字符串中检索特定值。

考虑以下 JSON 字符串：

```
{
    "success": true,
    "timestamp": 1588779306,
    "base": "USD",
    "date": "2022-01-15",
    "rates": {
        "BNB": 0.00225,
        "BTC": 0.000020,
        "EUR": 0.879,
        "GBP": 0.733,
        "CNY": 6.36
    } 
}
```

如果我们还想把美元解析为其他币种，不至于重新定义整个结构体，可以采取定义一个接口：

```
var result map[string] interface{}
```

上面的语句创建了一个 map 类型的变量 result，它的 key 是 string 类型，每个对应的 value 都是 interface{} 类型。 这个空接口表示该值可以是任何类型:

为了解析这个 JSON 字符串，我们应该使用 `json.Unmarshal()` 函数：

```
json.Unmarshal([]byte(jsonString), &result)
```

因为 result 的类型是接口，所有可以传入任何类型：

- 当解析 success 键的话可以使用 `result["sucess"]`，解析为布尔型。
- 当解析 `timestamp` 时可以解析为数字类型
- 解析 rates 使用传入 `rates` 即可, 即 `rates := result["rates"]`，解析为 map 类型

```
package main

import (
	"encoding/json"
	"fmt"
)

type Rates struct {
	Base   string `json:"base currency"`
	Symbol string `json:"destination currency"`
}

func main() {

	myJsonString := `{
		"success": true,
		"timestamp": 1588779306,
		"base": "USD",
		"date": "2022-01-15",
		"rates": {
			"BNB": 0.00225,
			"BTC": 0.000020,
			"EUR": 0.879,
			"GBP": 0.733,
			"CNY": 6.36
	  } 
	}`

	var result map[string]interface{}

	err := json.Unmarshal([]byte(myJsonString), &result)

	if err == nil {
		fmt.Println(result["success"])
		fmt.Println(result["timestamp"])
		fmt.Println(result["base"])
		fmt.Println(result["date"])
		Rates := result["rates"]
		fmt.Println(Rates)
	} else {
		fmt.Println(err)
	}
}
```

运行结果如下：

```
true
1.588779306e+09
USD
2022-01-15
map[BNB:0.00225 BTC:2e-05 CNY:6.36 EUR:0.879 GBP:0.733]
```

JSON 数据作为常见的数据格式，有着非常多的使用场景。本篇文章介绍了如何利用 Go 语言来解析 JSON 数据，如解析为结构体、数组、嵌入对象，解析自定义字段和解析非结构化数据。

## 反序列化成map

示例

```
package main

import (
	"encoding/json"
	"fmt"
)

func main() {
	myJsonString := `{
		"userName":"admin",
		"nick_name":"管理员",
		"info":{
		   "age":18
		},
		"extra":[
		   {
			  "address":"上海市"
		   },
		   {
			  "address":"北京市"
		   }
		]
	 }`
	anyMap := make(map[string]interface{}, 0)
	err := json.Unmarshal([]byte(myJsonString), &anyMap)
	if err == nil {
		fmt.Println(anyMap["userName"])
		fmt.Println(anyMap["nick_name"])
		fmt.Println(anyMap["info"])
		fmt.Println(anyMap["extra"])
	} else {
		fmt.Println(err)
	}
}
```

运行结果：

```
admin
管理员
map[age:18]
[map[address:上海市] map[address:北京市]]
```

