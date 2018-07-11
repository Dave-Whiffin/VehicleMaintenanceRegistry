pragma solidity ^0.4.23;

interface IRegistry {

//payable
    function registerMember(bytes32 _memberId) external payable returns (uint256);
    function enableMember(uint256 _memberNumber) external payable;
    function disableMember(uint256 _memberNumber) external payable;

    function transferMemberOwnership(uint256 _memberNumber, address _newOwner, bytes32 _keyHash) external payable;
    function acceptMemberOwnership(uint256 _memberNumber, bytes32 _keyHash) external payable;

    function addMemberAttribute(uint256 _memberNumber, bytes32 _attributeName, bytes32 _attributeType, bytes32 _attributeValue) 
        external payable returns (uint256);

    function setMemberAttribute(uint256 _memberNumber, uint256 _attributeNumber, bytes32 _attributeType, bytes32 _attributeValue) 
        external payable;

//member getters
    function getMemberTotalCount() external view returns (uint256);
    function isMemberRegistered(uint256 _memberNumber) external view returns (bool);
    function getMemberNumber(bytes32 _memberId) external view returns (uint256);
    function getMember(uint256 _memberNumber) 
        external view returns (uint256 memberNumber, bytes32 memberId, address owner, bool enabled);

//attribute getters    
    function getMemberAttributeTotalCount(uint256 _memberNumber) external view returns (uint256);
    function getMemberAttributeNumber(uint256 _memberNumber, bytes32 _attributeName) external view returns (uint256);
    function getMemberAttribute(uint256 _memberNumber, uint256 _attributeNumber) 
        external view returns (uint256 attributeNumber, bytes32 attributeName, bytes32 attributeType, bytes32 attributeValue);

}