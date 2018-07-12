pragma solidity ^0.4.23;

interface IVehicleRegistry {
    function getVehicleOwner(bytes32 _vin) external view returns (address);
    function isVehicleRegisteredAndEnabled(bytes32 _vin) external view returns (bool);
}