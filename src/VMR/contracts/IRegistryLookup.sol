pragma solidity ^0.4.23;

interface IRegistryLookup {
    function getMemberOwner(bytes32 _vin) external view returns (address);
    function isMemberRegisteredAndEnabled(bytes32 _vin) external view returns (bool);
}