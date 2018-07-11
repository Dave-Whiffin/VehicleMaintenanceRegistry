pragma solidity ^0.4.23;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/TokenDestructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./RegistryStorageLib.sol";
import "./IRegistry.sol";
import "./ByteUtils.sol";

contract Registry is IRegistry, Claimable, TokenDestructible, Pausable {

    using ByteUtils for bytes32;
    
    event MemberRegistered(uint256 indexed memberNumber, bytes32 indexed memberId);
    event MemberEnabled(uint256 indexed memberNumber);
    event MemberDisabled(uint256 indexed memberNumber);
    event MemberOwnershipTransferRequest(uint256 indexed memberNumber, address indexed from, address indexed to);
    event MemberOwnershipTransferAccepted(uint256 indexed memberNumber, address indexed newOwner);
    event MemberAttributeChanged(uint256 indexed memberNumber, 
    uint256 indexed attributeNumber, bytes32 indexed attributeName, bytes32 attributeType, bytes32 attributeValue);

    address private storageAddress;

    constructor(address _storageAddress) public {
        storageAddress = _storageAddress;
    }

    modifier memberIdRegistered(bytes32 _memberId) {
        require(RegistryStorageLib.memberNumberExists(storageAddress, getMemberNum(_memberId)), "Member must be registered");
        _;
    }

    modifier memberNumberRegistered(uint256 _memberNumber) {
        require(RegistryStorageLib.memberNumberExists(storageAddress, _memberNumber), "Member must be registered");
        _;
    }

    modifier memberIdEnabled(bytes32 _memberId) {
        require(RegistryStorageLib.getMemberEnabled(storageAddress, getMemberNum(_memberId)), "Member must be enabled");
        _;
    }

    modifier memberNumberEnabled(uint256 _memberNumber) {
        require(RegistryStorageLib.getMemberEnabled(storageAddress, _memberNumber), "Member must be enabled");
        _;
    }    

    modifier memberIdDisabled(bytes32 _memberId) {
        require(!RegistryStorageLib.getMemberEnabled(storageAddress, getMemberNum(_memberId)), "Member must be disabled");
        _;
    }    

    modifier memberNumberDisabled(uint256 _memberNumber) {
        require(!RegistryStorageLib.getMemberEnabled(storageAddress, _memberNumber), "Member must be disabled");
        _;
    }          

    modifier memberIdNotRegistered(bytes32 _memberId) {
        require(!RegistryStorageLib.memberNumberExists(storageAddress, getMemberNum(_memberId)), "Member must not already be registered");
        _;
    }

    modifier memberNumberNotRegistered(uint256 _memberNumber) {
        require(!RegistryStorageLib.memberNumberExists(storageAddress, _memberNumber), "Member must not already be registered");
        _;
    }    

    modifier memberIdOwner(bytes32 _memberId) {
        require(
            RegistryStorageLib.getMemberOwner(storageAddress, getMemberNum(_memberId)) == msg.sender, 
            "Only the owner of the member can perform this task");
        _;
    }

    modifier memberNumberOwner(uint256 _memberNumber) {
        require(
            RegistryStorageLib.getMemberOwner(storageAddress, _memberNumber) == msg.sender, 
            "Only the owner of the member can perform this task");
        _;
    }    

    modifier pendingMemberNumberOwner(uint256 _memberNumber) {
        require(
            RegistryStorageLib.getMemberPendingOwner(storageAddress, _memberNumber) == msg.sender, 
            "Only the pending owner of the member can perform this task");
        _;
    }        

    modifier memberMumberTransferKeyMatches(uint256 _memberNumber, bytes32 _keyHash) {
        bytes32 transferKey = RegistryStorageLib.getMemberTransferKey(storageAddress, _memberNumber);
        require(transferKey == _keyHash, "The key provided must match the existing transfer key");
        _;        
    }

    modifier attributeNameDoesNotExist(uint256 _memberNumber, bytes32 _attribName) {
        require(RegistryStorageLib.getAttributeNumber(storageAddress, _memberNumber, _attribName) == 0, "Attribute name must not already exist");
        _;
    }

    modifier attributeNameExists(uint256 _memberNumber, bytes32 _attribName) {
        require(RegistryStorageLib.getAttributeNumber(storageAddress, _memberNumber, _attribName) > 0, "Attribute name must exist");
        _;
    }   

    modifier attributeNumberExists(uint256 _memberNumber, uint256 _attributeNumber) {
        require(RegistryStorageLib.attributeNumberExists(storageAddress, _memberNumber, _attributeNumber), "Attribute number must exist");
        _;
    }        

    function getStorageAddress() 
        public view 
        returns(address) {
        return storageAddress;
    }      

//member related getters
    function getMemberTotalCount() 
        external view 
        returns (uint256) {
        return RegistryStorageLib.getMemberTotalCount(storageAddress);
    }

    function isMemberRegistered(uint256 _memberNumber) 
        external view 
        returns (bool) {
        return RegistryStorageLib.memberNumberExists(storageAddress, _memberNumber);
    } 

    function getMemberNumber(bytes32 _memberId) 
        external view 
        memberIdRegistered(_memberId)
        returns (uint256) {
        return getMemberNum(_memberId);
    }

    function getMember(uint256 _memberNumber) 
        external view
        memberNumberRegistered(_memberNumber)
        returns (uint256 memberNumber, bytes32 memberId, address owner, bool enabled) {

        memberNumber = _memberNumber;
        memberId = RegistryStorageLib.getMemberId(storageAddress, _memberNumber);
        owner = RegistryStorageLib.getMemberOwner(storageAddress, _memberNumber);
        enabled = RegistryStorageLib.getMemberEnabled(storageAddress, _memberNumber);
    }
 
    function getMemberAttributeTotalCount(uint256 _memberNumber) 
        external view
        memberNumberRegistered(_memberNumber)
        returns (uint256) {
        return RegistryStorageLib.getAttributeTotalCount(storageAddress, _memberNumber);
    }

    function getMemberAttributeNumber(uint256 _memberNumber, bytes32 _attributeName) 
        external view
        memberNumberRegistered(_memberNumber)
        attributeNameExists(_memberNumber, _attributeName)
        returns (uint256) {
        return RegistryStorageLib.getAttributeNumber(storageAddress, _memberNumber, _attributeName);
    }    

    function getMemberAttribute(uint256 _memberNumber, uint256 _attributeNumber) 
        memberNumberRegistered(_memberNumber)
        attributeNumberExists(_memberNumber, _attributeNumber)    
        external view returns 
        (uint256 attributeNumber, bytes32 attributeName, bytes32 attributeType, bytes32 attributeValue) 
        {
        attributeNumber = _attributeNumber;
        attributeName = RegistryStorageLib.getAttributeName(storageAddress, _memberNumber, _attributeNumber);
        attributeType = RegistryStorageLib.getAttributeType(storageAddress, _memberNumber, _attributeNumber);
        attributeValue = RegistryStorageLib.getAttributeValue(storageAddress, _memberNumber, _attributeNumber);
    }

//payable
    function registerMember(bytes32 _memberId) 
        external payable
        whenNotPaused()
        onlyOwner()
        memberIdNotRegistered(_memberId)
        returns (uint256) {
        uint256 memberNumber = RegistryStorageLib.storeMember(storageAddress, _memberId, owner);
        emit MemberRegistered(memberNumber, _memberId);
        return memberNumber;
    }

    function enableMember(uint256 _memberNumber) 
        external payable 
        whenNotPaused()
        onlyOwner()
        memberNumberRegistered(_memberNumber)
        memberNumberDisabled(_memberNumber)
        {     
        RegistryStorageLib.setMemberEnabled(storageAddress, _memberNumber, true);    
        emit MemberEnabled(_memberNumber);
    }        

    function disableMember(uint256 _memberNumber) 
        external payable
        whenNotPaused()
        onlyOwner()
        memberNumberRegistered(_memberNumber)
        memberNumberEnabled(_memberNumber)
         {
        RegistryStorageLib.setMemberEnabled(storageAddress, _memberNumber, false);    
        emit MemberDisabled(_memberNumber);
    }

    function transferMemberOwnership(uint256 _memberNumber, address _newOwner, bytes32 _keyHash) 
        external payable 
        whenNotPaused()
        memberNumberRegistered(_memberNumber)
        memberNumberOwner(_memberNumber)
        { 
        address currentOwner = RegistryStorageLib.getMemberOwner(storageAddress, _memberNumber);  
        RegistryStorageLib.setMemberPendingOwner(storageAddress, _memberNumber, _newOwner);  
        RegistryStorageLib.setMemberTransferKey(storageAddress, _memberNumber, _keyHash);  
        emit MemberOwnershipTransferRequest(_memberNumber, currentOwner, _newOwner);
    }

    function acceptMemberOwnership(uint256 _memberNumber, bytes32 _keyHash) 
        external payable
        whenNotPaused()
        memberNumberRegistered(_memberNumber)
        pendingMemberNumberOwner(_memberNumber)
        memberMumberTransferKeyMatches(_memberNumber, _keyHash)
         {  
        RegistryStorageLib.setMemberOwner(storageAddress, _memberNumber, msg.sender);
        emit MemberOwnershipTransferAccepted(_memberNumber, msg.sender);
    }     

    function addMemberAttribute(uint256 _memberNumber, bytes32 _attributeName, bytes32 _attributeType, bytes32 _attributeValue) 
        external payable 
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
        external payable 
        whenNotPaused()
        onlyOwner()
        memberNumberRegistered(_memberNumber)
        attributeNumberExists(_memberNumber, _attributeNumber) {

        RegistryStorageLib.setAttributeType(storageAddress, _memberNumber, _attributeNumber, _attributeType);
        RegistryStorageLib.setAttributeValue(storageAddress, _memberNumber, _attributeNumber, _attributeValue);

        bytes32 attributeName = RegistryStorageLib.getAttributeName(storageAddress, _memberNumber, _attributeNumber);        

        emit MemberAttributeChanged(_memberNumber, _attributeNumber, attributeName, _attributeType, _attributeValue);
    }      

    function setMemberAttributeValue(uint256 _memberNumber, uint256 _attributeNumber, bytes32 _attributeValue) 
        external payable 
        whenNotPaused()
        onlyOwner()
        memberNumberRegistered(_memberNumber)
        attributeNumberExists(_memberNumber, _attributeNumber) {

        RegistryStorageLib.setAttributeValue(storageAddress, _memberNumber, _attributeNumber, _attributeValue);

        bytes32 attributeType = RegistryStorageLib.getAttributeType(storageAddress, _memberNumber, _attributeNumber);
        bytes32 attributeName = RegistryStorageLib.getAttributeName(storageAddress, _memberNumber, _attributeNumber);        

        emit MemberAttributeChanged(_memberNumber, _attributeNumber, attributeName, attributeType, _attributeValue);
    } 

    function getMemberNum(bytes32 _memberId) 
        private view 
        returns (uint256) {
        return RegistryStorageLib.getMemberNumber(storageAddress, _memberId);  
    }   
}