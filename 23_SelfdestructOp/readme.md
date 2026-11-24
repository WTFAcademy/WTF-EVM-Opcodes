# WTF Opcodes极简入门: 23. Selfdestruct指令

我最近在重新学以太坊opcodes，也写一个“WTF EVM Opcodes极简入门”，供小白们使用。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/WTFAcademy/WTF-Opcodes](https://github.com/WTFAcademy/WTF-Opcodes)

-----

这一讲介绍 `SELFDESTRUCT`。以太坊在 Cancun 升级中通过 [EIP-6780](https://eips.ethereum.org/EIPS/eip-6780) 改变了该指令的语义。

## 基本概念

`SELFDESTRUCT` 停止当前执行帧，并把合约余额转给指定地址。转账不会执行接收方代码。Cancun 之后，已有合约的代码、存储和账户会保留。只有合约在执行该指令的同一笔交易中创建时，才保留原先的删除行为。

下面的代码与 notebook 演示的是 Cancun 升级前的简化模型。

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

本讲演示了 Cancun 之前的 `SELFDESTRUCT`，并介绍了 EIP-6780 对余额转移和合约删除的影响。
