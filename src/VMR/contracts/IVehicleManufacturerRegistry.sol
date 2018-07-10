pragma solidity ^0.4.23;

interface IVehicleManufacturerRegistry {

    function registerManufacturer(bytes32 _name) external payable returns (uint256);
    function disableManufacturer(bytes32 _name) external payable;
    function enableManufacturer(bytes32 _name) external payable;
    function addAttribute(bytes32 _name, bytes32 _attributeName, string _val) external payable returns (uint256);
    function setAttributeValue(bytes32 _name, bytes32 _attributeName, string _val) external payable;

    function transferManufacturerOwnership(bytes32 _name, address _newOwner, bytes32 _keyHash) external payable;
    function acceptManufacturerOwnership(bytes32 _VIN, bytes32 _keyHash) external payable;    

    function getManufacturerOwner(bytes32 _name) external view returns (address);
    function isRegistered(bytes32 _name) external view returns (bool);
    function isEnabled(bytes32 _name) external view returns (bool);
    function getCount() external view returns (uint256);
    function getName(uint256 _number) external view returns (bytes32);
    function getNumber(bytes32 _name) external view returns (uint256);
    function getAttributeCount(bytes32 _name) external view returns (uint256);
    function getAttributeName(bytes32 _name, uint256 _attributeNumber) external view returns (bytes32);
    function getAttributeValue(bytes32 _name, uint256 _attributeNumber) external view returns (string);

    event ManufacturerRegistered(bytes32 indexed name);
    event ManufacturerEnabled(bytes32 indexed name);
    event ManufacturerDisabled(bytes32 indexed name);
    event ManufacturerAttributeSet(bytes32 indexed name, bytes32 indexed attributeName, string value);    
    event ManufacturerOwnershipTransferRequest(bytes32 indexed name, address indexed from, address indexed to);
    event ManufacturerOwnershipTransferAccepted(bytes32 indexed name, address indexed newOwner);
}