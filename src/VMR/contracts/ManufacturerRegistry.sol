pragma solidity ^0.4.23;

import "./Registry.sol";

/** @title Manufacturer Registry - a registry for vehicle manufacturers inheriting from a base Registry, an extension point for manufacturer specific extension in the future */
contract ManufacturerRegistry is Registry {

    /** @dev The constructor
      * @param _storageAddress The address of the EternalStorage contract where manufacturers will be stored.
      * @param _feeLookupAddress The address of the contract implementing IFeeLookup for registration and transfer fees.
      */   

    constructor(address _storageAddress, address _feeLookupAddress) 
        Registry(_storageAddress, _feeLookupAddress) public {
    }
}