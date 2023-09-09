// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

// Note: this contract requires `PUSH0`, which is available in solidity > 0.8.20 and EVM version > Shanghai
contract Clone0Factory {
    error FailedCreateClone();

    receive() external payable {}

    /**
     * @dev Deploys and returns the address of a clone0 (Minimal Proxy Contract with `PUSH0`) that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone0(address impl) public payable returns (address addr) {
        // first 18 bytes of the creation code 
        bytes memory data1 = hex"602c8060095f395ff3365f5f375f5f365f73";
        // last 15 bytes of the creation code
        bytes memory data2 = hex"5af43d5f5f3e5f3d91602a57fd5bf3";
        // complete the creation code of Clone0
        bytes memory _code = abi.encodePacked(data1, impl, data2);

        // deploy with create op
        assembly {
            // create(v, p, n)
            addr := create(callvalue(), add(_code, 0x20), mload(_code))
        }

        if (addr == address(0)) {
            revert FailedCreateClone();
        }
    }
}