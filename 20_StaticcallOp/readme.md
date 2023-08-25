# WTF Opcodes极简入门: 20. Staticcall指令

我最近在重新学以太坊opcodes，也写一个“WTF EVM Opcodes极简入门”，供小白们使用。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/WTFAcademy/WTF-Opcodes](https://github.com/WTFAcademy/WTF-Opcodes)

-----

这一讲，我们介绍EVM中的`STATICCALL`指令，它和`CALL`指令类似，允许合约执行其他合约的代码，但是不能改变合约状态。它是Solidity中`pure`和`view`关键字的基础。

## STATICCALL 指令

`STATICCALL`指令会创建一个子环境来执行其他合约的部分代码，并返回数据。返回数据可以使用`RETURNDATASIZE`和`RETURNDATACOPY`获取。若执行成功，会将`1`压入堆栈；否则，则压入`0`。如果目标合约没有代码，仍将`1`压入堆栈（视为成功）。

和`CALL`指令的不同，`STATICCALL`不能发送`ETH`，也能改变合约的状态。它不允许子环境执行的代码中包含以下指令：

- `CREATE`, `CREATE2`, `SELFDESTRUCT`
- `LOG0` - `LOG4`
- `SSTORE`
- `value`不为0的`CALL`

它从堆栈中弹出6个参数，依次为：

- `gas`：为这次调用分配的gas量。
- `to`：被调用合约的地址。
- `mem_in_start`：输入数据（calldata）在内存的起始位置。
- `mem_in_size`：输入数据的长度。
- `mem_out_start`：返回数据（returnData）在内存的起始位置。
- `mem_out_size`：返回数据的长度。

它的操作码为`0xFA`，gas消耗为：内存扩展成本+地址操作成本。

下面，我们在极简evm中实现`STATICCALL`指令。首先，我们需要检查子环境的代码是否包含`STATICCALL`不支持的指令：

```python
def is_state_changing_opcode(self, opcode): # 检查static call不能包含的opcodes
    state_changing_opcodes = [
        0xF0, # CREATE
        0xF5, # CREATE2
        0xFF, # SELFDESTRUCT
        0xA0, # LOG0
        0xA1, # LOG1
        0xA2, # LOG2
        0xA3, # LOG3
        0xA4, # LOG4
        0x55  # SSTORE
    ]
    return opcode in state_changing_opcodes
```

然后在`init()`函数中初始化一个`is_static`状态，当它为`true`时，意味着执行的是`STATICCALL`，需要检查不支持的指令：

```python
class EVM:
    def __init__(self, code, is_static=False):
        # ... 其他初始化 ...
        self.is_static = is_static

    def run(self):
        while self.pc < len(self.code) and self.success:
            op = self.next_instruction()

            if self.is_static and self.is_state_changing_opcode(op):
                self.success = False
                raise Exception("State changing operation detected during STATICCALL!")
```

此外，对于不为0的value的CALL，我们需要稍作修改：

```python
def call(self):

    if self.is_static and value != 0:
        self.success = False
        raise Exception("State changing operation detected during STATICCALL!")

    # ... 其他代码 ...
```

最后，我们可以加入`staticcall`函数：

```python
def staticcall(self):
    if len(self.stack) < 6:
        raise Exception('Stack underflow')
        
    gas = self.stack.pop()
    to_addr = self.stack.pop()
    mem_in_start = self.stack.pop()
    mem_in_size = self.stack.pop()
    mem_out_start = self.stack.pop()
    mem_out_size = self.stack.pop()
    
    # 拓展内存
    if len(self.memory) < mem_in_start + mem_in_size:
        self.memory.extend([0] * (mem_in_start + mem_in_size - len(self.memory)))

    # 从内存中获取输入数据
    data = self.memory[mem_in_start: mem_in_start + mem_in_size]

    account_target = account_db[hex(to_addr)]
    
    # 使用txn构建上下文
    ctx = Transaction(to=hex(to_addr), 
                        data=data,
                        value=0,
                        caller=self.txn.thisAddr, 
                        origin=self.txn.origin, 
                        thisAddr=hex(to_addr), 
                        gasPrice=self.txn.gasPrice, 
                        gasLimit=self.txn.gasLimit, 
                        )
    
    # 创建evm子环境
    evm_staticcall = EVM(account_target['code'], ctx, is_static=True)
    # 运行代码
    evm_staticcall.run()
    
    # 拓展内存
    if len(self.memory) < mem_out_start + mem_out_size:
        self.memory.extend([0] * (mem_out_start + mem_out_size - len(self.memory)))
    
    self.memory[mem_out_start: mem_out_start + mem_out_size] = evm_staticcall.returnData
    
    if evm_staticcall.success:
        self.stack.append(1)  
    else:
        self.stack.append(0)
```

## 测试

在测试中，我们会使用第一个地址（`0x9bbf`起始）调用第二个地址（`0x1000`起始），运行上面的代码（`PUSH1 0x42 PUSH1 0 MSTORE PUSH1 1 PUSH1 31 RETURN`），成功的话会返回`0x42`。

测试字节码为`6001601f5f5f731000000000000000000000000000000000000c425ffA5f51`（PUSH1 1 PUSH1 31 PUSH0 PUSH0 PUSH20 1000000000000000000000000000000000000c42 PUSH0 STATICCALL PUSH0 MLOAD），它会调用第二个地址上的代码，然后将内存中的返回值`0x42`压入堆栈。

```python
# Staticcall
code = b"\x60\x01\x60\x1f\x5f\x5f\x73\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0c\x42\x5f\xfA\x5f\x51"
evm = EVM(code, txn)
evm.run()
print(hex(evm.stack[-2]))
# output: 0x1 (success)
print(hex(evm.stack[-1]))
# output: 0x42
```

## 总结

这一讲，我们探讨了`STATICCALL`指令，它提供了一种安全的方法来执行其他合约的代码，而不修改合约状态，是Solidity中`pure`和`view`关键字的基础。目前，我们已经学习了144个操作码中的140个（97%）！
