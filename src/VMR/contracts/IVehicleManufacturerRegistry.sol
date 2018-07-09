pragma solidity ^0.4.23;

interface IVehicleManufacturerRegistry {

    function registerManufacturer(bytes32 _name, address _owner) external payable;
    function disableManufacturer(bytes32 _name) external payable;
    function enableManufacturer(bytes32 _name) external payable;

    function transferManufacturerOwnership(bytes32 _name, address _newOwner, bytes32 _keyHash) external payable;
    function acceptManufacturerOwnership(bytes32 _VIN, bytes32 _keyHash) external payable;    

    function isRegistered(bytes32 _name) external view returns (bool);
    function isEnabled(bytes32 _name) external view returns (bool);

    event ManufacturerRegistered(bytes32 indexed _name);
    event ManufacturerEnabled(bytes32 indexed _name);
    event ManufacturerDisabled(bytes32 indexed _name);    
    event ManufacturerOwnershipTransferRequest(bytes32 indexed _name, address indexed _from, address indexed _to);
    event ManufacturerOwnershipTransferAccepted(bytes32 indexed _name, address indexed _newOwner);
}