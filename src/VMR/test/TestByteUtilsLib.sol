pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "../contracts/ByteUtilsLib.sol";

contract TestByteUtilsLib {

    using ByteUtilsLib for bytes32;

    function testGetStringLength() public {
        bytes32 s = "123456789";
        Assert.equal(9, s.getStringLength(), "The length should be 9");
    }

    function testBytes32ToString() public {
        bytes32 s = "123456789";
        Assert.equal("123456789", s.bytes32ToString(), "The string should be 123456789");
    }

    function testBytes32ToStringMaxLength() public {
        bytes32 s = "01234567890123456789012345678901";
        Assert.equal("01234567890123456789012345678901", s.bytes32ToString(), 
            "The string should be 01234567890123456789012345678901");
    }    
}