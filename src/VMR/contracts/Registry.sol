pragma solidity ^0.4.23;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/TokenDestructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./RegistryStorageLib.sol";
import "./ByteUtilsLib.sol";
import "./IRegistryFeeLookup.sol";

contract Registry is Claimable, TokenDestructible, Pausable {

    struct Member {
        uint256 memberNumber;
        bytes32 memberId;
        address owner;
        bool enabled;
    }

    using ByteUtilsLib for bytes32;
    
    event MemberRegistered(uint256 indexed memberNumber, bytes32 indexed memberId);
    event MemberEnabled(uint256 indexed memberNumber);
    event MemberDisabled(uint256 indexed memberNumber);
    event MemberOwnershipTransferRequest(uint256 indexed memberNumber, address indexed from, address indexed to);
    event MemberOwnershipTransferAccepted(uint256 indexed memberNumber, address indexed newOwner);
    event MemberAttributeChanged(uint256 indexed memberNumber, 
    uint256 indexed attributeNumber, bytes32 indexed attributeName, bytes32 attributeType, bytes32 attributeValue);

    address internal storageAddress;
    address internal feeLookupAddress;

    constructor(address _storageAddress, address _feeLookupAddress) public {
        storageAddress = _storageAddress;
        feeLookupAddress = _feeLookupAddress;
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

    modifier paidMemberRegistrationFee() {
        require(getMemberRegistrationFee() <= msg.value, "Value is below registration fee");
        _;
    }

    modifier paidMemberTransferFee() {
        require(getMemberTransferFee() <= msg.value, "Value is below registration transfer fee");
        _;
    }

    modifier senderAllowedToRegisterMember() {
        require(isAllowedToRegisterMember(msg.sender), "The sender is not allowed to register");
        _;
    }

    //interception point for contracts inheriting from this
    function isAllowedToRegisterMember(address _address) public view returns (bool) {
        return _address == owner;
    }

    function getStorageAddress() 
        public view 
        returns(address) {
        return storageAddress;
    }

    function setStorageAddress(address _storageAddress) 
        public
        onlyOwner() 
        whenPaused() {
        require(_storageAddress != storageAddress, "Storage address must be a different address");
        storageAddress = _storageAddress;
    }

    function setFeeLookupAddress(address _feeLookupAddress) 
        public
        onlyOwner() 
        whenPaused()
         {
        require(_feeLookupAddress != feeLookupAddress, "Fee Lookup address must be a different address");
        feeLookupAddress = _feeLookupAddress;
    }

    function getMemberRegistrationFee() public view returns (uint256) {
        return IRegistryFeeLookup(feeLookupAddress).getRegistrationFeeWei();
    }

    function getMemberTransferFee() public view returns (uint256) {
        return IRegistryFeeLookup(feeLookupAddress).getTransferFeeWei();
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
        returns (uint256 memberNumber, bytes32 memberId, address owner, bool enabled) {
        
        Member memory member = getMemberInternal(_memberNumber);
        memberNumber = member.memberNumber;
        memberId = member.memberId;
        owner = member.owner;
        enabled = member.enabled;
    }

    function getMemberInternal(uint256 _memberNumber)
        internal view returns (Member) {
        Member memory m = Member(
            _memberNumber,
            RegistryStorageLib.getMemberId(storageAddress, _memberNumber),
            RegistryStorageLib.getMemberOwner(storageAddress, _memberNumber),
            RegistryStorageLib.getMemberEnabled(storageAddress, _memberNumber)
        );            
        return m;
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
        attributeNumber = _attributeNumber;
        attributeName = RegistryStorageLib.getAttributeName(storageAddress, _memberNumber, _attributeNumber);
        attributeType = RegistryStorageLib.getAttributeType(storageAddress, _memberNumber, _attributeNumber);
        attributeValue = RegistryStorageLib.getAttributeValue(storageAddress, _memberNumber, _attributeNumber);
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

        RegistryStorageLib.setAttributeType(storageAddress, _memberNumber, _attributeNumber, _attributeType);
        RegistryStorageLib.setAttributeValue(storageAddress, _memberNumber, _attributeNumber, _attributeValue);

        bytes32 attributeName = RegistryStorageLib.getAttributeName(storageAddress, _memberNumber, _attributeNumber);        

        emit MemberAttributeChanged(_memberNumber, _attributeNumber, attributeName, _attributeType, _attributeValue);
    }      

    function setMemberAttributeValue(uint256 _memberNumber, uint256 _attributeNumber, bytes32 _attributeValue) 
        public payable 
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