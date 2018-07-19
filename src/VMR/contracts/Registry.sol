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
  Each member must have a unique memberId.
  Each member will be assigned a member number when initially added.
  Allowing members to be added.
  Allowing attributes to be set against members.
  Members to be disabled and re-enabled.
  Initial ownership of members is the owner of the registry.
  The owner of the registry can transfer ownership of the member.  
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

    modifier pendingMemberNumberOwner(uint256 _memberNumber) {
        require(
            RegistryStorageLib.getMemberPendingOwner(storageAddress, _memberNumber) == msg.sender);
        _;
    }        

    modifier memberMumberTransferKeyMatches(uint256 _memberNumber, string _key) {
        bytes32 storedKeyHash = RegistryStorageLib.getMemberTransferKeyHash(storageAddress, _memberNumber);
        bytes32 keyHash = keccak256(abi.encodePacked(_key));
        require(storedKeyHash == keyHash);
        _;        
    }

    modifier attributeNameDoesNotExist(uint256 _memberNumber, bytes32 _attribName) {
        require(RegistryStorageLib.getAttributeNumber(storageAddress, _memberNumber, _attribName) == 0);
        _;
    }

    modifier attributeNameExists(uint256 _memberNumber, bytes32 _attribName) {
        require(RegistryStorageLib.getAttributeNumber(storageAddress, _memberNumber, _attribName) > 0);
        _;
    }   

    modifier attributeNumberExists(uint256 _memberNumber, uint256 _attributeNumber) {
        require(RegistryStorageLib.attributeNumberExists(storageAddress, _memberNumber, _attributeNumber));
        _;
    }

    modifier paidMemberRegistrationFee() {
        require(IFeeLookup(feeLookupAddress).getFeeInWei() <= msg.value);
        _;
    }

    modifier paidMemberTransferFee() {
        require(IFeeLookup(feeLookupAddress).getFeeInWei() <= msg.value);
        _;
    }

    modifier senderAllowedToRegisterMember() {
        require(isAllowedToRegisterMember(msg.sender));
        _;
    }

    //interception point for contracts inheriting from this
    function isAllowedToRegisterMember(address _address) public view returns (bool) {
        return _address == owner;
    }

    function setFeeLookupAddress(address _feeLookupAddress) 
        public
        onlyOwner() 
        whenPaused()
         {
        require(_feeLookupAddress != feeLookupAddress);
        feeLookupAddress = _feeLookupAddress;
    }

//member related getters
    function getMemberTotalCount() 
        public view 
        returns (uint256) {
        return RegistryStorageLib.getMemberTotalCount(storageAddress);
    }

    function isMemberRegistered(uint256 _memberNumber) 
        public view 
        returns (bool) {
        return RegistryStorageLib.memberNumberExists(storageAddress, _memberNumber);
    } 

    function getMemberNumber(bytes32 _memberId) 
        public view 
        memberIdRegistered(_memberId)
        returns (uint256) {
        return getMemberNum(_memberId);
    }

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

    function getMemberInternal(uint256 _memberNumber)
        internal view returns (RegistryStorageLib.Member memory) {
        RegistryStorageLib.Member memory m = RegistryStorageLib.getMember(storageAddress, _memberNumber);
        return m;
    }

//IRegistryLookup
    function getMemberOwner(bytes32 _memberId)
        external view
        memberIdRegistered(_memberId)
        returns (address) {
        uint256 memberNumber = getMemberNumber(_memberId);
        RegistryStorageLib.Member memory member = getMemberInternal(memberNumber);
        return member.owner;
    }

//IRegistryLookup
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
 
    function getMemberAttributeTotalCount(uint256 _memberNumber) 
        public view
        memberNumberRegistered(_memberNumber)
        returns (uint256) {
        return RegistryStorageLib.getAttributeTotalCount(storageAddress, _memberNumber);
    }

    function getMemberAttributeNumber(uint256 _memberNumber, bytes32 _attributeName) 
        public view
        memberNumberRegistered(_memberNumber)
        attributeNameExists(_memberNumber, _attributeName)
        returns (uint256) {
        return RegistryStorageLib.getAttributeNumber(storageAddress, _memberNumber, _attributeName);
    }    

    function getMemberAttribute(uint256 _memberNumber, uint256 _attributeNumber) 
        memberNumberRegistered(_memberNumber)
        attributeNumberExists(_memberNumber, _attributeNumber)    
        public view returns 
        (uint256 attributeNumber, bytes32 attributeName, bytes32 attributeType, bytes32 attributeValue) 
        {
        RegistryStorageLib.Attribute memory attribute = RegistryStorageLib.getAttribute(storageAddress, _memberNumber, _attributeNumber);
        return (attribute.attributeNumber, attribute.name, attribute.attributeType, attribute.value);
    }

//payable
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

    function addMemberAttribute(uint256 _memberNumber, bytes32 _attributeName, bytes32 _attributeType, bytes32 _attributeValue) 
        public payable 
        whenNotPaused()
        onlyOwner()
        memberNumberRegistered(_memberNumber)
        attributeNameDoesNotExist(_memberNumber, _attributeName)
        returns (uint256) {
        uint256 attributeNumber = RegistryStorageLib.storeMemberAttribute(
            storageAddress, _memberNumber, _attributeName, _attributeType, _attributeValue);
        emit MemberAttributeChanged(_memberNumber, attributeNumber, _attributeName, _attributeType, _attributeValue);
        return attributeNumber;
    } 

    function setMemberAttribute(uint256 _memberNumber, uint256 _attributeNumber, bytes32 _attributeType, bytes32 _attributeValue) 
        public payable 
        whenNotPaused()
        onlyOwner()
        memberNumberRegistered(_memberNumber)
        attributeNumberExists(_memberNumber, _attributeNumber) {

        RegistryStorageLib.setAttribute(storageAddress, _memberNumber, _attributeNumber, _attributeType, _attributeValue);
        bytes32 attributeName = RegistryStorageLib.getAttributeName(storageAddress, _memberNumber, _attributeNumber);        
        emit MemberAttributeChanged(_memberNumber, _attributeNumber, attributeName, _attributeType, _attributeValue);
    }      

    function getMemberNum(bytes32 _memberId) 
        internal view 
        returns (uint256) {
        return RegistryStorageLib.getMemberNumber(storageAddress, _memberId);  
    }    
}