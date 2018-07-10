pragma solidity ^0.4.23;

import "./EternalStorage.sol";

library VehicleManufacturerStorage {

    function store (
        address _storageAccount, 
        bytes32 _name,
        address _owner, 
        bool _enabled) 
        public
        returns (uint256) {
        uint256 currentCount = getTotalCount(_storageAccount);
        uint256 number = currentCount + 1;
        setNumber(_storageAccount, _name, number);
        setName(_storageAccount, number, _name);
        setOwner(_storageAccount, number, _owner);
        setEnabled(_storageAccount, number, _enabled);
        setTotalCount(_storageAccount, number);
        return number;
    }

    function getTotalCount(address _storageAccount) public view returns(uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked("totalCount")));
    } 

    function getName(address _storageAccount, uint256 _number) public view returns(bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_number, "name")));
    }

    function getNumber(address _storageAccount, bytes32 _name) public view returns(uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_name, "number")));
    }

    function getOwner(address _storageAccount, uint256 _number) public view returns(address) {
        return EternalStorage(_storageAccount).getAddressValue(
            keccak256(abi.encodePacked(_number, "owner")));
    } 

    function getEnabled(address _storageAccount, uint256 _number) public view returns(bool) {
        return EternalStorage(_storageAccount).getBooleanValue(
            keccak256(abi.encodePacked(_number, "enabled")));
    }           

    function exists(address _storageAccount, uint256 _number) public view returns(bool) {
        return
            _number > 0 && _number <= getTotalCount(_storageAccount) &&
            EternalStorage(_storageAccount).getAddressValue(keccak256(abi.encodePacked(_number, "owner"))) != 0;
    } 

    function getTransferKey(address _storageAccount, uint256 _number) public view returns(bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_number, "transferKey")));
    }    

    function getPendingOwner(address _storageAccount, uint256 _number) public view returns(address) {
        return EternalStorage(_storageAccount).getAddressValue(
            keccak256(abi.encodePacked(_number, "pendingOwner")));
    } 

    function setTotalCount(address _storageAccount, uint256 _count) public {
        EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked("totalCount")), _count);
    } 

    function setName(address _storageAccount, uint256 _number, bytes32 _name) public {
        EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_number, "name")), _name);
    }

    function setNumber(address _storageAccount, bytes32 _name, uint _number) public {
        EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_name, "number")), _number);
    }     

    function setOwner(address _storageAccount, uint256 _number, address _owner) public {
        EternalStorage(_storageAccount).setAddressValue(
            keccak256(abi.encodePacked(_number, "owner")), _owner);
    } 

    function setEnabled(address _storageAccount, uint256 _number, bool _enabled) public {
        EternalStorage(_storageAccount).setBooleanValue(
            keccak256(abi.encodePacked(_number, "enabled")), _enabled);
    }          

    function setPendingOwner(address _storageAccount, uint256 _number, address _pendingOwner) public {
        EternalStorage(_storageAccount).setAddressValue(
            keccak256(abi.encodePacked(_number, "pendingOwner")), _pendingOwner);
    }   

    function setTransferKey(address _storageAccount, uint256 _number, bytes32 _keyHash) public {
        EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_number, "transferKey")), _keyHash);
    }    

}