pragma solidity ^0.4.23;

import "./IFeeLookup.sol";

contract MockFeeChecker is IFeeLookup {

    uint256 public fee;

    constructor(uint256 _initialFee) public {
        fee = _initialFee;
    }

    function getFeeInWei() external view returns (uint256) {
        return fee;
    }

    function setFeeInWei(uint256 _fee) public payable {
        fee = _fee;
    }

}