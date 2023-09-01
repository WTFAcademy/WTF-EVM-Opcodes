# WTF Opcodes极简入门: 24. Gas指令

我最近在重新学以太坊opcodes，也写一个“WTF EVM Opcodes极简入门”，供小白们使用。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/WTFAcademy/WTF-Opcodes](https://github.com/WTFAcademy/WTF-Opcodes)

-----

这一讲，我们介绍EVM中的`GAS`指令，并介绍以太坊的Gas机制。

## 什么是Gas

在EVM中，交易和执行智能合约需要消耗计算资源。为了防止用户恶意的滥用网络资源和补偿验证者所消耗的计算能源，以太坊引入了一种称为Gas的计费机制，使每一笔交易都有一个关联的成本。

在发起交易时，用户设定一个最大Gas数量（`gasLimit`）和每单位Gas的价格（`gasPrice`）。如果交易执行超出了`gasLimit`，交易会回滚，但已消耗的Gas不会退还。

## Gas规则

以太坊上的Gas用`gwei`衡量，它是`ETH`的子单位，`1 ETH = 10^9 gwei`。一笔交易的Gas成本等于每单位gas价格乘以交易的gas消耗，即`gasPrice * gasUsed`。gas价格会随着时间的推移而变化，具体取决于当前对区块空间的需求。gas消耗由很多因素决定，并且每个以太坊版本都会有所改动，下面总结下：

1. `calldata`大小：`calldata`中的每个字节都需要花费gas，交易数据的大小越大，gas消耗就越高。`calldata`每个零字节花费`4` Gas，每个非零字节花费`16` Gas（伊斯坦布尔硬分叉之前为 64 个）。

2. 内在gas：每笔交易的内在成本为21000 Gas。除了交易成本之外，创建合约还需要 32000 Gas。该成本是在任何操作码执行之前从交易中支付的。

3. `opcode`固定成本：每个操作码在执行时都有固定的成本，以Gas为单位。对于所有执行，该成本都是相同的。比如每个`ADD`指令消耗`3` Gas。

4. `opcode`动态成本：一些指令消耗更多的计算资源取决于其参数。因此，除了固定成本之外，这些指令还具有动态成本。比如`SHA3`指令消耗的Gas随参数长度增长。

5. 内存拓展成本：在EVM中，合约可以使用操作码访问内存。当首次访问特定偏移量的内存（读取或写入）时，内存可能会触发扩展，产生gas消耗。比如`MLOAD`或`RETURN`。

6. 访问集成本：对于每个外部交易，EVM会定义一个访问集，记录交易过程中访问过的合约地址和存储槽（slot）。访问成本根据数据是否已经被访问过（热）或是首次被访问（冷）而有所不同。

7. Gas退款：`SSTORE`的一些操作（比如清除存储）可以触发Gas退款。退款会在交易结束时执行，上限为总Gas消耗的20%（从伦敦硬分叉开始）。

更详细的Gas消耗信息可以参考[evm.codes](https://www.evm.codes/)。

## GAS指令

EVM中的`GAS`指令会将当前交易的剩余`Gas`压入堆栈。它的操作码为`0x5A`，gas消耗为`2`。

```python
def gas(self):
    self.stack.append(self.txn.gasLimit - self.gasUsed)
```

下面，我们在极简EVM中实现`GAS`。出于教学目的，目前我们仅实现部分`opcode`的固定成本，其他的未来实现。

首先，我们需要在`EVM`中添加一个`gasUsed`属性，用于记录已经消耗的Gas：

```python
class EVM:
    def __init__(self, ...):
        # ... 其他属性 ...
        self.gasUsed = 0

```

接下来，我们需要定义每个指令的固定成本：

```python
# 固定成本
GAS_COSTS = {
    'PUSH': 3,
    'POP': 2,
    'ADD': 3,
    'MUL': 5,
    'SUB': 3,
    # ... 其他操作码的固定成本 ...
}
```


在每一个操作码的实现中更新Gas消耗，比如`PUSH`指令：
```python
def push(self, size):
    data = self.code[self.pc:self.pc + size] # 按照size从code中获取数据
    value = int.from_bytes(data, 'big') # 将bytes转换为int
    self.stack.append(value) # 压入堆栈
    self.pc += size # pc增加size单位
    self.gasUsed += GAS_COSTS['PUSH'] # 更新Gas消耗
```

最后，在每个操作码执行后检查Gas是否被耗尽：

```python
def run(self):
    while self.pc < len(self.code) and self.success:
        op = self.next_instruction()
        # ... opcode执行逻辑 ...

        # 检查gas是否耗尽
        if self.gasUsed > self.txn.gasLimit:
            raise Exception('Out of gas!')
```

## 测试

```python
# Define Txn
addr = '0x1000000000000000000000000000000000000c42'
txn = Transaction(to=None, value=10, data='', 
                  caller=addr, origin=addr, thisAddr=addr, gasLimit=100, gasPrice=1)

# GAS 
code = b"\x60\x20\x5a"  # PUSH1 0x20 GAS
evm = EVM(code, txn)
evm.run()
print(evm.stack)
# output: [32, 97] 
# gasLimit=100，gasUsed=3
```

## 总结

这一讲，我们介绍了以太坊的Gas机制以及`GAS`操作码。Gas机制确保了以太坊网络的计算资源不被恶意代码滥用。通过`GAS`指令，智能合约可以实时地查询还剩下多少Gas，从而做出相应的决策。

至此，EVM中的144个操作码我们全部学习完了！相信你对EVM的理解一定有了质的飞跃，恭喜你！