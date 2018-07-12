pragma solidity ^0.4.23;

interface IManufacturerRegistry {
    function getMemberOwner(bytes32 _manufacturerId) external view returns (address);
    function isMemberRegisteredAndEnabled(bytes32 _manufacturerId) external view returns (bool);
}