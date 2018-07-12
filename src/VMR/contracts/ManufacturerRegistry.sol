pragma solidity ^0.4.23;

import "./Registry.sol";
import "./IManufacturerRegistry.sol";

contract ManufacturerRegistry is Registry, IManufacturerRegistry {

    constructor(address _storageAddress, address _feeLookupAddress) 
        Registry(_storageAddress, _feeLookupAddress) public {
    }

//IManufacturerRegistry
    function getManufacturerOwner(bytes32 _manufacturerId)
        external view
        returns (address) {
    
        return getMemberOwner(_manufacturerId);
    }

    function isManufacturerRegisteredAndEnabled(bytes32 _manufacturerId)
        external view
        returns (bool) {
        return isMemberRegisteredAndEnabled(_manufacturerId);
    }
}