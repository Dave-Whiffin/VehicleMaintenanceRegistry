pragma solidity ^0.4.23;

import "./Registry.sol";
import "./IManufacturerRegistry.sol";

contract ManufacturerRegistry is Registry, IManufacturerRegistry {

    constructor(address _storageAddress, address _feeLookupAddress) 
        Registry(_storageAddress, _feeLookupAddress) public {
    }

//IManufacturerRegistry
    function getManufacturerOwner(bytes32 _manufacturerId)
        external 
        memberIdRegistered(_manufacturerId)
        returns (address) {
        uint256 memberNumber = getMemberNumber(_manufacturerId);
        Member memory member = getMemberInternal(memberNumber);
        return member.owner;
    }

    function isManufacturerRegisteredAndEnabled(bytes32 _manufacturerId)
        external 
        returns (bool) {
        uint256 memberNumber = getMemberNumber(_manufacturerId);
        return isMemberRegistered(memberNumber);
    }
}