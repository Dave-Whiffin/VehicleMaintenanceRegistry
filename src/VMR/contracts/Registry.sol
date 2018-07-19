pragma solidity ^0.4.23;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/TokenDestructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../node_modules/openzeppelin-solidity/contracts/AddressUtils.sol";
import "./RegistryStorageLib.sol";
import "./ByteUtilsLib.sol";
import "./IFeeLookup.sol";
import "./IRegistryLookup.sol";

/** @title Registry
  * @dev A registry of members.
  * Each member must have a unique memberId.
  * Each member will be assigned a member number when initially added.
  * Allowing members to be added.
  * Allowing attributes to be set against members.
  * Members to be disabled and re-enabled.
  * Initial ownership of members is the owner of the registry.
  * The owner of the registry can transfer ownership of the member.  
 */
contract Registry is Claimable, TokenDestructible, Pausable, IRegistryLookup {

    using ByteUtilsLib for bytes32;
    using AddressUtils for address;
    
    /** @dev Event LogInfo.
      * @param message a message.
     */
    event LogInfo(string message);

    /** @dev Event MemberRegistered - occurs when a member is first registered.
      * @param memberNumber the member.
      * @param memberId the member Id.
     */    
    event MemberRegistered(uint256 indexed memberNumber, bytes32 indexed memberId);

    /** @dev Event MemberEnabled - occurs when a member re-enabled.
      * @param memberNumber the member number.
     */    
    event MemberEnabled(uint256 indexed memberNumber);

    /** @dev Event MemberDisabled - occurs when a member disabled.
      * @param memberNumber the member number.
     */        
    event MemberDisabled(uint256 indexed memberNumber);

    /** @dev Event MemberOwnershipTransferRequest - occurs when a member ownership transfer is requested.
      * @param memberNumber the member number.
      * @param from the address of the current owner.
      * @param to the address of the pending owner.
     */        
    event MemberOwnershipTransferRequest(uint256 indexed memberNumber, address indexed from, address indexed to);

    /** @dev Event MemberOwnershipTransferAccepted - occurs when a pending owner accepts ownership of a member.
      * @param memberNumber the member number.
      * @param newOwner the address of the new owner.
     */            
    event MemberOwnershipTransferAccepted(uint256 indexed memberNumber, address indexed newOwner);

    /** @dev Event MemberAttributeChanged - occurs when an attribute is added or set.
      * @param memberNumber the member number.
      * @param attributeNumber the registry allocated attribute number.
      * @param attributeName the attribute name (specified by the member owner).
      * @param attributeType the attribute type (specified by the member owner).
      * @param attributeValue the attribute value (specified by the member owner).
     */        
    event MemberAttributeChanged(uint256 indexed memberNumber, 
    uint256 indexed attributeNumber, bytes32 indexed attributeName, bytes32 attributeType, bytes32 attributeValue);

    /** @dev the address of the eternal storage contract holding the state data for the registry. */
    address public storageAddress;

    /** @dev the address of the contract implementing IFeeLookup. */
    address public feeLookupAddress;

    /** @dev The Constructor.
      * @param _storageAddress the address of the eternal storage contract holding the state data for the registry.
      * @param _feeLookupAddress the address of the contract implementing IFeeLookup .
     */
    constructor(address _storageAddress, address _feeLookupAddress) public {

        require(_storageAddress.isContract());
        require(_feeLookupAddress.isContract());
        storageAddress = _storageAddress;
        feeLookupAddress = _feeLookupAddress;
    }

    /** @dev Modifier memberIdRegistered - Throws when memberId is not registered.
      * @param _memberId the user specified member id.
     */
    modifier memberIdRegistered(bytes32 _memberId) {
        require(RegistryStorageLib.memberNumberExists(storageAddress, getMemberNum(_memberId)));
        _;
    }

    /** @dev Modifier memberNumberRegistered - Throws when the member number is not registered.
      * @param _memberNumber the member number.
    */
    modifier memberNumberRegistered(uint256 _memberNumber) {
        require(RegistryStorageLib.memberNumberExists(storageAddress, _memberNumber));
        _;
    }

    /** @dev Modifier memberIdEnabled - Throws when member is not enabled.
      * @param _memberId the member id.
     */
    modifier memberIdEnabled(bytes32 _memberId) {
        require(RegistryStorageLib.getMemberEnabled(storageAddress, getMemberNum(_memberId)));
        _;
    }

    /** @dev Modifier memberNumberEnabled - Throws when member is not enabled.
      * @param _memberNumber the member number.
     */
    modifier memberNumberEnabled(uint256 _memberNumber) {
        require(RegistryStorageLib.getMemberEnabled(storageAddress, _memberNumber));
        _;
    }    

    /** @dev Modifier memberIdDisabled - throws when member is not disabled.
      * @param _memberId the member id.
    */
    modifier memberIdDisabled(bytes32 _memberId) {
        require(!RegistryStorageLib.getMemberEnabled(storageAddress, getMemberNum(_memberId)));
        _;
    }    

    /** @dev Modifier memberNumberDisabled - throws when member is not disabled.
      * @param _memberNumber the member number.
    */
    modifier memberNumberDisabled(uint256 _memberNumber) {
        require(!RegistryStorageLib.getMemberEnabled(storageAddress, _memberNumber));
        _;
    }          

    /** @dev Modifier memberIdNotRegistered - throws when member is already registered.
      * @param _memberId the member id.
    */
    modifier memberIdNotRegistered(bytes32 _memberId) {
        require(!RegistryStorageLib.memberNumberExists(storageAddress, getMemberNum(_memberId)));
        _;
    }

    /** @dev Modifier memberNumberNotRegistered - throws when member is already registered.
      * @param _memberNumber the member number.
    */
    modifier memberNumberNotRegistered(uint256 _memberNumber) {
        require(!RegistryStorageLib.memberNumberExists(storageAddress, _memberNumber));
        _;
    }    

    /** @dev Modifier memberIdOwner - Throws when sender is not the member owner.
      * @param _memberId the member id.
     */
    modifier memberIdOwner(bytes32 _memberId) {
        require(
            RegistryStorageLib.getMemberOwner(storageAddress, getMemberNum(_memberId)) == msg.sender);
        _;
    }

    /** @dev Modifier memberNumberOwner - Throws when sender is not the member owner.
      * @param _memberNumber the member number.
     */
    modifier memberNumberOwner(uint256 _memberNumber) {
        require(
            RegistryStorageLib.getMemberOwner(storageAddress, _memberNumber) == msg.sender);
        _;
    }    

    /** @dev Modifier pendingMemberNumberOwner - Throws when sender is not pending owner.
      * @param _memberNumber the member number.
     */
    modifier pendingMemberNumberOwner(uint256 _memberNumber) {
        require(
            RegistryStorageLib.getMemberPendingOwner(storageAddress, _memberNumber) == msg.sender);
        _;
    }        

    /** @dev Modifier memberMumberTransferKeyMatches - Throws when a hash of the key provided does not match the stored hash.
      * @param _memberNumber the member number.
      * @param _key the secret (not the hash, the actual value).
     */
    modifier memberMumberTransferKeyMatches(uint256 _memberNumber, string _key) {
        bytes32 storedKeyHash = RegistryStorageLib.getMemberTransferKeyHash(storageAddress, _memberNumber);
        bytes32 keyHash = keccak256(abi.encodePacked(_key));
        require(storedKeyHash == keyHash);
        _;        
    }

    /** @dev Modifier attributeNameDoesNotExist - Throws if the attribute name already exists against the member.
      * @param _memberNumber the member number.
      * @param _attribName the attribute name
     */
    modifier attributeNameDoesNotExist(uint256 _memberNumber, bytes32 _attribName) {
        require(RegistryStorageLib.getAttributeNumber(storageAddress, _memberNumber, _attribName) == 0);
        _;
    }

    /** @dev Modifier attributeNameExists - Throws if the attribute name does not exist against the member.
      * @param _memberNumber the member number.
      * @param _attribName the attribute name
     */
    modifier attributeNameExists(uint256 _memberNumber, bytes32 _attribName) {
        require(RegistryStorageLib.getAttributeNumber(storageAddress, _memberNumber, _attribName) > 0);
        _;
    }   

    /** @dev Modifier attributeNumberExists - Throws if the attribute number does not exist.
      * @param _memberNumber the member number.
      * @param _attributeNumber the attribute number
     */
    modifier attributeNumberExists(uint256 _memberNumber, uint256 _attributeNumber) {
        require(RegistryStorageLib.attributeNumberExists(storageAddress, _memberNumber, _attributeNumber));
        _;
    }

    /** @dev Modifier paidMemberRegistrationFee - Throws if the msg.value is below the registration fee (Wei)
     */
    modifier paidMemberRegistrationFee() {
        require(IFeeLookup(feeLookupAddress).getFeeInWei() <= msg.value);
        _;
    }

    /** @dev Modifier paidMemberTransferFee - Throws if the msg.value is below the transfer fee (Wei)
     */
    modifier paidMemberTransferFee() {
        require(IFeeLookup(feeLookupAddress).getFeeInWei() <= msg.value);
        _;
    }

    /** @dev Modifier senderAllowedToRegisterMember - Throws if isAllowedToRegisterMember returns false
     */
    modifier senderAllowedToRegisterMember() {
        require(isAllowedToRegisterMember(msg.sender));
        _;
    }

    /** @dev Returns true if the sender is the registry owner.
      * This may be overriden in contracts inheriting from Registry.
      * @param _address the address to check 
     */
    function isAllowedToRegisterMember(address _address) public view returns (bool) {
        return _address == owner;
    }

    /** @dev Sets the address of the IFeeLookup contract. Must be called by owner and contract is paused.
      * Requires a different addres to the current address.  
      * @param _feeLookupAddress the address of the IFeeLookup contract.     */
    function setFeeLookupAddress(address _feeLookupAddress) 
        public
        onlyOwner() 
        whenPaused()
         {
        require(_feeLookupAddress != feeLookupAddress);
        feeLookupAddress = _feeLookupAddress;
    }

    /** @dev Returns the total count of members in the registry.  */
    function getMemberTotalCount() 
        public view 
        returns (uint256) {
        return RegistryStorageLib.getMemberTotalCount(storageAddress);
    }

    /** @dev Returns true if the member is registered. 
      * @param _memberNumber the member number.
    */
    function isMemberRegistered(uint256 _memberNumber) 
        public view 
        returns (bool) {
        return RegistryStorageLib.memberNumberExists(storageAddress, _memberNumber);
    } 

    /** @dev Returns the member number for a given member id.  Throws if member id is not registered.
      * @param _memberId the member id. */
    function getMemberNumber(bytes32 _memberId) 
        public view 
        memberIdRegistered(_memberId)
        returns (uint256) {
        return getMemberNum(_memberId);
    }

    /** @dev Returns the member details for a given member.  Throws if the member does not exist.
      * @param _memberNumber the member number.
     */
    function getMember(uint256 _memberNumber) 
        public view
        memberNumberRegistered(_memberNumber)
        returns (uint256 memberNumber, bytes32 memberId, address owner, bool enabled, uint256 created) {
        
        RegistryStorageLib.Member memory member = getMemberInternal(_memberNumber);
        memberNumber = member.memberNumber;
        memberId = member.memberId;
        owner = member.owner;
        enabled = member.enabled;
        created = member.created;
    }

    /** @dev A Internal function to get the member struct for a member.
      * @param _memberNumber the member number. */
    function getMemberInternal(uint256 _memberNumber)
        internal view returns (RegistryStorageLib.Member memory) {
        RegistryStorageLib.Member memory m = RegistryStorageLib.getMember(storageAddress, _memberNumber);
        return m;
    }

    /** @dev IRegistryLookup implementation.  Returns the owner address for a given member.
      * @param _memberId the member id.
      */
    function getMemberOwner(bytes32 _memberId)
        external view
        memberIdRegistered(_memberId)
        returns (address) {
        uint256 memberNumber = getMemberNumber(_memberId);
        RegistryStorageLib.Member memory member = getMemberInternal(memberNumber);
        return member.owner;
    }

    /** @dev IRegistryLookup implementation.  Returns true if the member is registered and enabled.
      * @param _memberId the member id.
      */
    function isMemberRegisteredAndEnabled(bytes32 _memberId)
        external view
        returns (bool) {
        uint256 memberNumber = getMemberNum(_memberId);
        if(memberNumber == 0) {
            return false;
        }
        RegistryStorageLib.Member memory member = getMemberInternal(memberNumber);
        return member.enabled;
    }    
 
    /** @dev Returns the total attribute count for a given member.
    Throws if member does not exist.
      * @param _memberNumber the member number.
     */
    function getMemberAttributeTotalCount(uint256 _memberNumber) 
        public view
        memberNumberRegistered(_memberNumber)
        returns (uint256) {
        return RegistryStorageLib.getAttributeTotalCount(storageAddress, _memberNumber);
    }

    /** @dev Returns the attribute number relating to an attribute name for a member.
      * Throws when member is not registered.
      * Throws when attribute name does not exist.
      @param _memberNumber the member number
      @param _attributeName the attribute name
     */
    function getMemberAttributeNumber(uint256 _memberNumber, bytes32 _attributeName) 
        public view
        memberNumberRegistered(_memberNumber)
        attributeNameExists(_memberNumber, _attributeName)
        returns (uint256) {
        return RegistryStorageLib.getAttributeNumber(storageAddress, _memberNumber, _attributeName);
    }    

    /** @dev Returns the attribute for a given member and attribute number.
      * Throws when member is not registered.
      * Throws when attribute number does not exist.
      @param _memberNumber the member number
      @param _attributeNumber the attribute name
     */
    function getMemberAttribute(uint256 _memberNumber, uint256 _attributeNumber) 
        memberNumberRegistered(_memberNumber)
        attributeNumberExists(_memberNumber, _attributeNumber)    
        public view returns 
        (uint256 attributeNumber, bytes32 attributeName, bytes32 attributeType, bytes32 attributeValue) 
        {
        RegistryStorageLib.Attribute memory attribute = RegistryStorageLib.getAttribute(storageAddress, _memberNumber, _attributeNumber);
        return (attribute.attributeNumber, attribute.name, attribute.attributeType, attribute.value);
    }

    /** @dev Adds a new member to the registry.
      * Throws if contract is paused.
      * Throws if member id is already registered.
      * Throw if the sender is not allowed to register (is not the owner).
      * Throws if the msg.value is below the registration fee
      * @param _memberId the user allocated member id - must be unique.
      @return The member number.
     */
    function registerMember(bytes32 _memberId) 
        public payable
        whenNotPaused()
        memberIdNotRegistered(_memberId)
        senderAllowedToRegisterMember()
        paidMemberRegistrationFee()
        returns (uint256) {
        uint256 memberNumber = RegistryStorageLib.storeMember(storageAddress, _memberId, msg.sender);
        
        emit MemberRegistered(memberNumber, _memberId);
        return memberNumber;
    }

    /** @dev Enables a member in the registry.
      * Throws if contract is paused.
      * Throws if the sender is not the registry owner.
      * Throws if member number is not registered.
      * Throws is member is alredy enabled.
      * @param _memberNumber the member number to enable.
     */
    function enableMember(uint256 _memberNumber) 
        public payable 
        whenNotPaused()
        onlyOwner()
        memberNumberRegistered(_memberNumber)
        memberNumberDisabled(_memberNumber)
        {     
        RegistryStorageLib.setMemberEnabled(storageAddress, _memberNumber, true);    
        emit MemberEnabled(_memberNumber);
    }        

    /** @dev Disables a member in the registry
      * Throws when contract is paused
      * Throws if the sender is not the registry owner 
      * Throws if member is not registered
      * Throws if member is not enabled
      * @param _memberNumber the member number
    */
    function disableMember(uint256 _memberNumber) 
        public payable
        whenNotPaused()
        onlyOwner()
        memberNumberRegistered(_memberNumber)
        memberNumberEnabled(_memberNumber)
         {
        RegistryStorageLib.setMemberEnabled(storageAddress, _memberNumber, false);    
        emit MemberDisabled(_memberNumber);
    }

    /** @dev Sets the pending owner of a member (requires new owner to accept).
      * Throws when contract is paused
      * Throws when member is not registerd
      * Throws when sender does not own the member
      * Throws when msg.value is below the transfer fee
      * @param _memberNumber the member number
      * @param _newOwner the address of the new owner
      * @param _keyHash a hash of a secret (the secret should have been given to the new owner by other means)
    */
    function transferMemberOwnership(uint256 _memberNumber, address _newOwner, bytes32 _keyHash) 
        public payable 
        whenNotPaused()
        memberNumberRegistered(_memberNumber)
        memberNumberOwner(_memberNumber)
        paidMemberTransferFee()
        { 
        address currentOwner = RegistryStorageLib.getMemberOwner(storageAddress, _memberNumber);  
        RegistryStorageLib.setMemberPendingOwner(storageAddress, _memberNumber, _newOwner);  
        RegistryStorageLib.setMemberTransferKeyHash(storageAddress, _memberNumber, _keyHash);  
        emit MemberOwnershipTransferRequest(_memberNumber, currentOwner, _newOwner);
    }

    /** @dev The pending owner becomes the new owner of the member.
      * Throws when member does not exist.
      * Throws when contract is paused.
      * Throws when sender is not the pending owner address.
      * Throws when the hash of the provided key does not match the stored hash.
      @param _memberNumber the member number.
      @param _key the secret/password given to the pending owner by the current owner.
     */
    function acceptMemberOwnership(uint256 _memberNumber, string _key) 
        public payable
        whenNotPaused()
        memberNumberRegistered(_memberNumber)
        pendingMemberNumberOwner(_memberNumber)
        memberMumberTransferKeyMatches(_memberNumber, _key)
         {  
        RegistryStorageLib.setMemberOwner(storageAddress, _memberNumber, msg.sender);
        emit MemberOwnershipTransferAccepted(_memberNumber, msg.sender);
    }     

    /** @dev Adds an attibute to a member
      * Attributes are primarily key/value pairs.
      * They are indexed by attribute name (which must be unique for the member) and a registry allocated attribute number.
      * They can have a user specified attribute type to help group attributes.
      * Throws when contract is paused.
      * Throws when sender is not the member number owner.
      * Throws when member is not registered.
      * Throws is attribute name already exists for member.
      @param _memberNumber the member number.
      @param _attributeName the user specified attribute name (must be unique for member).
      @param _attributeType the user specified attribute type.
      @param _attributeValue the user specified value of the attribute.
      @return the registry allocated attribute number.
     */
    function addMemberAttribute(uint256 _memberNumber, bytes32 _attributeName, bytes32 _attributeType, bytes32 _attributeValue) 
        public payable 
        whenNotPaused()
        memberNumberRegistered(_memberNumber)        
        memberNumberOwner(_memberNumber)
        attributeNameDoesNotExist(_memberNumber, _attributeName)
        returns (uint256) {
        uint256 attributeNumber = RegistryStorageLib.storeMemberAttribute(
            storageAddress, _memberNumber, _attributeName, _attributeType, _attributeValue);
        emit MemberAttributeChanged(_memberNumber, attributeNumber, _attributeName, _attributeType, _attributeValue);
        return attributeNumber;
    } 

    /** @dev Sets the type and value on an existing attribute (both the type and value will be set even if empty)
      * Thows when contract is paused.
      * Throws when the member does not exist
      * Throws when the caller is not the owner of the member
      * Throws when the attribute number does not exist against the member
      * @param _memberNumber the member number
      * @param _attributeNumber the attribute number
      * @param _attributeType the attribute type to set
      * @param _attributeValue the attribute value to set
    */
    function setMemberAttribute(uint256 _memberNumber, uint256 _attributeNumber, bytes32 _attributeType, bytes32 _attributeValue) 
        public payable 
        whenNotPaused()
        memberNumberRegistered(_memberNumber)
        memberNumberOwner(_memberNumber)
        attributeNumberExists(_memberNumber, _attributeNumber) {

        RegistryStorageLib.setAttribute(storageAddress, _memberNumber, _attributeNumber, _attributeType, _attributeValue);
        bytes32 attributeName = RegistryStorageLib.getAttributeName(storageAddress, _memberNumber, _attributeNumber);        
        emit MemberAttributeChanged(_memberNumber, _attributeNumber, attributeName, _attributeType, _attributeValue);
    }      

    /** @dev Internal method which returns the member number from the given member id.
      * Does not throw if member does not exist (which the public or external getters do) 
      * @param _memberId the member id
      */
    function getMemberNum(bytes32 _memberId) 
        internal view 
        returns (uint256) {
        return RegistryStorageLib.getMemberNumber(storageAddress, _memberId);  
    }    
}