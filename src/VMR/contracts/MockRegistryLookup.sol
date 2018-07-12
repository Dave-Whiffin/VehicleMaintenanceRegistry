pragma solidity ^0.4.23;

import "./IRegistryLookup.sol";

contract MockRegistryLookup is IRegistryLookup {
    
    address private manufacturerOwner;
    bool private isEnabled;

    mapping(bytes32 => address) owners;
    mapping(bytes32 => bool) enabled;

    function getMemberOwner(bytes32 _manufacturerId) external view returns (address) {
        address owner = owners[_manufacturerId];
        require(owner != 0);
        return owner;
    }

    function isMemberRegisteredAndEnabled(bytes32 _manufacturerId) external view returns (bool) {
        return enabled[_manufacturerId];
    }

    function setMock(bytes32 _manufacturerId, address _owner, bool _isEnabled) external payable {
        owners[_manufacturerId] = _owner;
        enabled[_manufacturerId] = _isEnabled;
    }
}