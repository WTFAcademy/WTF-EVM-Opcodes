# WTF Opcodes极简入门: 22. Create2指令

我最近在重新学以太坊opcodes，也写一个“WTF EVM Opcodes极简入门”，供小白们使用。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/WTFAcademy/WTF-Opcodes](https://github.com/WTFAcademy/WTF-Opcodes)

-----

上一讲我们介绍了`CREATE`指令，使合约有能力创建其他合约。这一讲，我们将进一步探讨`CREATE2`指令，它提供了一种新的方式来确定新合约的地址。

## CREATE vs CREATE2

传统的`CREATE`指令通过调用者的地址和nonce来确定新合约的地址，而`CREATE2`则提供了一种新的计算方法，使我们可以在合约部署之前预知它的地址。

与`CREATE`不同，`CREATE2`使用调用者地址、盐（一个自定义的256位的值）以及`initcode`的哈希来确定新合约的地址，计算方法如下：

```python
address = keccak256( 0xff + sender_address + salt + keccak256(init_code))[12:]
```

这样的好处是，只要你知道`initcode`，盐值和发送者的地址，就可以预先知道新合约的地址，而不需要现在部署它。而`CREATE`计算的地址取决于部署账户的`nonce`，也就是说，在`nonce`不确定的情况下（合约还未部署，nonce可能会增加），没法确定新合约的地址。

对`CREATE2`的更多介绍可以参考[WTF Solidity教程第25讲](https://github.com/AmazingAng/WTF-Solidity/blob/main/25_Create2/readme.md)。

## CREATE2

在EVM中，`CREATE2`指令的简化流程如下：

1. 从堆栈中弹出`value`（向新合约发送的ETH）、`mem_offset`、`length`（新合约的`initcode`在内存中的初始位置和长度）以及`salt`。
2. 使用上面的公式计算新合约的地址。
3. 之后的步骤同`CREATE`指令：初始化新的EVM上下文、执行`initcode`、更新创建的账户状态、返回新合约地址或`0`（如果失败）。

下面，我们在极简EVM中实现`CREATE2`指令：

```python
def create2(self):
    if len(self.stack) < 4:
        raise Exception('Stack underflow')

    value = self.stack.pop()
    mem_offset = self.stack.pop()
    length = self.stack.pop()
    salt = self.stack.pop()

    # 扩展内存
    if len(self.memory) < mem_offset + length:
        self.memory.extend([0] * (mem_offset + length - len(self.memory)))

    # 获取初始化代码
    init_code = self.memory[mem_offset: mem_offset + length]

    # 检查创建者的余额是否足够
    creator_account = account_db[self.txn.thisAddr]
    if creator_account['balance'] < value:
        raise Exception('Insufficient balance to create contract!')

    # 为创建者扣除指定的金额
    creator_account['balance'] -= value

    # 生成新的合约地址（参考geth中的方式，使用盐和initcode的hash）
    init_code_hash = sha3.keccak_256(init_code).digest()
    data_to_hash = b'\xff' + self.txn.thisAddr.encode() + str(salt).encode() + init_code_hash
    new_contract_address_bytes = sha3.keccak_256(data_to_hash).digest()
    new_contract_address = '0x' + new_contract_address_bytes[-20:].hex()  # 取后20字节作为地址

    # 使用txn构建上下文并执行
    ctx = Transaction(to=new_contract_address,
                        data=init_code,
                        value=value,
                        caller=self.txn.thisAddr,
                        origin=self.txn.origin,
                        thisAddr=new_contract_address,
                        gasPrice=self.txn.gasPrice,
                        gasLimit=self.txn.gasLimit)
    evm_create2 = EVM(init_code, ctx)
    evm_create2.run()

    # 如果EVM实例返回错误，压入0，表示创建失败
    if evm_create2.success == False:
        self.stack.append(0)
        return

    # 更新创建者的nonce
    creator_account['nonce'] += 1

    # 存储合约的状态
    account_db[new_contract_address] = {
        'balance': value,
        'nonce': 0,
        'storage': evm_create2.storage,
        'code': evm_create2.returnData
    }

    # 压入新创建的合约地址
    self.stack.append(int(new_contract_address, 16))
```

## 测试

1. 使用`CREATE2`指令部署一个新合约，发送`9` wei，但不部署任何代码：
    ```python
    # CREATE2 (empty code, 9 wei balance)
    code = b"\x5f\x5f\x5f\x60\x09\xf5"
    # PUSH0 PUSH0 PUSH0 PUSH1 0x09 CREATE2
    evm = EVM(code, txn)
    evm.run()
    print(hex(evm.stack[-1]))
    # output: 0x260144093a2920f68e1ae2e26b3bd15ddd610dfe
    print(account_db[hex(evm.stack[-1])])
    # output: {'balance': 9, 'nonce': 0, 'storage': {}, 'code': bytearray(b'')}
    ```

2. 使用`CREATE2`指令部署一个新合约，并将代码设置为`ffffffff`:

    ```python
    # CREATE2 (with 4x FF)
    code = b"\x6c\x63\xff\xff\xff\xff\x60\x00\x52\x60\x04\x60\x1c\xf3\x60\x00\x52\x60\x00\x60\x0d\x60\x13\x60\x00\xf5"
    # PUSH13 0x63ffffffff6000526004601cf3 PUSH1 0x00 MSTORE PUSH1 0x00 PUSH1 0x0d PUSH1 0x13 PUSH1 0x00 CREATE2
    evm = EVM(code, txn)
    evm.run()
    print(hex(evm.stack[-1]))
    # output: 0x6dddd3288a19f0bf4eee7bfb9e168ad29e1395d0
    print(account_db[hex(evm.stack[-1])])
    # {'balance': 0, 'nonce': 0, 'storage': {}, 'code': bytearray(b'\xff\xff\xff\xff')}
    ```

## 总结

这一讲，我们介绍了`EVM`中创建合约的另一个指令，`CREATE2`，通过它，合约不仅可以创造其他合约，而且可以预知新合约的地址。`Uniswap v2`中的LP地址就是用这个方法计算的。现在，我们已经学习了144个操作码中的142个（98.6%）！
