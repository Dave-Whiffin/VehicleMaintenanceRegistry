pragma solidity ^0.4.23;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/TokenDestructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./RegistryStorageLib.sol";
import "./ByteUtilsLib.sol";
import "./IFeeLookup.sol";
import "./IRegistryLookup.sol";

contract Registry is Claimable, TokenDestructible, Pausable, IRegistryLookup {

    using ByteUtilsLib for bytes32;
    
    event LogInfo(string message);
    event MemberRegistered(uint256 indexed memberNumber, bytes32 indexed memberId);
    event MemberEnabled(uint256 indexed memberNumber);
    event MemberDisabled(uint256 indexed memberNumber);
    event MemberOwnershipTransferRequest(uint256 indexed memberNumber, address indexed from, address indexed to);
    event MemberOwnershipTransferAccepted(uint256 indexed memberNumber, address indexed newOwner);
    event MemberAttributeChanged(uint256 indexed memberNumber, 
    uint256 indexed attributeNumber, bytes32 indexed attributeName, bytes32 attributeType, bytes32 attributeValue);

    address public storageAddress;
    address public feeLookupAddress;

    constructor(address _storageAddress, address _feeLookupAddress) public {
        storageAddress = _storageAddress;
        feeLookupAddress = _feeLookupAddress;
    }

    modifier memberIdRegistered(bytes32 _memberId) {
        require(RegistryStorageLib.memberNumberExists(storageAddress, getMemberNum(_memberId)));
        _;
    }

    modifier memberNumberRegistered(uint256 _memberNumber) {
        require(RegistryStorageLib.memberNumberExists(storageAddress, _memberNumber));
        _;
    }

    modifier memberIdEnabled(bytes32 _memberId) {
        require(RegistryStorageLib.getMemberEnabled(storageAddress, getMemberNum(_memberId)));
        _;
    }

    modifier memberNumberEnabled(uint256 _memberNumber) {
        require(RegistryStorageLib.getMemberEnabled(storageAddress, _memberNumber));
        _;
    }    

    modifier memberIdDisabled(bytes32 _memberId) {
        require(!RegistryStorageLib.getMemberEnabled(storageAddress, getMemberNum(_memberId)));
        _;
    }    

    modifier memberNumberDisabled(uint256 _memberNumber) {
        require(!RegistryStorageLib.getMemberEnabled(storageAddress, _memberNumber));
        _;
    }          

    modifier memberIdNotRegistered(bytes32 _memberId) {
        require(!RegistryStorageLib.memberNumberExists(storageAddress, getMemberNum(_memberId)));
        _;
    }

    modifier memberNumberNotRegistered(uint256 _memberNumber) {
        require(!RegistryStorageLib.memberNumberExists(storageAddress, _memberNumber));
        _;
    }    

    modifier memberIdOwner(bytes32 _memberId) {
        require(
            RegistryStorageLib.getMemberOwner(storageAddress, getMemberNum(_memberId)) == msg.sender);
        _;
    }

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

    modifier memberMumberTransferKeyMatches(uint256 _memberNumber, bytes32 _keyHash) {
        bytes32 transferKey = RegistryStorageLib.getMemberTransferKey(storageAddress, _memberNumber);
        require(transferKey == _keyHash);
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
        RegistryStorageLib.setMemberTransferKey(storageAddress, _memberNumber, _keyHash);  
        emit MemberOwnershipTransferRequest(_memberNumber, currentOwner, _newOwner);
    }

    function acceptMemberOwnership(uint256 _memberNumber, bytes32 _keyHash) 
        public payable
        whenNotPaused()
        memberNumberRegistered(_memberNumber)
        pendingMemberNumberOwner(_memberNumber)
        memberMumberTransferKeyMatches(_memberNumber, _keyHash)
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