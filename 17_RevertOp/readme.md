# WTF Opcodes极简入门: 17. Revert指令

我最近在重新学以太坊opcodes，也写一个“WTF EVM Opcodes极简入门”，供小白们使用。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/WTFAcademy/WTF-Opcodes](https://github.com/WTFAcademy/WTF-Opcodes)

-----

这一讲，我们将介绍EVM中与异常处理相关的2个指令: `REVERT` 和 `INVALID`。当它们被触发时，交易会回滚。

## 交易状态

我们需要在咱们的极简`evm`中跟踪交易的状态`success`，默认为`True`，当交易失败回滚时变为`False`，只有当`success`为`True`时继续执行opcodes，否则结束交易:

```python
class EVM:
    def __init__(self):
        # ... 其他属性 ...
        self.success = True

    def run(self):
        while self.pc < len(self.code) and self.success:
            op = self.next_instruction()
        # ... 指令操作 ...
```

## REVERT

当合约运行出错，或者达到了某种条件需要终止执行并返回错误信息时，可以使用`REVERT`指令。`REVERT`指令会终止交易的执行，返回一个错误消息，并且所有状态更改（例如资金转移、存储值的更改等）都不会生效。它会从堆栈中弹出两个参数：内存中错误消息的起始位置`mem_offset`和错误消息的长度`length`。它的操作码为`0xFD`，gas消耗为内存扩展消耗。

```python
def revert(self):
    if len(self.stack) < 2:
        raise Exception('Stack underflow')
    mem_offset = self.stack.pop()
    length = self.stack.pop()

    # 拓展内存
    if len(self.memory) < mem_offset + length:
        self.memory.extend([0] * (mem_offset + length - len(self.memory)))

    self.returnData = self.memory[mem_offset:mem_offset+length]
    self.success = False
```

## INVALID

`INVALID`是EVM中用来表示无效操作的指令。当EVM遇到无法识别的操作码时，或者在故意触发异常的情境下，它会执行`INVALID`指令，导致所有状态更改都不会生效，并且消耗掉所有的gas。它确保了当合约试图执行未定义的操作时，不会无所作为或产生不可预测的行为，而是会安全地停止执行，对EVM的安全至关重要。它的操作码为`0xFE`，gas消耗为所有剩余的gas。

```python
def invalid(self):
    self.success = False
```

## 测试

1. **REVERT**: 我们运行一个包含`REVERT`指令的字节码：`60aa6000526001601ffd`（PUSH1 aa PUSH1 0 MSTORE PUSH1 1 PUSH1 1f REVERT）。这个字节码将`aa`存在内存中，然后使用`REVERT`指令将交易回滚，并将`aa`复制到`returnData`中。


    ```python
    # REVERT
    code = b"\x60\xa2\x60\x00\x52\x60\x01\x60\x1f\xfd"
    evm = EVM(code)
    evm.run()
    print(evm.returnData.hex())
    # output: a2
    ```

## 总结

这一讲，我们学习了EVM中与异常处理相关的2个指令：`REVERT`和`INVALID`，并通过代码示例为极简EVM添加了对这些指令的支持。异常处理是任何程序或合约执行的重要部分，而这两个指令是Solidity中的`require`，`error`和`assert`关键字的基础。目前，我们已经学习了144个操作码中的136个（94%）！
