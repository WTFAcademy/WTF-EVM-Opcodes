# WTF Opcodes极简入门: 9. 控制流指令

我最近在重新学以太坊opcodes，也写一个“WTF EVM Opcodes极简入门”，供小白们使用。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/WTFAcademy/WTF-Opcodes](https://github.com/WTFAcademy/WTF-Opcodes)

-----

在这一讲，我们将介绍EVM中用于控制流的5个指令，包括`STOP`，`JUMP`，`JUMPI`，`JUMPDEST`，和`PC`。我们将在用Python写的极简版EVM中添加对这些操作的支持。

## EVM中的控制流

我们在[第三讲](https://github.com/WTFAcademy/WTF-Opcodes/blob/main/03_StackOp/readme.md)介绍了程序计数器（Program Counter，PC），而EVM的控制流是由跳转指令（`JUMP`，`JUMPI`，`JUMPDEST`）控制PC指向新的指令位置而实现的，这允许合约进行条件执行和循环执行。

## STOP（停止）

`STOP`是EVM的停止指令，它的作用是停止当前上下文的执行，并成功退出。它的操作码是`0x00`，gas消耗为0。

将`STOP`操作作码设为`0x00`有一个好处：当一个调用被执行到一个没有代码的地址（EOA），并且EVM尝试读取代码数据时，系统会返回一个默认值0，这个默认值对应的就是`STOP`指令，程序就会停止执行。

下面，让我们在`run()`函数中添加对`STOP`指令的处理：

```python
def run(self):
    while self.pc < len(self.code):
        op = self.next_instruction()

        # ... 其他指令的处理 ...

        elif op == STOP: # 处理STOP指令
            print('Program has been stopped')
            break # 停止执行
```

现在，我们可以尝试运行一个包含`STOP`指令的字节码：

```python
# STOP
code = b"\x00"
evm = EVM(code)
evm.run()
# output: Program has been stopped
```

## JUMPDEST（跳转目标）

`JUMPDEST`指令标记一个有效的跳转目标位置，不然无法使用`JUMP`和`JUMPI`进行跳转。它的操作码是`0x5b`，gas消耗为1。

但是`0x5b`有时会作为`PUSH`的参数（详情可看[黄皮书](https://ethereum.github.io/yellowpaper/paper.pdf)中的9.4.3. Jump Destination Validity），所以需要在运行代码前，筛选字节码中有效的`JUMPDEST`指令，使用`ValidJumpDest` 来存储有效的`JUMPDEST`指令所在位置。

```python
def findValidJumpDestinations(self):
    pc = 0

    while pc < len(self.code):
        op = self.code[pc]
        if op == JUMPDEST:
            self.validJumpDest[pc] = True
        elif op >= PUSH1 and op <= PUSH32:
            pc += op - PUSH1 + 1
        pc += 1
```

```python
def jumpdest(self):
    pass
```

## JUMP（跳转）

`JUMP`指令用于无条件跳转到一个新的程序计数器位置。它从堆栈中弹出一个元素，将这个元素设定为新的程序计数器（`pc`）的值。操作码是`0x56`，gas消耗为8。

```python
def jump(self):
    if len(self.stack) < 1:
        raise Exception('Stack underflow')
    destination = self.stack.pop()
    if destination not in self.validJumpDest:
        raise Exception('Invalid jump destination')
    else:  self.pc = destination
```

我们在`run()`函数中添加对`JUMP`和`JUMPDEST`指令的处理：

```python
elif op == JUMP: 
    self.jump()
elif op == JUMPDEST: 
    self.jumpdest()
```

现在，我们可以尝试运行一个包含`JUMP`和`JUMPDEST`指令的字节码：`0x600456005B`（PUSH1 4 JUMP STOP JUMPDEST）。这段字节码将`4`推入堆栈，然后进行`JUMP`，跳转到`pc = 4`的位置，该位置正好是`JUMPDEST`指令，跳转成功，程序没有被`STOP`指令中断。

```python
# JUMP
code = b"\x60\x04\x56\x00\x5b"
evm = EVM(code)
evm.run()
print(evm.pc)  
# output: 5
```

## JUMPI（条件跳转）

`JUMPI`指令用于条件跳转，它从堆栈中弹出两个元素，如果第二个元素（条件，`condition`）不为0，那么将第一个元素（目标，`destination`）设定为新的`pc`的值。操作码是`0x57`，gas消耗为10。

```python
def jumpi(self):
    if len(self.stack) < 2:
        raise Exception('Stack underflow')
    destination = self.stack.pop()
    condition = self.stack.pop()
    if condition != 0:
        if destination not in self.validJumpDest:
            raise Exception('Invalid jump destination')
        else:  self.pc = destination
```

我们在`run()`函数中添加对`JUMPI`指令的处理：

```python
elif op == JUMPI: 
    self.jumpi()
```

现在，我们可以尝试运行一个包含`JUMPI`和`JUMPDEST`指令的字节码：`0x6001600657005B`（PUSH1 01 PUSH1 6 JUMPI STOP JUMPDEST）。这个字节码将`1`和`6`推入堆栈，然后进行`JUMPI`，由于条件不为`0`，执行跳转到`pc = 6`的位置，该位置正好是`JUMPDEST`指令，跳转成功，程序没有被`STOP`指令中断。

```python
# JUMPI
code = b"\x60\x01\x60\x06\x57\x00\x5b"
evm = EVM(code)
evm.run()
print(evm.pc)  
# output: 7 程序没有被中断
```

## PC（程序计数器）

`PC`指令将当前的程序计数器（`pc`）的值压入堆栈。操作码为`0x58`，gas消耗为2。

```python
def pc(self):
    self.stack.append(self.pc)
```

## 总结

这一讲，我们介绍了EVM中的控制流程指令，并在极简版EVM中添加了对它们的支持。这些操作为合约提供了控制流程的能力，为编写更复杂的合约逻辑提供了可能。

课后习题: 写出`0x5F600557005B`对应的指令形式，并给出运行后的堆栈和程序计数器状态。
