pragma solidity ^0.4.23;

contract ThrowProxy {
    address public target;
    bytes data;

    constructor(address _target) public {
        target = _target;
    }

    function() public {
        data = msg.data;
    }

    function execute() public returns (bool) {
        return target.call(data);
    }  
}