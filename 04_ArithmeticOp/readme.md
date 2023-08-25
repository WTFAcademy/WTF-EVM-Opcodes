# WTF Opcodes极简入门: 4. 算数指令

我最近在重新学以太坊opcodes，也写一个“WTF EVM Opcodes极简入门”，供小白们使用。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/WTFAcademy/WTF-Opcodes](https://github.com/WTFAcademy/WTF-Opcodes)

-----

这一讲，我们将介绍EVM中用于基础算术运算的11个指令，包括`ADD`（加法），`MUL`（乘法），`SUB`（减法），和`DIV`（除法）。并且，我们将在用Python写的极简版EVM中添加对他们的支持。

## ADD (加法)

`ADD`指令从堆栈中弹出两个元素，将它们相加，然后将结果推入堆栈。如果堆栈元素不足两个，那么会抛出异常。这个指令的操作码是`0x01`，gas消耗为`3`。

我们可以将`ADD`指令的实现添加到我们的EVM模拟器中：

```python
def add(self):
    if len(self.stack) < 2:
        raise Exception('Stack underflow')
    a = self.stack.pop()
    b = self.stack.pop()
    res = (a + b) % (2**256) # 加法结果需要模2^256，防止溢出
    self.stack.append(res)
```

我们在`run()`函数中添加对`ADD`指令的处理：

```python
def run(self):
    while self.pc < len(self.code):
        op = self.next_instruction()

        if PUSH1 <= op <= PUSH32:
            size = op - PUSH1 + 1
            self.push(size)
        elif op == PUSH0:
            self.stack.append(0)
            self.pc += size
        elif op == POP:
            self.pop()
        elif op == ADD: # 处理ADD指令
            self.add()
```

现在，我们可以尝试运行一个包含`ADD`指令的字节码：`0x6002600301`（PUSH1 2 PUSH1 3 ADD）。这个字节码将`2`和`3`推入堆栈，然后将它们相加。

```python
code = b"\x60\x02\x60\x03\x01"
evm = EVM(code)
evm.run()
print(evm.stack)
# output: [5]
```

## MUL (乘法)

`MUL`指令和`ADD`类似，但是它将堆栈的顶部两个元素相乘。操作码是`0x02`，gas消耗为`5`。

我们将`MUL`指令的实现添加到EVM模拟器：

```python
def mul(self):
    if len(self.stack) < 2:
        raise Exception('Stack underflow')
    a = self.stack.pop()
    b = self.stack.pop()
    res = (a * b) % (2**256) # 乘法结果需要模2^256，防止溢出
    self.stack.append(res)
```

我们在`run()`函数中添加对`MUL`指令的处理：

```python
def run(self):
    while self.pc < len(self.code):
        op = self.next_instruction()

        if PUSH1 <= op <= PUSH32:
            size = op - PUSH1 + 1
            self.push(size)
        elif op == PUSH0:
            self.stack.append(0)
            self.pc += size
        elif op == POP:
            self.pop()
        elif op == ADD:
            self.add()
        elif op == MUL: # 处理MUL指令
            self.mul()
```

现在，我们可以尝试运行一个包含`MUL`指令的字节码：`0x6002600302`（PUSH1 2 PUSH1 3 MUL）。这个字节码将`2`和`3`推入堆栈，然后将它们相乘。

```python
code = b"\x60\x02\x60\x03\x02"
evm = EVM(code)
evm.run()
print(evm.stack)
# output: [6]
```

## SUB (减法)

`SUB`指令从堆栈顶部弹出两个元素，然后计算第二个元素减去第一个元素，最后将结果推入堆栈。这个指令的操作码是`0x03`，gas消耗为`3`。

我们将`SUB`指令的实现添加到EVM模拟器：

```python
def sub(self):
    if len(self.stack) < 2:
        raise Exception('Stack underflow')
    a = self.stack.pop()
    b = self.stack.pop()
    res = (b - a) % (2**256) # 结果需要模2^256，防止溢出
    self.stack.append(res)
```

我们在`run()`函数中添加对`SUB`指令的处理：

```python
def run(self):
    while self.pc < len(self.code):
        op = self.next_instruction()

        if PUSH1 <= op <= PUSH32:
            size = op - PUSH1 + 1
            self.push(size)
        elif op == PUSH0:
            self.stack.append(0)
            self.pc += size
        elif op == POP:
            self.pop()
        elif op == ADD:
            self.add()
        elif op == MUL:
            self.mul()
        elif op == SUB: # 处理SUB指令
            self.sub()
```

现在，我们可以尝试运行一个包含`SUB`指令的字节码：`0x6002600303`（PUSH1 2 PUSH1 3 SUB）。这个字节码将`2`和`3`推入堆栈，然后将它们相减。

```python
code = b"\x60\x03\x60\x02\x03"
evm = EVM(code)
evm.run()
print(evm.stack)
# output: [1]
```

## DIV (除法)

`DIV`指令从堆栈顶部弹出两个元素，然后将第二个元素除以第一个元素，最后将结果推入堆栈。如果第一个元素（除数）为0，则将0推入堆栈。这个指令的操作码是`0x04`，gas消耗为`5`。

我们将`DIV`指令的实现添加到EVM模拟器：

```python
def div(self):
    if len(self.stack) < 2:
        raise Exception('Stack underflow')
    a = self.stack.pop()
    b = self.stack.pop()
    if a == 0:
        res = 0
    else:
        res =  (b // a) % (2**256)
    self.stack.append(res)
```

我们在`run()`函数中添加对`DIV`指令的处理：

```python
def run(self):
    while self.pc < len(self.code):
        op = self.next_instruction()

        if PUSH1 <= op <= PUSH32:
            size = op - PUSH1 + 1
            self.push(size)
        elif op == PUSH0:
            self.stack.append(0)
            self.pc += size
        elif op == POP:
            self.pop()
        elif op == ADD:
            self.add()
        elif op == MUL:
            self.mul()
        elif op == SUB:
            self.sub()
        elif op == DIV: # 处理DIV指令
            self.div()
```

现在，我们可以尝试运行一个包含`DIV`指令的字节码：`0x6002600304`（PUSH1 2 PUSH1 3 DIV）。这个字节码将`2`和`3`推入堆栈，然后将它们相除。

```python
code = b"\x60\x06\x60\x03\x04"
evm = EVM(code)
evm.run()
print(evm.stack)
# output: [2]
```

## 其他算数指令

1. **SDIV**: 带符号整数的除法指令。与`DIV`类似，这个指令会从堆栈中弹出两个元素，然后将第二个元素除以第一个元素，结果带有符号。如果第一个元素（除数）为0，结果为0。它的操作码是`0x05`，gas消耗为5。要注意，EVM字节码中的负数是用二进制补码（two’s complement）形式，比如`-1`表示为`0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff`，它加一等于0。

    ```python
    def sdiv(self):
        if len(self.stack) < 2:
            raise Exception('Stack underflow')
        a = self.stack.pop()
        b = self.stack.pop()
        res = b//a % (2**256) if a!=0 else 0
        self.stack.append(res)
    ```

2. **MOD**: 取模指令。这个指令会从堆栈中弹出两个元素，然后将第二个元素除以第一个元素的余数推入堆栈。如果第一个元素（除数）为0，结果为0。它的操作码是`0x06`，gas消耗为5。

    ```python
    def mod(self):
        if len(self.stack) < 2:
            raise Exception('Stack underflow')
        a = self.stack.pop()
        b = self.stack.pop()
        res = b % a if a != 0 else 0
        self.stack.append(res)
    ```

3. **SMOD**: 带符号的取模指令。这个指令会从堆栈中弹出两个元素，然后将第二个元素除以第一个元素的余数推入堆栈，结果带有第二个元素的符号。如果第一个元素（除数）为0，结果为0。它的操作码是`0x07`，gas消耗为5。

    ```python
    def smod(self):
        if len(self.stack) < 2:
            raise Exception('Stack underflow')
        a = self.stack.pop()
        b = self.stack.pop()
        res = b % a if a != 0 else 0
        self.stack.append(res)
    ```

4. **ADDMOD**: 模加法指令。这个指令会从堆栈中弹出三个元素，将前两个元素相加，然后对第三个元素取模，将结果推入堆栈。如果第三个元素（模数）为0，结果为0。它的操作码是`0x08`，gas消耗为8。

    ```python
    def addmod(self):
        if len(self.stack) < 3:
            raise Exception('Stack underflow')
        a = self.stack.pop()
        b = self.stack.pop()
        n = self.stack.pop()
        res = (a + b) % n if n != 0 else 0
        self.stack.append(res)
    ```

5. **MULMOD**: 模乘法指令。这个指令会从堆栈中弹出三个元素，将前两个元素相乘，然后对第三个元素取模，将结果推入堆栈。如果第三个元素（模数）为0，结果为0。它的操作码是`0x09`，gas消耗为5。

    ```python
    def mulmod(self):
        if len(self.stack) < 3:
            raise Exception('Stack underflow')
        a = self.stack.pop()
        b = self.stack.pop()
        n = self.stack.pop()
        res = (a * b) % n if n != 0 else 0
        self.stack.append(res)
    ```

6. **EXP**: 指数运算指令。这个指令会从堆栈中弹出两个元素，将第二个元素作为底数，第一个元素作为指数，进行指数运算，然后将结果推入堆栈。它的操作码是`0x0A`，gas消耗为10。

    ```python
    def exp(self):
        if len(self.stack) < 2:
            raise Exception('Stack underflow')
        a = self.stack.pop()
        b = self.stack.pop()
        res = pow(b, a) % (2**256)
        self.stack.append(res)
    ```

7. **SIGNEXTEND**: 符号位扩展指令，即在保留数字的符号（正负性）及数值的情况下，增加二进制数字位数的操作。举个例子，若计算机使用8位二进制数表示数字“0000 1010”，且此数字需要将字长符号扩充至16位，则扩充后的值为“0000 0000 0000 1010”。此时，数值与符号均保留了下来。`SIGNEXTEND`指令会从堆栈中弹出两个元素，对第二个元素进行符号扩展，扩展的位数由第一个元素决定，然后将结果推入堆栈。它的操作码是`0x0B`，gas消耗为5。

    ```python
    def signextend(self):
        if len(self.stack) < 2:
            raise Exception('Stack underflow')
        b = self.stack.pop()
        x = self.stack.pop()
        if b < 32: # 如果b>=32，则不需要扩展
            sign_bit = 1 << (8 * b - 1) # b 字节的最高位（符号位）对应的掩码值，将用来检测 x 的符号位是否为1
            x = x & ((1 << (8 * b)) - 1)  # 对 x 进行掩码操作，保留 x 的前 b+1 字节的值，其余字节全部置0
            if x & sign_bit:  # 检查 x 的符号位是否为1
                x = x | ~((1 << (8 * b)) - 1)  # 将 x 的剩余部分全部置1
        self.stack.append(x)
    ```

## 总结

这一讲，我们介绍了EVM中的11个算数指令，并在极简版EVM中添加了对他们的支持。课后习题: 写出`0x60036004600209`对应的指令形式，并给出运行后的堆栈状态。