pragma solidity ^0.4.23;

import "./EternalStorage.sol";

library VehicleManufacturerStorage {

    function storeManufacturer (
        address _storageAccount, 
        bytes32 _name,
        address _owner, 
        bool _enabled) 
        public {

        setName(_storageAccount, _name);
        setOwner(_storageAccount, _name, _owner);
        setEnabled(_storageAccount, _name, _enabled);
    }

    function getName(address _storageAccount, bytes32 _name) public view returns(bytes32) {

        return EternalStorage(_storageAccount).getBytes32Value(keccak256(abi.encodePacked(_name, "name")));
    }

    function getOwner(address _storageAccount, bytes32 _name) public view returns(address) {

        return EternalStorage(_storageAccount).getAddressValue(keccak256(abi.encodePacked(_name, "owner")));
    } 

    function getEnabled(address _storageAccount, bytes32 _name) public view returns(bool) {

        return EternalStorage(_storageAccount).getBooleanValue(keccak256(abi.encodePacked(_name, "enabled")));
    }           

    function exists(address _storageAccount, bytes32 _name) public view returns(bool) {
        return EternalStorage(_storageAccount).getAddressValue(keccak256(abi.encodePacked(_name, "owner"))) > 0;
    } 

      
    function getTransferKey(address _storageAccount, bytes32 _name) public view returns(bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(keccak256(abi.encodePacked(_name, "transferKey")));
    }    

    function getPendingOwner(address _storageAccount, bytes32 _name) public view returns(address) {
        return EternalStorage(_storageAccount).getAddressValue(keccak256(abi.encodePacked(_name, "pendingOwner")));
    } 

    function setName(address _storageAccount, bytes32 _name) public {
        return EternalStorage(_storageAccount).setBytes32Value(keccak256(abi.encodePacked(_name, "name")), _name);
    }    

    function setOwner(address _storageAccount, bytes32 _name, address _owner) public {
        return EternalStorage(_storageAccount).setAddressValue(keccak256(abi.encodePacked(_name, "owner")), _owner);
    } 

    function setEnabled(address _storageAccount, bytes32 _name, bool _enabled) public {
        return EternalStorage(_storageAccount).setBooleanValue(keccak256(abi.encodePacked(_name, "enabled")), _enabled);
    }          

    function setPendingOwner(address _storageAccount, bytes32 _name, address _pendingOwner) public {
        return EternalStorage(_storageAccount).setAddressValue(keccak256(abi.encodePacked(_name, "pendingOwner")), _pendingOwner);
    }   

    function setTransferKey(address _storageAccount, bytes32 _name, bytes32 _keyHash) public {
        return EternalStorage(_storageAccount).setBytes32Value(keccak256(abi.encodePacked(_name, "transferKey")), _keyHash);
    }    

}