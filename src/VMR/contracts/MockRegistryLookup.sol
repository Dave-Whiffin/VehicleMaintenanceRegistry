pragma solidity ^0.4.23;

import "./IRegistryLookup.sol";

contract MockRegistryLookup is IRegistryLookup {
    
    mapping(bytes32 => address) owners;
    mapping(bytes32 => bool) enabled;

    function getMemberOwner(bytes32 _memberId) external view returns (address) {
        address owner = owners[_memberId];
        require(owner != 0);
        return owner;
    }

    function isMemberRegisteredAndEnabled(bytes32 _memberId) external view returns (bool) {
        return enabled[_memberId];
    }

    function setMock(bytes32 _memberId, address _owner, bool _isEnabled) external payable {
        owners[_memberId] = _owner;
        enabled[_memberId] = _isEnabled;
    }
}