pragma solidity ^0.4.23;

import "./IRegistryFeeLookup.sol";

contract MockRegistryFeeChecker is IRegistryFeeLookup {

    uint256 public registrationFee;
    uint256 public transferFee;

    constructor(uint256 _registrationFee, uint256 _transferFee) public {
        registrationFee = _registrationFee;
        transferFee = _transferFee;
    }

    function getRegistrationFeeWei() external view returns (uint256) {
        return registrationFee;
    }

    function getTransferFeeWei() external view returns (uint256) {
        return transferFee;
    }

    function setRegistrationFeeWei(uint256 _fee) public payable {
        registrationFee = _fee;
    }

    function setTransferFeeWei(uint256 _fee) public payable {
        transferFee = _fee;
    }    
}