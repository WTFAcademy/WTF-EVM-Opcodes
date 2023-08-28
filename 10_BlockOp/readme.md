# WTF Opcodes极简入门: 10. 区块信息指令

我最近在重新学以太坊opcodes，也写一个“WTF EVM Opcodes极简入门”，供小白们使用。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/WTFAcademy/WTF-Opcodes](https://github.com/WTFAcademy/WTF-Opcodes)

-----

在这一讲，我们将介绍EVM中用于查询区块信息的9个指令，包括`BLOCKHASH`，`COINBASE`，`PREVRANDAO`等。我们将在用Python写的极简版EVM中添加对这些操作的支持。

## 区块信息

我们在写智能合约时经常会用到区块链信息，比如生成[伪随机数](https://github.com/AmazingAng/WTF-Solidity/blob/main/39_Random/Random.sol)时我们会使用`blockhash`，`block.number`，和`block.timestamp`:

```solidity
    /** 
    * 链上伪随机数生成
    * keccak256(abi.encodePacked())中填上一些链上的全局变量/自定义变量
    * 返回时转换成uint256类型
    */
    function getRandomOnchain() public view returns(uint256){
        /*
         * 本例链上随机只依赖区块哈希，调用者地址，和区块时间，
         * 想提高随机性可以再增加一些属性比如nonce等，但是不能根本上解决安全问题
         */
        bytes32 randomBytes = keccak256(abi.encodePacked(blockhash(block.number-1), msg.sender, block.timestamp));
        return uint256(randomBytes);
    }
```

EVM提供了一系列指令让智能合约访问当前或历史区块的信息，包括区块哈希、时间戳、coinbase等。

这些信息一般保存在区块头（`Header`）中，但我们可以为在极简EVM中添加`current_block`属性来模拟这些区块信息：

```python
def __init__(self, code):
    self.code = code
    self.pc = 0
    self.stack = []
    self.memory = bytearray()
    self.current_block = {
        "blockhash": 0x7527123fc877fe753b3122dc592671b4902ebf2b325dd2c7224a43c0cbeee3ca,
        "coinbase": 0x388C818CA8B9251b393131C08a736A67ccB19297,
        "timestamp": 1625900000,
        "number": 17871709,
        "prevrandao": 0xce124dee50136f3f93f19667fb4198c6b94eecbacfa300469e5280012757be94,
        "gaslimit": 30,
        "chainid": 1,
        "selfbalance": 100,
        "basefee": 30,
    }
```

## 区块信息指令

下面，我们介绍这些区块信息指令：

1. `BLOCKHASH`: 查询特定区块（最近的256个区块，不包括当前区块）的hash，它的操作码为`0x40`，gas消耗为20。。它从堆栈中弹出一个值作为区块高度（block number），然后将该区块的hash压入堆栈，如果它不属于最近的256个区块，则返回0（你可以使用`NUMBER`指令查询当前区块高度）。但是为了简化，我们在这里只考虑当前块。

    ```python
    def blockhash(self):
        if len(self.stack) < 1:
            raise Exception('Stack underflow')
        number = self.stack.pop()
        # 在真实场景中, 你会需要访问历史的区块hash
        if number == self.current_block["number"]:
            self.stack.append(self.current_block["blockhash"])
        else:
            self.stack.append(0)  # 如果不是当前块，返回0
    ```


2. `COINBASE`: 将当前区块的coinbase（矿工/受益人）地址压入堆栈，它的操作码为`0x41`，gas消耗为2。

    ```python
    def coinbase(self):
        self.stack.append(self.current_block["coinbase"])
    ```

3. `TIMESTAMP`: 将当前区块的时间戳压入堆栈，它的操作码为`0x42`，gas消耗为2。

    ```python
    def timestamp(self):
        self.stack.append(self.current_block["timestamp"])
    ```

4. `NUMBER`: 将当前区块高度压入堆栈，它的操作码为`0x43`，gas消耗为2。

    ```python
    def number(self):
        self.stack.append(self.current_block["number"])
    ```

5. `PREVRANDAO`: 替代了原先的`DIFFICULTY`(0x44) 操作码，其返回值是beacon链随机性信标的输出。此变更允许智能合约在以太坊转向权益证明(PoS)后继续从原本的`DIFFICULTY`操作码处获得随机性。它的操作码为`0x44`，gas消耗为2。

    ```python
    def prevrandao(self):
        self.stack.append(self.current_block["prevrandao"])
    ```

6. `GASLIMIT`: 将当前区块的gas限制压入堆栈，它的操作码为`0x45`，gas消耗为2。

    ```python
    def gaslimit(self):
        self.stack.append(self.current_block["gaslimit"])
    ```

7. `CHAINID`: 将当前的[链ID](https://chainlist.org/)压入堆栈，它的操作码为`0x46`，gas消耗为2。

    ```python
    def chainid(self):
        self.stack.append(self.current_block["chainid"])
    ```

8. `SELFBALANCE`: 将合约的当前余额压入堆栈，它的操作码为`0x47`，gas消耗为5。

    ```python
    def selfbalance(self):
        self.stack.append(self.current_block["selfbalance"])
    ```

9. `BASEFEE`: 将当前区块的[基础费](https://ethereum.org/zh/developers/docs/gas/#base-fee)（base fee）压入堆栈，它的操作码`0x48`，gas消耗为2。

    ```python
    def basefee(self):
        self.stack.append(self.current_block["basefee"])
    ```

下面，我们在极简EVM中添加对这些操作码的支持：

```python
BLOCKHASH = 0x40
COINBASE = 0x41
TIMESTAMP = 0x42
NUMBER = 0x43
PREVRANDAO = 0x44
GASLIMIT = 0x45
CHAINID = 0x46
SELFBALANCE = 0x47
BASEFEE = 0x48

def run(self):
    while self.pc < len(self.code):
        op = self.next_instruction()

        # ... 其他指令的处理 ...

        elif op == BLOCKHASH:
            self.blockhash()
        elif op == COINBASE:
            self.coinbase()
        elif op == TIMESTAMP:
            self.timestamp()
        elif op == NUMBER:
            self.number()
        elif op == PREVRANDAO:
            self.prevrandao()
        elif op == GASLIMIT:
            self.gaslimit()
        elif op == CHAINID:
            self.chainid()
        elif op == SELFBALANCE:
            self.selfbalance()
        elif op == BASEFEE:
            self.basefee()        
```

## 总结

这一讲，我们介绍了EVM中与区块链信息相关的指令，这些指令允许智能合约访问与其所在区块链相关的信息。这些信息有很多用途，比如判断交易是否超时，或者检查合约的余额。

课后习题: 请尝试写出一段字节码，该字节码会先压入当前区块链的高度，然后获取它的区块哈希。
