pragma solidity ^0.4.23;

import "./IFeeLookup.sol";

/** @title Mock Fee Checker - for unit testing contracts depending on IFeeLookup */
contract MockFeeChecker is IFeeLookup {

    uint256 public fee;

    /** @dev The constructor.
      * @param _initialFee the fee to return when getFeeInWei is called.
      */   
    constructor(uint256 _initialFee) public {
        fee = _initialFee;
    }

    /** @dev returns the fee.
      * @return the fee.
      */   
    function getFeeInWei() external view returns (uint256) {
        return fee;
    }

    /** @dev sets the fee to return when getFeeInWei is called.
      * @param _fee the fee to return.
      */   
    function setFeeInWei(uint256 _fee) public payable {
        fee = _fee;
    }

}