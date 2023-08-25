# WTF Opcodes极简入门: 6. 位级指令

我最近在重新学以太坊opcodes，也写一个“WTF EVM Opcodes极简入门”，供小白们使用。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/WTFAcademy/WTF-Opcodes](https://github.com/WTFAcademy/WTF-Opcodes)

-----

这一讲，我们将介绍EVM中用于位级运算的8个指令，包括`AND`（与），`OR`（或），和`XOR`（异或）。并且，我们将在用Python写的极简版EVM中添加对他们的支持。

## AND (与)

`AND`指令从堆栈中弹出两个元素，对它们进行位与运算，并将结果推入堆栈。操作码是`0x16`，gas消耗为`3`。

我们将`AND`指令的实现添加到我们的EVM模拟器中：

```python
def and_op(self):
    if len(self.stack) < 2:
        raise Exception('Stack underflow')
    a = self.stack.pop()
    b = self.stack.pop()
    self.stack.append(a & b)
```

我们在`run()`函数中添加对`AND`指令的处理：

```python
def run(self):
    while self.pc < len(self.code):
        op = self.next_instruction()

        # ... 其他指令的处理 ...
        
        elif op == AND:  # 处理AND指令
            self.and_op()
```

现在，我们可以尝试运行一个包含`AND`指令的字节码：`0x6002600316`（PUSH1 2 PUSH1 3 AND）。这个字节码将`2`（0000 0010）和`3`（0000 0011）推入堆栈，然后进行位级与运算，结果应该为`2`（0000 0010）。

```python
code = b"\x60\x02\x60\x03\x16"
evm = EVM(code)
evm.run()
print(evm.stack)
# output: [2]
```

## OR (或)

`OR`指令与`AND`指令类似，但执行的是位或运算。操作码是`0x17`，gas消耗为`3`。

我们将`OR`指令的实现添加到EVM模拟器：

```python
def or_op(self):
    if len(self.stack) < 2:
        raise Exception('Stack underflow')
    a = self.stack.pop()
    b = self.stack.pop()
    self.stack.append(a | b)
```

我们在`run()`函数中添加对`OR`指令的处理：

```python
def run(self):
    while self.pc < len(self.code):
        op = self.next_instruction()

        # ... 其他指令的处理 ...

        elif op == OR:  # 处理OR指令
            self.or_op()
```

现在，我们可以尝试运行一个包含`OR`指令的字节码：`0x6002600317`（PUSH1 2 PUSH1 3 OR）。这个字节码将`2`（0000 0010）和`3`（0000 0011）推入堆栈，然后进行位级与运算，结果应该为`3`（0000 0011）。

```python
code = b"\x60\x02\x60\x03\x17"
evm = EVM(code)
evm.run()
print(evm.stack)
# output: [3]
```

## XOR (异或)

`XOR`指令与`AND`和`OR`指令类似，但执行的是异或运算。操作码是`0x18`，gas消耗为`3`。

我们将`XOR`指令的实现添加到EVM模拟器：

```python
def xor_op(self):
    if len(self.stack) < 2:
        raise Exception('Stack underflow')
    a = self.stack.pop()
    b = self.stack.pop()
    self.stack.append(a ^ b)
```

我们在`run()`函数中添加对`XOR`指令的处理：

```python
def run(self):
    while self.pc < len(self.code):
        op = self.next_instruction()

        # ... 其他指令的处理 ...

        elif op == XOR:  # 处理XOR指令
            self.xor_op()
```

现在，我们可以尝试运行一个包含`XOR`指令的字节码：`0x6002600318`（PUSH1 2 PUSH1 3 XOR）。这个字节码将`2`（0000 0010）和`3`（0000 0011）推入堆栈，然后进行位级与运算，结果应该为`1`（0000 0001）。

```python
code = b"\x60\x02\x60\x03\x18"
evm = EVM(code)
evm.run()
print(evm.stack)
# output: [1]
```

## NOT

`NOT` 指令执行按位非操作，取栈顶元素的补码，然后将结果推回栈顶。它的操作码是`0x19`，gas消耗为`3`。

我们将`NOT`指令的实现添加到EVM模拟器：

```python
def not_op(self):
    if len(self.stack) < 1:
        raise Exception('Stack underflow')
    a = self.stack.pop()
    self.stack.append(~a % (2**256)) # 按位非操作的结果需要模2^256，防止溢出
```

在`run()`函数中添加对`NOT`指令的处理：

```python
elif op == NOT: # 处理NOT指令
    self.not_op()
```

现在，我们可以尝试运行一个包含`NOT`指令的字节码：`0x600219`（PUSH1 2 NOT）。这个字节码将`2`（0000 0010）推入堆栈，然后进行位级非运算，结果应该为`很大的数`（0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd）。

```python
# NOT
code = b"\x60\x02\x19"
evm = EVM(code)
evm.run()
print(evm.stack)
# output: [很大的数] (fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd)
```

## SHL

`SHL`指令执行左移位操作，从堆栈中弹出两个元素，将第二个元素左移第一个元素位数，然后将结果推回栈顶。它的操作码是`0x1B`，gas消耗为`3`。

我们将`SHL`指令的实现添加到EVM模拟器：

```python
def shl(self):
    if len(self.stack) < 2:
        raise Exception('Stack underflow')
    a = self.stack.pop()
    b = self.stack.pop()
    self.stack.append((b << a) % (2**256)) # 左移位操作的结果需要模2^256
```

在`run()`函数中添加对`SHL`指令的处理：

```python
elif op == SHL: # 处理SHL指令
    self.shl()
```

现在，我们可以尝试运行一个包含`XOR`指令的字节码：`0x600260031B`（PUSH1 2 PUSH1 3 SHL）。这个字节码将`2`（0000 0010）和`3`（0000 0011）推入堆栈，然后将`2`左移`3`位，结果应该为`16`（0001 0000）。

```python
code = b"\x60\x02\x60\x03\x1B"
evm = EVM(code)
evm.run()
print(evm.stack)
# output: [16] (0x000000010 << 3 => 0x00010000)
```

## SHR

`SHR`指令执行右移位操作，从堆栈中弹出两个元素，将第二个元素右移第一个元素位数，然后将结果推回栈顶。它的操作码是`0x1C`，gas消耗为`3`。

我们将`SHR`指令的实现添加到EVM模拟器：

```python
def shr(self):
    if len(self.stack) < 2:
        raise Exception('Stack underflow')
    a = self.stack.pop()
    b = self.stack.pop()
    self.stack.append(b >> a) # 右移位操作
```

在`run()`函数中添加对`SHR`指令的处理：

```python
elif op == SHR: # 处理SHR指令
    self.shr()
```

现在，我们可以尝试运行一个包含`XOR`指令的字节码：`0x601060031C`（PUSH1 16 PUSH1 3 SHL）。这个字节码将`16`（0001 0000）和`3`（0000 0011）推入堆栈，然后将`16`右移`3`位，结果应该为`2`（0000 0010）。

```python
code = b"\x60\x10\x60\x03\x1C"
evm = EVM(code)
evm.run()
print(evm.stack)
# output: [2] (0x00010000 >> 3 => 0x000000010)
```

## 其他位级指令

1. **BYTE**: `BYTE`指令从堆栈中弹出两个元素（`a`和`b`），将第二个元素（`b`）看作一个字节数组，并返回该字节数组中第一个元素指定索引的字节（`b[a]`），并压入堆栈。如果索引大于或等于字节数组的长度，则返回`0`。操作码是`0x1a`，gas消耗为`3`。

    ```python
    def byte_op(self):
        if len(self.stack) < 2:
            raise Exception('Stack underflow')
        position = self.stack.pop()
        value = self.stack.pop()
        if position >= 32:
            res = 0
        else:
            res = (value // pow(256, 31 - position)) & 0xFF
        self.stack.append(res)
    ```


2. **SAR**: `SAR`指令执行算术右移位操作，与`SHR`类似，但考虑符号位：如果我们对一个负数进行算术右移，那么在右移的过程中，最左侧（符号位）会被填充`F`以保持数字的负值。它从堆栈中弹出两个元素，将第二个元素以符号位填充的方式右移第一个元素位数，然后将结果推回栈顶。它的操作码是`0x1D`。由于Python的`>>`操作符已经是算术右移，我们可以直接复用`shr`函数的代码。

    ```python
    def sar(self):
        if len(self.stack) < 2:
            raise Exception('Stack underflow')
        a = self.stack.pop()
        b = self.stack.pop()
        self.stack.append(b >> a) # 右移位操作
    ```

## 总结

这一讲，我们介绍了EVM中的8个位级指令，并在极简版EVM中添加了对他们的支持。课后习题: 写出`0x6002600160011B1B`对应的指令形式，并给出运行后的堆栈状态。