pragma solidity ^0.4.23;

interface IVehicleRegistry {
    function getVehicleOwner(bytes32 _vin) external returns (address);
    function isVehicleRegistered(bytes32 _vin) external returns (bool);
}