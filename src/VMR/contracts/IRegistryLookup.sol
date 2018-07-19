pragma solidity ^0.4.23;

/** @title IRegistry Lookup interface.
  * @dev Indicates a contract has registry read functionality. 
*/
interface IRegistryLookup {

    /** @dev Gets the address of the owner relating to the member
      * @param _memberId The member id
      */    
    function getMemberOwner(bytes32 _memberId) external view returns (address);

    /** @dev Is the member registered and marked as enabled
      * @param _memberId The member id
      */            
    function isMemberRegisteredAndEnabled(bytes32 _memberId) external view returns (bool);
}