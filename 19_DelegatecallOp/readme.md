# WTF Opcodes极简入门: 19. Delegatecall指令

我最近在重新学以太坊opcodes，也写一个“WTF Opcodes极简入门”，供小白们使用。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/WTFAcademy/WTF-Opcodes](https://github.com/WTFAcademy/WTF-Opcodes)

-----

这一讲，我们介绍EVM中的`DELEGATECALL`指令和不再建议使用的`CALLCODE`指令。他们与`CALL`指令类似，但是调用的上下文不同。如果你不了解`DELEGATECALL`指令，请参考[WTF Solidity教程第23讲](https://github.com/AmazingAng/WTF-Solidity/blob/main/23_Delegatecall/readme.md)。

![](./img/19-1.png)

## DELEGATECALL

`DELEGATECALL`指令与`CALL`有许多相似之处，但关键的区别在于调用的上下文不同，它在代理合约和可升级合约中被广泛应用。它的设计目的是允许一个合约借用其他合约的代码，但代码是在原始合约的上下文中执行。这使得一份代码可以被多个合约重复使用，而无需重新部署。使用`DELEGATECALL`时`msg.sender`和`msg.value`保持不变，修改的存储变量也是原始合约的。

它从堆栈中弹出6个参数，与`CALL`不同，它不包括`value`，因为ETH不会被发送：

- `gas`：为这次调用分配的gas量。
- `to`：被调用合约的地址。
- `mem_in_start`：输入数据（calldata）在内存的起始位置。
- `mem_in_size`：输入数据的长度。
- `mem_out_start`：返回数据（returnData）在内存的起始位置。
- `mem_out_size`：返回数据的长度。

```python
def delegatecall(self):
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
    
    # 创建evm子环境，注意，这里的上下文是原始的调用合约，而不是目标合约
    evm_delegate = EVM(account_target['code'], self.txn)
    evm_delegate.storage = self.storage
    # 运行代码
    evm_delegate.run()
    
    # 拓展内存
    if len(self.memory) < mem_out_start + mem_out_size:
        self.memory.extend([0] * (mem_out_start + mem_out_size - len(self.memory)))
    
    self.memory[mem_out_start: mem_out_start + mem_out_size] = evm_delegate.returnData
    
    if evm_delegate.success:
        self.stack.append(1)  
    else:
        self.stack.append(0)  
        print("Delegatecall execution failed!")
```

有两个关键点需要注意：

1. `DELEGATECALL`不会更改`msg.sender`和`msg.value`。
2. `DELEGATECALL`改变的存储（storage）是原始合约的存储。
3. 与`CALL`不同，`DELEGATECALL`不会传递ETH值，因此少一个`value`参数。

## CALLCODE

`CALLCODE`与`DELEGATECALL`非常相似，但当修改状态变量时，它会更改调用者的合约状态而不是被调用者的合约状态。由于这个原因，`CALLCODE`在某些情况下可能会引起意料之外的行为，目前被视为已弃用。建议大家使用`DELEGATECALL`，而不是`CALLCODE`。

我们根据[EIP-2488](https://eips.ethereum.org/EIPS/eip-2488)，将`CALLCODE`视为已弃用：每次调用在堆栈中压入`0`（视为调用失败）。

```python
def callcode(self):
    self.stack.append(0)  
    print("Callcode not support!")
```

## 测试

在测试中，我们会使用第一个地址（`0x9bbf`起始）调用第二个地址（`0x1000`起始），运行上面的代码（`PUSH1 0x42 PUSH1 0 MSTORE PUSH1 1 PUSH1 31 RETURN`），成功的话会返回`0x42`。

测试字节码为`6001601f5f5f731000000000000000000000000000000000000c425ff45f51`（PUSH1 1 PUSH1 31 PUSH0 PUSH0 PUSH20 1000000000000000000000000000000000000c42 PUSH0 DELEGATECALL PUSH0 MLOAD），它会调用第二个地址上的代码，然后将内存中的返回值`0x42`压入堆栈。

```python
# Delegatecall
code = b"\x60\x01\x60\x1f\x5f\x5f\x73\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0c\x42\x5f\xf4\x5f\x51"
evm = EVM(code, txn)
evm.run()
print(hex(evm.stack[-2]))
# output: 0x1 (success)
print(hex(evm.stack[-1]))
# output: 0x42
```

## 总结

这一讲，我们探讨了`DELEGATECALL`指令，它使得EVM上的合约在不更改上下文的情况下调用其他合约，增加代码的复用性。它在代理合约和可升级合约中被广泛应用。另外，我们还介绍了已被视为弃用的`CALLCODE`指令。目前，我们已经学习了144个操作码中的139个（96%）！
