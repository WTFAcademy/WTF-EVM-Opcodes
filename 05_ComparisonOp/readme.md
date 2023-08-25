# WTF Opcodes极简入门: 5. 比较指令

我最近在重新学以太坊opcodes，也写一个“WTF EVM Opcodes极简入门”，供小白们使用。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/WTFAcademy/WTF-Opcodes](https://github.com/WTFAcademy/WTF-Opcodes)

-----

这一讲，我们将介绍EVM中用于比较运算的6个指令，包括`LT`（小于），`GT`（大于），和`EQ`（相等）。并且，我们将在用Python写的极简版EVM中添加对他们的支持。

## LT (小于)

`LT`指令从堆栈中弹出两个元素，比较第二个元素是否小于第一个元素。如果是，那么将`1`推入堆栈，否则将`0`推入堆栈。如果堆栈元素不足两个，那么会抛出异常。这个指令的操作码是`0x10`，gas消耗为`3`。

我们可以将`LT`指令的实现添加到我们的极简EVM中：

```python
def lt(self):
    if len(self.stack) < 2:
        raise Exception('Stack underflow')
    a = self.stack.pop()
    b = self.stack.pop()
    self.stack.append(int(b < a)) # 注意这里的比较顺序
```

我们在`run()`函数中添加对`LT`指令的处理：

```python
def run(self):
    while self.pc < len(self.code):
        op = self.next_instruction()

        # ... 其他指令的处理 ...

        elif op == LT: # 处理LT指令
            self.lt()
```

现在，我们可以尝试运行一个包含`LT`指令的字节码：`0x6002600310`（PUSH1 2 PUSH1 3 LT）。这个字节码将`2`和`3`推入堆栈，然后比较`2`是否小于`3`。

```python
code = b"\x60\x02\x60\x03\x10"
evm = EVM(code)
evm.run()
print(evm.stack)
# output: [1]
```

## GT (大于)

`GT`指令和`LT`指令非常类似，不过它比较的是第二个元素是否大于第一个元素。操作码是`0x11`，gas消耗为`3`。

我们将`GT`指令的实现添加到极简EVM：

```python
def gt(self):
    if len(self.stack) < 2:
        raise Exception('Stack underflow')
    a = self.stack.pop()
    b = self.stack.pop()
    self.stack.append(int(b > a)) # 注意这里的比较顺序
```

我们在`run()`函数中添加对`GT`指令的处理：

```python
def run(self):
    while self.pc < len(self.code):
        op = self.next_instruction()

        # ... 其他指令的处理 ...

        elif op == GT: # 处理GT指令
            self.gt()
```

现在，我们可以运行一个包含`GT`指令的字节码：`0x6002600311`（PUSH1 2 PUSH1 3 GT）。这个字节码将`2`和`3`推入堆栈，然后比较`2`是否大于`3`。

```python
code = b"\x60\x02\x60\x03\x11"
evm = EVM(code)
evm.run()
print(evm.stack)
# output: [0]
```

## EQ (等于)

`EQ`指令从堆栈中弹出两个元素，如果两个元素相等，那么将`1`推入堆栈，否则将`0`推入堆栈。该指令的操作码是`0x14`，gas消耗为`3`。

我们将`EQ`指令的实现添加到极简EVM：

```python
def eq(self):
    if len(self.stack) < 2:
        raise Exception('Stack underflow')
    a = self.stack.pop()
    b = self.stack.pop()
    self.stack.append(int(a == b))
```

我们在`run()`函数中添加对`EQ`指令的处理：

```python
elif op == EQ: 
    self.eq()
```

现在，我们可以运行一个包含`EQ`指令的字节码：`0x6002600314`（PUSH1 2 PUSH1 3 EQ）。这个字节码将`2`和`3`推入堆栈，然后比较两者是否相等。

```python
code = b"\x60\x02\x60\x03\x14"
evm = EVM(code)
evm.run()
print(evm.stack)
# output: [0]
```

## ISZERO (是否为零)

`ISZERO`指令从堆栈中弹出一个元素，如果元素为0，那么将`1`推入堆栈，否则将`0`推入堆栈。该指令的操作码是`0x15`，gas消耗为`3`。

我们将`ISZERO`指令的实现添加到极简EVM：

```python
def iszero(self):
    if len(self.stack) < 1:
        raise Exception('Stack underflow')
    a = self.stack.pop()
    self.stack.append(int(a == 0))
```

我们在`run()`函数中添加对`ISZERO`指令的处理：

```python
elif op == ISZERO: 
    self.iszero()
```

现在，我们可以运行一个包含`ISZERO`指令的字节码：`0x600015`（PUSH1 0 ISZERO）。这个字节码将`0`推入堆栈，然后检查其是否为0。

```python
code = b"\x60\x00\x15"
evm = EVM(code)
evm.run()
print(evm.stack)
# output: [1]
```

## 其他比较指令

1. **SLT (有符号小于)**: 这个指令会从堆栈中弹出两个元素，然后比较第二个元素是否小于第一个元素，结果以有符号整数形式返回。如果第二个元素小于第一个元素，将`1`推入堆栈，否则将`0`推入堆栈。它的操作码是`0x12`，gas消耗为`3`。

    ```python
    def slt(self):
        if len(self.stack) < 2:
            raise Exception('Stack underflow')
        a = self.stack.pop()
        b = self.stack.pop()
        self.stack.append(int(b < a)) # 极简evm stack中的值已经是以有符号整数存储了，所以和lt一样实现
    ```

2. **SGT (有符号大于)**: 这个指令会从堆栈中弹出两个元素，然后比较第二个元素是否大于第一个元素，结果以有符号整数形式返回。如果第二个元素大于第一个元素，将`1`推入堆栈，否则将`0`推入堆栈。它的操作码是`0x13`，gas消耗为`3`。

    ```python
    def sgt(self):
        if len(self.stack) < 2:
            raise Exception('Stack underflow')
        a = self.stack.pop()
        b = self.stack.pop()
        self.stack.append(int(b > a)) # 极简evm stack中的值已经是以有符号整数存储了，所以和gt一样实现
    ```

## 总结

这一讲，我们介绍了EVM中的6个比较指令，并在极简版EVM中添加了对他们的支持。课后习题: 写出`0x6003600414`对应的指令形式，并给出运行后的堆栈状态。