pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "../contracts/ByteUtils.sol";

contract TestByteUtils {

    using ByteUtils for bytes32;

    function testGetStringLength() public {
        bytes32 s = "123456789";
        Assert.equal(9, s.getStringLength(), "The length should be 9");
    }

    function testBytes32ToString() public {
        bytes32 s = "123456789";
        Assert.equal("123456789", s.bytes32ToString(), "The string should be 123456789");
    }
}