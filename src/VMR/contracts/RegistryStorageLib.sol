pragma solidity ^0.4.23;

import "./EternalStorage.sol";

library RegistryStorageLib {

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

        setMemberTotalCount(_storageAccount, memberNumber);
        return memberNumber;
    }

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
        setAttributeValue(_storageAccount, _memberNumber, attributeNumber, _attributeType);
        setAttributeValue(_storageAccount, _memberNumber, attributeNumber, _val);

        setAttributeTotalCount(_storageAccount, _memberNumber, attributeNumber);
        return attributeNumber;
    }

//attribute setters
//private setters
    function setAttributeNumber(address _storageAccount, uint256 _memberNumber, bytes32 _attributeName, uint256 _attribNumber) private {
        EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_memberNumber, _attributeName, "number")), _attribNumber);   
    }   

    function setAttributeName(address _storageAccount, uint256 _memberNumber, uint256 _attribNumber, bytes32 _attributeName) private {
        EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, _attribNumber, "name")), _attributeName);   
    }      

//public setters    
    
    function setAttributeTotalCount(address _storageAccount, uint256 _memberNumber, uint256 _count) public {
        EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_memberNumber, "attributeCount")), _count);   
    }

    function setAttributeValue(address _storageAccount, uint256 _memberNumber, uint256 _attribNumber, bytes32 _val) public {
        EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, _attribNumber, "value")), _val);   
    } 

    function setAttributeType(address _storageAccount, uint256 _memberNumber, uint256 _attribNumber, bytes32 _type) public {
        EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, _attribNumber, "type")), _type);   
    }        

//attribute getters

    function attributeNumberExists(address _storageAccount, uint256 _memberNumber, uint256 _attributeNumber) public view returns (bool) {
        return 
            memberNumberExists(_storageAccount, _memberNumber) && _attributeNumber > 0 && _attributeNumber <= getAttributeTotalCount(_storageAccount, _memberNumber);
    }

    function getAttributeTotalCount(address _storageAccount, uint256 _memberNumber) 
        public view returns(uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_memberNumber, "attributeCount")));   
    }   

    function getAttributeNumber(address _storageAccount, uint256 _memberNumber, bytes32 _attributeName) 
        public view returns(uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_memberNumber, _attributeName, "number")));   
    }

    function getAttributeName(address _storageAccount,  uint256 _memberNumber, uint256 _attribNumber) 
        public view returns(bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, _attribNumber, "name")));   
    }

    function getAttributeValue(address _storageAccount,  uint256 _memberNumber, uint256 _attribNumber) 
        public view returns(bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, _attribNumber, "value")));   
    }

    function getAttributeType(address _storageAccount,  uint256 _memberNumber, uint256 _attribNumber) 
        public view returns(bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, _attribNumber, "type")));   
    }    

//getters
    function getMemberTotalCount(address _storageAccount) public view returns(uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked("totalMemberCount")));
    } 

//member getters
    function memberNumberExists(address _storageAccount, uint256 _memberNumber) public view returns(bool) {
        return
            _memberNumber > 0 && _memberNumber <= getMemberTotalCount(_storageAccount) && getMemberOwner(_storageAccount, _memberNumber) != 0;
    }     

    function getMemberNumber(address _storageAccount, bytes32 _memberId) public view returns(uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_memberId, "number")));
    }

    function getMemberId(address _storageAccount, uint256 _memberNumber) public view returns(bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, "id")));
    }    

    function getMemberOwner(address _storageAccount, uint256 _memberNumber) public view returns(address) {
        return EternalStorage(_storageAccount).getAddressValue(
            keccak256(abi.encodePacked(_memberNumber, "owner")));
    } 

    function getMemberEnabled(address _storageAccount, uint256 _memberNumber) public view returns(bool) {
        return EternalStorage(_storageAccount).getBooleanValue(
            keccak256(abi.encodePacked(_memberNumber, "enabled")));
    }           

    function getMemberTransferKey(address _storageAccount, uint256 _memberNumber) public view returns(bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, "transferKey")));
    }    

    function getMemberPendingOwner(address _storageAccount, uint256 _memberNumber) public view returns(address) {
        return EternalStorage(_storageAccount).getAddressValue(
            keccak256(abi.encodePacked(_memberNumber, "pendingOwner")));
    } 

//private setters
    function setMemberNumber(address _storageAccount, bytes32 _memberId, uint _memberNumber) private {
        EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_memberId, "number")), _memberNumber);
    }    

    function setMemberId(address _storageAccount, uint256 _memberNumber, bytes32 _memberId) private {
        EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, "id")), _memberId);
    }

//public setters
    function setMemberTotalCount(address _storageAccount, uint256 _count) public {
        EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked("totalMemberCount")), _count);
    } 
   
    function setMemberOwner(address _storageAccount, uint256 _memberNumber, address _owner) public {
        EternalStorage(_storageAccount).setAddressValue(
            keccak256(abi.encodePacked(_memberNumber, "owner")), _owner);
    } 

    function setMemberEnabled(address _storageAccount, uint256 _memberNumber, bool _enabled) public {
        EternalStorage(_storageAccount).setBooleanValue(
            keccak256(abi.encodePacked(_memberNumber, "memberEnabled")), _enabled);
    }          

    function setMemberPendingOwner(address _storageAccount, uint256 _memberNumber, address _pendingOwner) public {
        EternalStorage(_storageAccount).setAddressValue(
            keccak256(abi.encodePacked(_memberNumber, "pendingOwner")), _pendingOwner);
    }   

    function setMemberTransferKey(address _storageAccount, uint256 _memberNumber, bytes32 _keyHash) public {
        EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_memberNumber, "transferKey")), _keyHash);
    }    

}