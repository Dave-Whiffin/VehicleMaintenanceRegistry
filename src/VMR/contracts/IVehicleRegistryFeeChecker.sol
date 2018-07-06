pragma solidity ^0.4.23;

interface IVehicleRegistryFeeChecker {
    function getRegistrationFeeEth() external view returns (uint256);
    function getTransferFeeEth() external view returns (uint256);
}