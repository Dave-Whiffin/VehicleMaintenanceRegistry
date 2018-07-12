pragma solidity ^0.4.23;

interface IManufacturerRegistry {
    function getManufacturerOwner(bytes32 _manufacturerId) external view returns (address);
    function isManufacturerRegisteredAndEnabled(bytes32 _manufacturerId) external view returns (bool);
}