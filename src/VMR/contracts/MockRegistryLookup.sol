pragma solidity ^0.4.23;

import "./IRegistryLookup.sol";

/** @title Mock Registry Lookup
  * @dev A contract to use as a test double when unit testing contract dependant on the IRegistryLookup interface.
 */
contract MockRegistryLookup is IRegistryLookup {
    
    mapping(bytes32 => address) owners;
    mapping(bytes32 => bool) enabled;

    /** @dev gets the owner of a member.
      * @param _memberId the member id.
      * @return the owner address.
      */   
    function getMemberOwner(bytes32 _memberId) external view returns (address) {
        address owner = owners[_memberId];
        require(owner != 0);
        return owner;
    }

    /** @dev Indicates if the member is registered and enabled.
      * @param _memberId the member id.
      * @return a boolean.
      */   
    function isMemberRegisteredAndEnabled(bytes32 _memberId) external view returns (bool) {
        return enabled[_memberId];
    }

    /** @dev sets the mock values which will be returned when IRegistryLookup functions are called.
      * @param _memberId the memberId.
      * @param _owner the address of the owner relating to the member.
      * @param _isEnabled a flag to indicate if the member is regarded as enabled.
     */
    function setMock(bytes32 _memberId, address _owner, bool _isEnabled) external payable {
        owners[_memberId] = _owner;
        enabled[_memberId] = _isEnabled;
    }
}