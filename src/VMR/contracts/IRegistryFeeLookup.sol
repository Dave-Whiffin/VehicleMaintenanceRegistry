pragma solidity ^0.4.23;

interface IRegistryFeeLookup {
    function getRegistrationFeeWei() external view returns (uint256);
    function getTransferFeeWei() external view returns (uint256);
}