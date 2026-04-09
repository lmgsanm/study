

### 示例

#### 代码

```
package main

import (
	"fmt"
)

func sum(a ...int) int {
	total := 0
	for _, num := range a {
		total += num
	}
	return total
}
func main() {
	fmt.Println(sum(1))
	fmt.Println(sum(5))
	fmt.Println(sum(1, 2, 3, 4, 5))
	fmt.Println(sum(0))
	vars := []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
	fmt.Println(sum(vars...))

}
```

#### 结果

```
1
5
15
0
55
```

