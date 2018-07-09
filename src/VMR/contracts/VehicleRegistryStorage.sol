pragma solidity ^0.4.23;

import "./EternalStorage.sol";

library VehicleRegistryStorage {

    function storeVehicle (
        address _storageAccount, 
        bytes32 _VIN, 
        bytes32 _manufacturerName,        
        bytes32 _licencePlate, 
        address _owner, 
        address _maintenanceLogAddress, 
        uint256 _registered) 
        public {

        setVin(_storageAccount, _VIN);
        setManufacturerName(_storageAccount, _VIN, _manufacturerName);
        setLicencePlate(_storageAccount, _VIN, _licencePlate);
        setOwner(_storageAccount, _VIN, _owner);
        setMaintenanceLogAddress(_storageAccount, _VIN, _maintenanceLogAddress);
        setRegistered(_storageAccount, _VIN, _registered);
    }

    function getVin(address _storageAccount, bytes32 _VIN) public view returns(bytes32) {

        return EternalStorage(_storageAccount).getBytes32Value(keccak256(abi.encodePacked(_VIN, "vin")));
    }

    function getManufacturerName(address _storageAccount, bytes32 _VIN) public view returns(bytes32) {

        return EternalStorage(_storageAccount).getBytes32Value(keccak256(abi.encodePacked(_VIN, "manufacturerName")));
    }    

    function getLicencePlate(address _storageAccount, bytes32 _VIN) public view returns(bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(keccak256(abi.encodePacked(_VIN, "licencePlate")));
    }

    function getOwner(address _storageAccount, bytes32 _VIN) public view returns(address) {
        return EternalStorage(_storageAccount).getAddressValue(keccak256(abi.encodePacked(_VIN, "owner")));
    }

    function getMaintenanceLogAddress(address _storageAccount, bytes32 _VIN) public view returns(address) {
        return EternalStorage(_storageAccount).getAddressValue(keccak256(abi.encodePacked(_VIN, "maintenanceLogAddress")));
    }

    function getRegistered(address _storageAccount, bytes32 _VIN) public view returns(uint256) {
        return EternalStorage(_storageAccount).getUint256Value(keccak256(abi.encodePacked(_VIN, "registered")));
    }

    function getTransferKey(address _storageAccount, bytes32 _VIN) public view returns(bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(keccak256(abi.encodePacked(_VIN, "transferKey")));
    }    

    function getPendingOwner(address _storageAccount, bytes32 _VIN) public view returns(address) {
        return EternalStorage(_storageAccount).getAddressValue(keccak256(abi.encodePacked(_VIN, "pendingOwner")));
    }        

    function exists(address _storageAccount, bytes32 _VIN) public view returns(bool) {
        return EternalStorage(_storageAccount).getAddressValue(keccak256(abi.encodePacked(_VIN, "owner"))) > 0;
    } 

    function setVin(address _storageAccount, bytes32 _VIN) public {
        return EternalStorage(_storageAccount).setBytes32Value(keccak256(abi.encodePacked(_VIN, "vin")), _VIN);
    }  

    function setManufacturerName(address _storageAccount, bytes32 _VIN, bytes32 _manufacturerName) public {
        return EternalStorage(_storageAccount).setBytes32Value(keccak256(abi.encodePacked(_VIN, "manufacturerName")), _manufacturerName);
    }        

    function setLicencePlate(address _storageAccount, bytes32 _VIN, bytes32 _licencePlate) public {
        return EternalStorage(_storageAccount).setBytes32Value(keccak256(abi.encodePacked(_VIN, "licencePlate")), _licencePlate);
    }

    function setOwner(address _storageAccount, bytes32 _VIN, address _owner) public {
        return EternalStorage(_storageAccount).setAddressValue(keccak256(abi.encodePacked(_VIN, "owner")), _owner);
    }

    function setMaintenanceLogAddress(address _storageAccount, bytes32 _VIN, address _maintenanceLogAddress) public {
        bytes32 key = keccak256(abi.encodePacked(_VIN, "maintenanceLogAddress"));
        return EternalStorage(_storageAccount).setAddressValue(key, _maintenanceLogAddress);
    }

    function setRegistered(address _storageAccount, bytes32 _VIN, uint256 _registered) public {
        return EternalStorage(_storageAccount).setUint256Value(keccak256(abi.encodePacked(_VIN, "registered")), _registered);
    }

    function setPendingOwner(address _storageAccount, bytes32 _VIN, address _pendingOwner) public {
        return EternalStorage(_storageAccount).setAddressValue(keccak256(abi.encodePacked(_VIN, "pendingOwner")), _pendingOwner);
    }   

    function setTransferKey(address _storageAccount, bytes32 _VIN, bytes32 _keyHash) public {
        return EternalStorage(_storageAccount).setBytes32Value(keccak256(abi.encodePacked(_VIN, "transferKey")), _keyHash);
    }    

}