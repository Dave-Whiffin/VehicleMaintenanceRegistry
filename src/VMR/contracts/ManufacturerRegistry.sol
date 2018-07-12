pragma solidity ^0.4.23;

import "./Registry.sol";

contract ManufacturerRegistry is Registry {

    constructor(address _storageAddress, address _feeLookupAddress) 
        Registry(_storageAddress, _feeLookupAddress) public {
    }
}