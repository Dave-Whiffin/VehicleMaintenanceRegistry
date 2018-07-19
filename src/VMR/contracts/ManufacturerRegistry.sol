pragma solidity ^0.4.23;

import "./Registry.sol";

/** @title Manufacturer Registry 
  * @dev A registry for vehicle manufacturers inheriting from a base Registry
  Empty for now except for a constructor but acting as an extension point for future
  Hence only a basic test. */
contract ManufacturerRegistry is Registry {

    /** @dev The constructor
      * @param _storageAddress The address of the EternalStorage contract where manufacturers will be stored.
      * @param _feeLookupAddress The address of the contract implementing IFeeLookup for registration and transfer fees.
      */   

    constructor(address _storageAddress, address _feeLookupAddress) 
        Registry(_storageAddress, _feeLookupAddress) public {
    }
}