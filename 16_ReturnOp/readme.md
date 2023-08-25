# WTF Opcodes极简入门: 16. Return指令

我最近在重新学以太坊opcodes，也写一个“WTF EVM Opcodes极简入门”，供小白们使用。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/WTFAcademy/WTF-Opcodes](https://github.com/WTFAcademy/WTF-Opcodes)

-----

这一讲，我们将介绍EVM中与返回数据（return）相关的3个指令: `RETURN`，`RETURNDATASIZE`，和`RETURNDATACOPY`。它们是Solidity中`return`关键字的基础。

## 返回数据

EVM的返回数据，通常称为`returnData`，本质上是一个字节数组。它不遵循固定的数据结构，而是简单地表示为连续的字节。当合约函数需要返回复杂数据类型（如结构体或数组）时，这些数据将按照ABI规范被编码为字节，并存储在`returnData`中，供其他函数或合约访问。

为了支持这一特性，我们需要为我们的简化版EVM添加一个新属性以保存返回数据：

```python
class EVM:
    def __init__(self):
        # ... 其他属性 ...
        self.returnData = bytearray()
```

## 返回相关指令

### 1. RETURN

- **操作码**：`0xF3`
- **gas消耗**：内存扩展成本。
- **功能**：从指定的内存位置提取数据，存储到`returnData`中，并终止当前的操作。此指令需要从堆栈中取出两个参数：内存的起始位置`mem_offset`和数据的长度`length`。
- **使用场景**：当需要将数据返回给外部函数或交易时。

```python
def return_op(self):
    if len(self.stack) < 2:
        raise Exception('Stack underflow')

    mem_offset = self.stack.pop()
    length = self.stack.pop()
    
    # 拓展内存
    if len(self.memory) < mem_offset + length:
        self.memory.extend([0] * (mem_offset + length - len(self.memory)))

    self.returnData = self.memory[offset:offset + length]      
```

### 2. RETURNDATASIZE

- **操作码**：`0x3D`
- **gas消耗**：2
- **功能**：将`returnData`的大小推入堆栈。
- **使用场景**：使用上一个调用返回的数据。

```python
def returndatasize(self):
    self.stack.append(len(self.returnData))
```

### 3. RETURNDATACOPY

- 操作码：`0x3E`
- gas消耗： 3 + 3 * 数据长度 + 内存扩展成本
- **功能**：将`returnData`中的某段数据复制到内存中。此指令需要从堆栈中取出三个参数：内存的起始位置`mem_offset`，返回数据的起始位置`return_offset`，和数据的长度`length`。
- **使用场景**：使用上一个调用返回的部分数据。

```python
def returndatacopy(self):
    if len(self.stack) < 3:
        raise Exception('Stack underflow')

    mem_offset = self.stack.pop()
    return_offset = self.stack.pop()
    length = self.stack.pop()

    if return_offset + length > len(self.returnData):
        raise Exception("Invalid returndata size")

    # 扩展内存
    if len(self.memory) < mem_offset + length:
        self.memory.extend([0] * (mem_offset + length - len(self.memory)))

    # 使用切片进行复制
    self.memory[mem_offset:mem_offset + length] = self.returnData[return_offset:return_offset + length]
```

## 测试

1. **RETURN**: 我们运行一个包含`RETURN`指令的字节码：`60a26000526001601ff3`（PUSH1 a2 PUSH1 0 MSTORE PUSH1 1 PUSH1 1f RETURN）。这个字节码将`a2`存在内存中，然后使用`RETURN`指令将`a2`复制到`returnData`中。


    ```python
    # RETURN
    code = b"\x60\xa2\x60\x00\x52\x60\x01\x60\x1f\xf3"
    evm = EVM(code)
    evm.run()
    print(evm.returnData.hex())
    # output: a2
    ```

2. **RETURNDATASIZE**：我们将`returnData`设为`aaaa`，然后用`RETURNDATASIZE`将它的长度压入堆栈。

    ```python
    # RETURNDATASIZE
    code = b"\x3D"
    evm = EVM(code)
    evm.returnData = b"\xaa\xaa"
    evm.run()
    print(evm.stack)
    # output: 2
    ```

3. **RETURNDATACOPY**：我们将`returnData`设为`aaaa`，然后运行一个包含`RETURNDATACOPY`指令的字节码：`60025F5F3E`（PUSH1 2 PUSH0 PUSH0 RETURNDATACOPY），将返回数据存入内存。

    ```python
    # RETURNDATACOPY
    code = b"\x60\x02\x5F\x5F\x3E"
    evm = EVM(code)
    evm.returnData = b"\xaa\xaa"
    evm.run()
    print(evm.memory.hex())
    # output: aaaa
    ``````

## 总结

这一讲，我们学习了EVM中与返回数据相关的3个指令：`RETURN`、`RETURNDATASIZE`，和`RETURNDATACOPY`，并通过代码示例为极简EVM添加了对这些指令的支持。目前，我们已经学习了144个操作码中的134个（93%）！