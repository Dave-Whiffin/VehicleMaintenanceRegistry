pragma solidity ^0.4.23;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "./VehicleManufacturerStorage.sol";
import "./IVehicleManufacturerRegistry.sol";

contract VehicleManufacturerRegistry is IVehicleManufacturerRegistry, Claimable {

    address private vehicleManufacturerStorageAddress;

    constructor(address _vehicleManufacturerStorageAddress) public {
        vehicleManufacturerStorageAddress = _vehicleManufacturerStorageAddress;
    }

    event ManufacturerRegistered(bytes32 indexed _name);
    event ManufacturerEnabled(bytes32 indexed indexed _name);
    event ManufacturerDisabled(bytes32 indexed _name);
    event ManufacturerOwnershipTransferRequest(bytes32 indexed _name, address indexed _from, address indexed _to);
    event ManufacturerOwnershipTransferAccepted(bytes32 indexed _name, address indexed _newOwner);

    modifier isARegisteredManufacturer(bytes32 _name) {
        require(VehicleManufacturerStorage.exists(vehicleManufacturerStorageAddress, _name), "Manufacturer must be registered");
        _;
    }

    modifier manufacturerMustBeEnabled(bytes32 _name) {
        require(VehicleManufacturerStorage.getEnabled(vehicleManufacturerStorageAddress, _name), "Manufacturer must be enabled");
        _;
    }  

    modifier manufacturerIsNotRegistered(bytes32 _name) {
        require(!VehicleManufacturerStorage.exists(vehicleManufacturerStorageAddress, _name), "Manufacturer must not already be registered");
        _;
    }

    modifier onlyManufacturerOwner(bytes32 _name) {
        require(
            VehicleManufacturerStorage.getOwner(vehicleManufacturerStorageAddress, _name) == msg.sender, 
            "Only the owner of the manufacturer can perform this task");
        _;
    }

    modifier onlyPendingManufacturerOwner(bytes32 _name) {
        require(
            VehicleManufacturerStorage.getPendingOwner(vehicleManufacturerStorageAddress, _name) == msg.sender, 
            "Only the pending owner of the manufacturer can perform this task");
        _;
    }    

    modifier manufacturerTransferKeyMatches(bytes32 _name, bytes32 _keyHash) {
        bytes32 transferKey = VehicleManufacturerStorage.getTransferKey(vehicleManufacturerStorageAddress, _name);
        require(transferKey == _keyHash, "The key provided must match the existing transfer key");
        _;        
    }       

    function isRegistered(bytes32 _name) external view returns (bool) {
        return VehicleManufacturerStorage.exists(vehicleManufacturerStorageAddress, _name);
    }

    function isEnabled(bytes32 _name) external view returns (bool) {
        return VehicleManufacturerStorage.getEnabled(vehicleManufacturerStorageAddress, _name);
    }

    function registerManufacturer(bytes32 _name, address _owner) 
        external payable
        onlyOwner()
        manufacturerIsNotRegistered(_name)
         {
        VehicleManufacturerStorage.storeManufacturer(vehicleManufacturerStorageAddress, _name, address(this), true);
        if(_owner != address(this)){
            VehicleManufacturerStorage.setPendingOwner(vehicleManufacturerStorageAddress, _name, _owner);
        }
        emit ManufacturerRegistered(_name);
    }

    function disableManufacturer(bytes32 _name) 
        external payable
        onlyOwner()
         {
        VehicleManufacturerStorage.setEnabled(vehicleManufacturerStorageAddress, _name, false);    
        emit ManufacturerDisabled(_name);
    }

    function enableManufacturer(bytes32 _name) 
        external payable 
        onlyOwner()
        {
        VehicleManufacturerStorage.setEnabled(vehicleManufacturerStorageAddress, _name, true);    
        emit ManufacturerEnabled(_name);
    }

    function transferManufacturerOwnership(bytes32 _name, address _newOwner, bytes32 _keyHash) 
        external payable 
        onlyManufacturerOwner(_name)
        {
        address currentOwner = VehicleManufacturerStorage.getOwner(vehicleManufacturerStorageAddress, _name);  
        VehicleManufacturerStorage.setPendingOwner(vehicleManufacturerStorageAddress, _name, _newOwner);  
        VehicleManufacturerStorage.setTransferKey(vehicleManufacturerStorageAddress, _name, _keyHash);  
        emit ManufacturerOwnershipTransferRequest(_name, currentOwner, _newOwner);
    }

    function acceptManufacturerOwnership(bytes32 _name, bytes32 _keyHash) 
        external payable
        onlyPendingManufacturerOwner(_name)
        manufacturerTransferKeyMatches(_name, _keyHash)
         {
        VehicleManufacturerStorage.setOwner(vehicleManufacturerStorageAddress, _name, msg.sender);
        emit ManufacturerOwnershipTransferAccepted(_name, msg.sender);
    } 
}