# WTF Opcodes极简入门: 15. Log指令

我最近在重新学以太坊opcodes，也写一个“WTF EVM Opcodes极简入门”，供小白们使用。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/WTFAcademy/WTF-Opcodes](https://github.com/WTFAcademy/WTF-Opcodes)

-----

这一讲，我们将介绍EVM中与日志（Log）相关的5个指令：：从`LOG0`到`LOG4`。日志是EVM中一个重要的概念，用于记录与合约交互的重要信息，是智能合约中事件（Event）的基础。这些记录永久保存在在区块链上，方便检索，但不会影响区块链的状态，是DApps和智能合约开发者的一个强大工具。


## EVM中的日志和事件

在Solidity中，我们常常使用`event`来定义和触发事件。当这些事件被触发时，它们会生成日志，将数据永久存储在区块链上。日志分为主题（`topic`）和数据（`data`）。第一个主题通常是事件签名的哈希值，后面的主题是由`indexed`修饰的事件参数。如果你对`event`不了解，推荐阅读WTF Solidity的[相应章节](https://github.com/AmazingAng/WTF-Solidity/tree/main/12_Event)。

EVM中的`LOG`指令用于创建这些日志。指令`LOG0`到`LOG4`的区别在于它们包含的主题数量。例如，`LOG0`没有主题，而`LOG4`有四个主题。

为了在我们的极简EVM中支持日志功能，我们首先需要定义一个`Log`类来表示一个日志条目，他会记录发出日志的合约地址`address`，数据部分`data`，和主体部分`topics`：

```python
class Log:
    def __init__(self, address, data, topics=[]):
        self.address = address
        self.data = data
        self.topics = topics

    def __str__(self):
        return f'Log(address={self.address}, data={self.data}, topics={self.topics})'
```

然后，我们需要在EVM的初始化函数中增加一个`logs`列表，记录这些日志：

```python
class EVM:
    def __init__(self, code, txn = None):
        
        # ... 初始化其他变量 ...

        self.logs = []
```

## LOG指令

EVM中有五个`Log`指令：`LOG0`、`LOG1`、`LOG2`、`LOG3`和`LOG4`。它们的主要区别在于携带的主题数（`topics`）：`LOG0`没有主题，而`LOG4`有四个。操作码从`A0`到`A4`，gas消耗由以下公式计算:

```python
gas = 375 + 375 * topic数量 + 内存扩展成本
```

`Log`指令从堆栈中弹出2 + n的元素。其中前两个参数是内存开始位置`mem_offset`和数据长度`length`，n是主题的数量（取决于具体的`LOG`指令）。所以对于`LOG1`，我们会从堆栈中弹出3个元素：内存开始位置，数据长度，和一个主题。需要`mem_offset`的原因是日志的数据（`data`）部分存储在内存中，gas消耗低，而主题（`topic`）部分直接存储在堆栈上。

接下来，我们实现`LOG`指令：

```python
def log(self, num_topics):
    if len(self.stack) < 2 + num_topics:
        raise Exception('Stack underflow')

    mem_offset = self.stack.pop()
    length = self.stack.pop()
    topics = [self.stack.pop() for _ in range(num_topics)]

    data = self.memory[mem_offset:mem_offset + length]
    log_entry = {
        "address": self.txn.thisAddr,
        "data": data.hex(),
        "topics": [f"0x{topic:064x}" for topic in topics]
    }
    self.logs.append(log_entry)
```

最后，我们需要在`run`方法中为不同的`LOG`指令添加支持：

```python
def run(self):
    while self.pc < len(self.code):
        op = self.next_instruction()
        
        # ... 其他指令的处理 ...
        
        elif op == LOG0:
            self.log(0)
        elif op == LOG1:
            self.log(1)
        elif op == LOG2:
            self.log(2)
        elif op == LOG3:
            self.log(3)
        elif op == LOG4:
            self.log(4)
```

## 测试

### 测试`LOG0`

我们运行一个包含`LOG0`指令的字节码：`60aa6000526001601fa0`（PUSH1 aa PUSH1 0 MSTORE PUSH1 1 PUSH1 1f LOG0）。这个字节码将`aa`存在内存中，然后使用`LOG0`指令将`aa`输出到日志的数据部分。

```python
# LOG0
code = b"\x60\xaa\x60\x00\x52\x60\x01\x60\x1f\xa0"
evm = EVM(code, txn)
evm.run()
print(evm.logs)
# output: [{'address': '0x9bbfed6889322e016e0a02ee459d306fc19545d8', 'data': 'aa', 'topics': []}]
```

### 测试`LOG1`

我们运行一个包含`LOG1`指令的字节码：`60aa60005260116001601fa1`（PUSH1 aa PUSH1 0 MSTORE PUSH 11 PUSH1 1 PUSH1 1f LOG1）。这个字节码将`aa`存在内存，然后将`11`压入堆栈，最后使用`LOG1`指令将`aa`输出到日志的数据部分，将`11`输出到日志的主题部分。

```python
# LOG1
code = b"\x60\xaa\x60\x00\x52\x60\x11\x60\x01\x60\x1f\xa1"
evm = EVM(code, txn)
evm.run()
print(evm.logs)
# output: [{'address': '0x9bbfed6889322e016e0a02ee459d306fc19545d8', 'data': 'aa', 'topics': ['0x0000000000000000000000000000000000000000000000000000000000000011']}]
```

## 总结

这一讲，我们学习了EVM中与日志和事件相关的5个指令。这些指令在智能合约开发中扮演着关键角色，允许开发者在区块链上永久记录重要信息，同时不会影响区块链的状态。目前，我们已经学习了144个操作码中的131个！
