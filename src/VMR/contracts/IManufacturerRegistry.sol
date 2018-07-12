pragma solidity ^0.4.23;

interface IManufacturerRegistry {
    function getManufacturerOwner(bytes32 _manufacturerId) external returns (address);
    function isManufacturerRegisteredAndEnabled(bytes32 _manufacturerId) external returns (bool);
}