pragma solidity ^0.4.23;

import "./Registry.sol";

/** @title Maintainer Registry
  * @dev A registry of vehicle maintainers (garages etc).
  Inherits Registry which provides all of the functionality.
  Is a base for future maintainer specific functionality
*/
contract MaintainerRegistry is Registry {

    /** @dev The constructor
      * @param _storageAddress The address of the EternalStorage contract.
      * @param _feeLookupAddress The address of the contract implementing IFeeLookup
      */    
    constructor(address _storageAddress, address _feeLookupAddress) 
        Registry(_storageAddress, _feeLookupAddress) public {
    }
}