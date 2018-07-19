pragma solidity ^0.4.23;

import "./EternalStorage.sol";

/** @title Registry Storage Library
  * @dev Sets and Gets storage data from an eternal storage contract
 */
library RegistryStorageLib {

    /** @dev A struct describing a registry member */
    struct Member {
        uint256 memberNumber;
        bytes32 memberId;
        address owner;
        bool enabled;
        uint256 created;
    }

    /** @dev a struct describing an attribute of a member */
    struct Attribute {
        uint256 memberNumber;
        uint256 attributeNumber;
        bytes32 attributeType;
        bytes32 name;
        bytes32 value;
    }

    /** @dev adds a member to the registry.
      * @param _storageAccount the address of the eternal storage contract.
      * @param _memberId the member id (user allocated - should be unique)
      * @param _owner the address of the member owner
      * @return the registry storage allocated member number
       */
    function storeMember (
        address _storageAccount, 
        bytes32 _memberId,
        address _owner) 
        public
        returns (uint256) {

        uint256 currentCount = getMemberTotalCount(_storageAccount);
        uint256 memberNumber = currentCount + 1;
        
        setMemberNumber(_storageAccount, _memberId, memberNumber);
        setMemberId(_storageAccount, memberNumber, _memberId);
        setMemberOwner(_storageAccount, memberNumber, _owner);
        setMemberEnabled(_storageAccount, memberNumber, true);
        setMemberCreated(_storageAccount, memberNumber, now);

        setMemberTotalCount(_storageAccount, memberNumber);
        return memberNumber;
    }

    /** @dev adds an attribute to a member of the registry
      * @param _storageAccount the address of the eternal storage contract.
      * @param _memberNumber the registry storage allocated member number
      * @param _attributeName the user definied attribute name (should be unique to member)
      * @param _attributeType the user definied attribute type (for grouping attributes)
      * @param _val the user definied attribute value
      * @return the registry storage allocated attribute number
     */
    function storeMemberAttribute (
        address _storageAccount,
        uint256 _memberNumber,
        bytes32 _attributeName,
        bytes32 _attributeType,
        bytes32 _val) 
        public 
        returns (uint256) {

        uint256 currentCount = getAttributeTotalCount(_storageAccount, _memberNumber);
        uint256 attributeNumber = currentCount + 1;

        setAttributeNumber(_storageAccount, _memberNumber, _attributeName, attributeNumber);
        setAttributeName(_storageAccount, _memberNumber, attributeNumber, _attributeName);
        setAttributeType(_storageAccount, _memberNumber, attributeNumber, _attributeType);
        setAttributeValue(_storageAccount, _memberNumber, attributeNumber, _val);

        setAttributeTotalCount(_storageAccount, _memberNumber, attributeNumber);
        return attributeNumber;
    }

    /** @dev adds a new or sets (if already exists) an attribute in storage.
      * If the attribute exists, the new type and value are stored
      * @param _storageAccount the address of the eternal storage contract.
      * @param _memberNumber the registry storage allocated member number
      * @param _attributeName the user definied attribute name (should be unique to member)
      * @param _attributeType the user definied attribute type (for grouping attributes)
      * @param _val the user definied attribute value
      * @return the registry storage allocated attribute number    
    */
    function storeOrSetAttribute (
        address _storageAccount,
        uint256 _memberNumber,
        bytes32 _attributeName,
        bytes32 _attributeType,
        bytes32 _val
    )
        public 
        returns (uint256) {
        uint256 attributeNumber = getAttributeNumber(_storageAccount, _memberNumber, _attributeName);
        if(attributeNumber == 0){
            storeMemberAttribute(_storageAccount, _memberNumber, _attributeName, _attributeType, _val);
        }
        else{
            setAttribute(_storageAccount, _memberNumber, attributeNumber, _attributeType, _val);
        }
    }

    /** @dev sets the value and type on an existing attribute for a member */
    function setAttribute(address _storageAccount, uint256 _memberNumber, uint256 _attribNumber, bytes32 _type, bytes32 _val) public {
        setAttributeType(_storageAccount, _memberNumber, _attribNumber, _type);
        setAttributeValue(_storageAccount, _memberNumber, _attribNumber, _val);    
    }    

//attribute setters
//private attribute setters

    /** @dev private - updates the index of attribute number to attribute name (member specific) */
    function setAttributeNumber(address _storageAccount, uint256 _memberNumber, bytes32 _attributeName, uint256 _attribNumber) private {
        EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_memberNumber, _attributeName, "number")), _attribNumber);   
    }   

    /** @dev private - updates the index of attribute name to attribute number (member specific) */
    function setAttributeName(address _storageAccount, uint256 _memberNumber, uint256 _attribNumber, bytes32 _attributeName) private {
        EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, _attribNumber, "name")), _attributeName);   
    }      

    /** @dev private - sets the total attribute count for a member */
    function setAttributeTotalCount(address _storageAccount, uint256 _memberNumber, uint256 _count) private {
        EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_memberNumber, "attributeCount")), _count);   
    }

    /** @dev private - sets the total attribute value */
    function setAttributeValue(address _storageAccount, uint256 _memberNumber, uint256 _attribNumber, bytes32 _val) private {
        EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, _attribNumber, "value")), _val);   
    } 

    /** @dev private - sets the total attribute type */
    function setAttributeType(address _storageAccount, uint256 _memberNumber, uint256 _attribNumber, bytes32 _type) private {
        EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, _attribNumber, "type")), _type);   
    }        

//attribute getters

    /** @dev Returns a boolean indicating if the attribute number exists against a member */
    function attributeNumberExists(address _storageAccount, uint256 _memberNumber, uint256 _attributeNumber) public view returns (bool) {
        return 
            memberNumberExists(_storageAccount, _memberNumber) && _attributeNumber > 0 && _attributeNumber <= getAttributeTotalCount(_storageAccount, _memberNumber);
    }

    /** @dev Returns the number of attributes stored against a member */
    function getAttributeTotalCount(address _storageAccount, uint256 _memberNumber) 
        public view returns(uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_memberNumber, "attributeCount")));   
    }   

    /** @dev Returns an Attribute struct for a specific attribute (by number) stored against a member (internal because it is a struct) */
    function getAttribute(address _storageAccount, uint256 _memberNumber, uint256 _attributeNumber) 
        internal view returns (Attribute memory) 
        {
        Attribute memory attribute = Attribute({
            memberNumber: _memberNumber,
            attributeNumber: _attributeNumber,
            attributeType: getAttributeType(_storageAccount, _memberNumber, _attributeNumber),
            name: getAttributeName(_storageAccount, _memberNumber, _attributeNumber),
            value: getAttributeValue(_storageAccount, _memberNumber, _attributeNumber)
        });
        return attribute;
    }    

    /** @dev Returns an Attribute struct for a specific attribute (by name) stored against a member (internal because it is a struct) */
    function getAttribute(address _storageAccount, uint256 _memberNumber, bytes32 _attributeName) 
        internal view returns (Attribute) {
        uint256 attributeNumber = getAttributeNumber(_storageAccount, _memberNumber, _attributeName);
        Attribute memory attribute = getAttribute(_storageAccount, _memberNumber, attributeNumber);
        return attribute;
    }

    /** @dev Returns the attribute number belonging to an attribute name for a member */
    function getAttributeNumber(address _storageAccount, uint256 _memberNumber, bytes32 _attributeName) 
        public view returns(uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_memberNumber, _attributeName, "number")));   
    }

    /** @dev Returns the attribute name belonging to an attribute number for a member */
    function getAttributeName(address _storageAccount,  uint256 _memberNumber, uint256 _attribNumber) 
        public view returns(bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, _attribNumber, "name")));   
    }

    /** @dev Returns the attribute value belonging to an attribute number for a member */
    function getAttributeValue(address _storageAccount,  uint256 _memberNumber, uint256 _attribNumber) 
        public view returns(bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, _attribNumber, "value")));   
    }

    /** @dev Returns the attribute type belonging to an attribute number for a member */
    function getAttributeType(address _storageAccount,  uint256 _memberNumber, uint256 _attribNumber) 
        public view returns(bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, _attribNumber, "type")));   
    }    

//getters
    /** @dev Returns a total count of members in the registry */
    function getMemberTotalCount(address _storageAccount) public view returns(uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked("totalMemberCount")));
    } 

//member getters
    /** @dev Returns true if a member number exists in the regisry */
    function memberNumberExists(address _storageAccount, uint256 _memberNumber) public view returns(bool) {
        return
            _memberNumber > 0 && _memberNumber <= getMemberTotalCount(_storageAccount) && getMemberOwner(_storageAccount, _memberNumber) != 0;
    }     

    /** @dev Returns a Member struct for a member (internal because it returns a struct) */
    function getMember(address _storageAccount, uint256 _memberNumber)
        internal view returns (Member) {
        Member memory m = Member(
            {memberNumber: _memberNumber,
            memberId: getMemberId(_storageAccount, _memberNumber),
            owner: getMemberOwner(_storageAccount, _memberNumber),
            enabled: getMemberEnabled(_storageAccount, _memberNumber),
            created: getMemberCreated(_storageAccount, _memberNumber)}
        );            
        return m;
    }    

    /** @dev Returns the member number belonging to the member Id */
    function getMemberNumber(address _storageAccount, bytes32 _memberId) public view returns(uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_memberId, "number")));
    }

    /** @dev Returns the member id belonging to the member number */
    function getMemberId(address _storageAccount, uint256 _memberNumber) public view returns(bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, "id")));
    }    

    /** @dev Returns the address of the owner of the member */
    function getMemberOwner(address _storageAccount, uint256 _memberNumber) public view returns(address) {
        return EternalStorage(_storageAccount).getAddressValue(
            keccak256(abi.encodePacked(_memberNumber, "owner")));
    } 

    /** @dev Returns true if the member is enabled */
    function getMemberEnabled(address _storageAccount, uint256 _memberNumber) public view returns(bool) {
        return EternalStorage(_storageAccount).getBooleanValue(
            keccak256(abi.encodePacked(_memberNumber, "enabled")));
    }   

    /** @dev Returns the date the member was added to the registry */
    function getMemberCreated(address _storageAccount, uint256 _memberNumber) public view returns(uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_memberNumber, "created")));
    }               

    /** @dev Returns the transferKeyHash for a member (set when the current owner transfers) */
    function getMemberTransferKeyHash(address _storageAccount, uint256 _memberNumber) public view returns(bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, "transferKeyHash")));
    }    

    /** @dev Returns the address of the pending owner of the member */
    function getMemberPendingOwner(address _storageAccount, uint256 _memberNumber) public view returns(address) {
        return EternalStorage(_storageAccount).getAddressValue(
            keccak256(abi.encodePacked(_memberNumber, "pendingOwner")));
    } 

//private setters
    /** @dev links member id to member number (private) */
    function setMemberNumber(address _storageAccount, bytes32 _memberId, uint _memberNumber) private {
        EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_memberId, "number")), _memberNumber);
    }    

    /** @dev links member number to member id (private) */
    function setMemberId(address _storageAccount, uint256 _memberNumber, bytes32 _memberId) private {
        EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, "id")), _memberId);
    }

    /** @dev Sets the total member count in the registry */
    function setMemberTotalCount(address _storageAccount, uint256 _count) private {
        EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked("totalMemberCount")), _count);
    } 

    /** @dev Set the date the member was added to the registry (private). */
    function setMemberCreated(address _storageAccount, uint256 _memberNumber, uint256 _created) private {
        EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_memberNumber, "created")), _created);
    }       

//public setters

    /** @dev Set the address of the owner of the member. */
    function setMemberOwner(address _storageAccount, uint256 _memberNumber, address _owner) public {
        EternalStorage(_storageAccount).setAddressValue(
            keccak256(abi.encodePacked(_memberNumber, "owner")), _owner);
    } 

    /** @dev Set the enabled flag of the member. */
    function setMemberEnabled(address _storageAccount, uint256 _memberNumber, bool _enabled) public {
        EternalStorage(_storageAccount).setBooleanValue(
            keccak256(abi.encodePacked(_memberNumber, "enabled")), _enabled);
    } 

    /** @dev Sets the address of the pending owner of the member */
    function setMemberPendingOwner(address _storageAccount, uint256 _memberNumber, address _pendingOwner) public {
        EternalStorage(_storageAccount).setAddressValue(
            keccak256(abi.encodePacked(_memberNumber, "pendingOwner")), _pendingOwner);
    }   

    /** @dev Sets the transfer key hash for the member */
    function setMemberTransferKeyHash(address _storageAccount, uint256 _memberNumber, bytes32 _keyHash) public {
        EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, "transferKeyHash")), _keyHash);
    }    

}