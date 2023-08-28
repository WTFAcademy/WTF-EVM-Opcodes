# WTF Opcodes极简入门: 21. Create指令

我最近在重新学以太坊opcodes，也写一个“WTF EVM Opcodes极简入门”，供小白们使用。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/WTFAcademy/WTF-Opcodes](https://github.com/WTFAcademy/WTF-Opcodes)

-----

这一讲，我们介绍EVM中的`CREATE`指令，它可以让合约创建新的合约。

## initcode 初始代码

之前我们提到过，以太坊有两种交易，一种是合约调用，而另一种是合约创建。在合约创建的交易中，`to`字段设为空，而`data`字段应填写为合约的初始代码（`initcode`）。`initcode`也是字节码，但它只在合约创建时执行一次，目的是为新合约设置必要的状态和返回最终的合约字节码（`contract code`）。

下面，我们看一个简单的`initcode`：`63ffffffff6000526004601cf3`。它的指令形式为：
```
PUSH4 ffffffff
PUSH1	00
MSTORE	
PUSH1	04
PUSH1	1c
RETURN	
```

它先用`MSTORE`指令把`ffffffff`拷贝到内存中，然后用`RETURN`指令将它拷贝到返回数据中。这段`initcode`会把新合约的字节码设置为`ffffffff`。


## CREATE

在EVM中，当一个合约想要创建一个新的合约时，会使用`CREATE`指令。它的简化流程：

1. 从堆栈中弹出`value`（向新合约发送的ETH）、`mem_offset`和`length`（新合约的`initcode`在内存中的初始位置和长度）。
2. 计算新合约的地址，计算方法为: 
    ```python
    address = keccak256(rlp([sender_address,sender_nonce]))[12:]
    ```
3. 更新ETH余额。
4. 初始化新的EVM上下文`evm_create`，用于执行`initcode`。
5. 在`evm_create`中执行`initcode`。
6. 如果执行成功，则更新创建的账户状态：更新`balance`，将`nonce`初始化为`0`，将`code`字段设为`evm_create`的返回数据，将`storage`字段设置为`evm_create`的`storage`。
7. 如果成功，则将新合约地址推入堆栈；若失败，将`0`推入堆栈。

下面，我们在极简EVM中实现`CREATE`指令：

```python
def create(self):
    if len(self.stack) < 3:
        raise Exception('Stack underflow')

    # 弹出堆栈数据
    value = self.stack.pop()
    mem_offset = self.stack.pop()
    length = self.stack.pop()

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

    # 生成新的合约地址（参考geth中的方式，使用创建者的地址和nonce）
    creator_nonce = creator_account['nonce']
    new_contract_address_bytes = sha3.keccak_256(self.txn.thisAddr.encode() + str(creator_nonce).encode()).digest()
    new_contract_address = '0x' + new_contract_address_bytes[-20:].hex()  # 取后20字节作为地址

    # 使用txn构建上下文
    ctx = Transaction(to=new_contract_address,
                        data=init_code,
                        value=value,
                        caller=self.txn.thisAddr,
                        origin=self.txn.origin,
                        thisAddr=new_contract_address,
                        gasPrice=self.txn.gasPrice,
                        gasLimit=self.txn.gasLimit)

    # 创建并运行新的EVM实例
    evm_create = EVM(init_code, ctx)
    evm_create.run()

    # 如果EVM实例返回错误，压入0，表示创建失败
    if evm_create.success == False:
        self.stack.append(0)
        return

    # 更新创建者的nonce
    creator_account['nonce'] += 1

    # 存储合约的状态
    account_db[new_contract_address] = {
        'balance': value,
        'nonce': 0,  # 新合约的nonce从0开始
        'storage': evm_create.storage,
        'code': evm_create.returnData
    }
    
    # 压入新创建的合约地址
    self.stack.append(int(new_contract_address, 16))
```

## 测试

1. 部署一个新合约，发送`9` wei，不部署任何代码：
    ```python
    # CREATE (empty code, 9 wei balance)
    code = b"\x5f\x5f\x60\x09\xf0"
    evm = EVM(code, txn)
    evm.run()
    print(hex(evm.stack[-1]))
    # output: 0x260144093a2920f68e1ae2e26b3bd15ddd610dfe
    print(account_db[hex(evm.stack[-1])])
    # output: {'balance': 9, 'nonce': 0, 'storage': {}, 'code': bytearray(b'')}
    ```

2. 部署一个新合约，代码设置为`ffffffff`:

    ```python
    # CREATE (with 4x FF)
    code = b"\x6c\x63\xff\xff\xff\xff\x60\x00\x52\x60\x04\x60\x1c\xf3\x60\x00\x52\x60\x0d\x60\x13\x60\x00\xf0"
    # PUSH13 0x63ffffffff6000526004601cf3 PUSH1 0x00 MSTORE PUSH1 0x0d PUSH1 0x19 PUSH1 0x00 CREATE
    evm = EVM(code, txn)
    evm.run()
    print(hex(evm.stack[-1]))
    # output: 0x6dddd3288a19f0bf4eee7bfb9e168ad29e1395d0
    print(account_db[hex(evm.stack[-1])])
    # {'balance': 0, 'nonce': 0, 'storage': {}, 'code': bytearray(b'\xff\xff\xff\xff')}
    ```

## 总结

这一讲，我们介绍了`EVM`中创建合约的指令`CREATE`，通过它，合约可以创造其他合约，从而实现更为复杂的逻辑和功能。我们已经学习了144个操作码中的141个（98%）！
