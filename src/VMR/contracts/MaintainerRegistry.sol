pragma solidity ^0.4.23;

import "./Registry.sol";

/** @title Maintainer Registry - a home to vehicle maintainers (garages etc) */
contract MaintainerRegistry is Registry {

    /** @dev The constructor
      * @param _storageAddress The address of the EternalStorage contract.
      * @param _feeLookupAddress The address of the contract implementing IFeeLookup
      */    
    constructor(address _storageAddress, address _feeLookupAddress) 
        Registry(_storageAddress, _feeLookupAddress) public {
    }
}