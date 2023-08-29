# WTF Opcodes极简入门: 23. Selfdestruct指令

我最近在重新学以太坊opcodes，也写一个“WTF EVM Opcodes极简入门”，供小白们使用。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/WTFAcademy/WTF-Opcodes](https://github.com/WTFAcademy/WTF-Opcodes)

-----

这一讲，我们介绍EVM中的`SELFDESTRUCT`指令，它可以让合约自毁。这个指令可能在未来会被弃用，见[EIP-4758](https://eips.ethereum.org/EIPS/eip-4758)和[EIP-6049](https://eips.ethereum.org/EIPS/eip-6049)。

## 基本概念

EVM中的`SELFDESTRUCT`指令可以让合约自行销毁，并将账户中的ETH余额发送到指定地址。这个指令一些特殊的地方：

1. 使用`SELFDESTRUCT`指令时，当前合约会被标记为待销毁。但实际的销毁操作会在整个交易完成后进行。
2. 合约的`ETH`余额会被发送到指定的地址，并且这一过程保证会成功的。
3. 如果指定的地址是一个合约，那么该合约的代码不会被执行，即不会像平常的`ETH`转账执行目标地址的`fallback`方法。
4. 如果指定的地址不存在，则会为其创建一个新的账户，并存储这些ETH。
5. 一旦合约被销毁，其代码和数据都会永久地从链上删除，无法恢复。销毁合约可能会影响到与它互动的其他合约或服务。

`SELFDESTRUCT`指令的工作流程如下：

1. 从堆栈中弹出接收`ETH`的指定地址。
2. 将当前合约的余额转移到指定地址。
3. 销毁合约。

下面，我们在极简EVM中实现`SELFDESTRUCT`指令：

```python
def selfdestruct(self):
    if len(self.stack) < 1:
        raise Exception('Stack underflow')

    # 弹出接收ETH的指定地址
    raw_recipient = self.stack.pop()
    recipient = '0x' + format(raw_recipient, '040x')  # 转化为0x前缀的40个十六进制字符

    # 如果地址不存在，则创建它
    if recipient not in account_db:
        account_db[recipient] = {'balance': 0, 'nonce': 0, 'storage': {}, 'code': bytearray(b'')}

    # 将合约的余额转移到接收者账户
    account_db[recipient]['balance'] += account_db[self.txn.thisAddr]['balance']

    # 从数据库中删除合约
    del account_db[self.txn.thisAddr]
```

## 测试

1. 自毁当前合约，并将余额转移到新地址。

```python
# Define Txn
addr = '0x1000000000000000000000000000000000000c42'
txn = Transaction(to=None, value=10, 
                  caller=addr, origin=addr, thisAddr=addr)

# SELFDESTRUCT 
# delete account: 0x1000000000000000000000000000000000000c42
print("自毁前: ", account_db)
# 自毁前:  {'0x9bbfed6889322e016e0a02ee459d306fc19545d8': {'balance': 100, 'nonce': 1, 'storage': {}, 'code': b''}, '0x1000000000000000000000000000000000000c42': {'balance': 10, 'nonce': 0, 'storage': {}, 'code': b'`B`\x00R`\x01`\x1f\xf3'}}

code = b"\x60\x20\xff"  # PUSH1 0x20 (destination address) SELFDESTRUCT
evm = EVM(code, txn)
evm.run()
print("自毁后: ", account_db)
# 自毁后:  {'0x9bbfed6889322e016e0a02ee459d306fc19545d8': {'balance': 100, 'nonce': 1, 'storage': {}, 'code': b''}, '0x0000000000000000000000000000000000000020': {'balance': 10, 'nonce': 0, 'storage': {}, 'code': bytearray(b'')}}
```

## 总结

这一讲，我们介绍了EVM中销毁合约的`SELFDESTRUCT`指令，它可以自毁合约并且将其剩余的`ETH`强行发送到另一个地址。该指令将会在未来被弃用，大家尽量不要使用。现在，我们已经学习了144个操作码中的143个（99%），仅剩一个了！