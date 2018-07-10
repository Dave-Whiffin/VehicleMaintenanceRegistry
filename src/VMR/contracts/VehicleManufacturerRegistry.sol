pragma solidity ^0.4.23;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/TokenDestructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./VehicleManufacturerStorage.sol";
import "./IVehicleManufacturerRegistry.sol";
import "./ByteUtils.sol";

contract VehicleManufacturerRegistry is IVehicleManufacturerRegistry, Claimable, TokenDestructible, Pausable {

    using ByteUtils for bytes32;

    address private storageAddress;
    
    event ManufacturerRegistered(bytes32 indexed name);
    event ManufacturerEnabled(bytes32 indexed indexed name);
    event ManufacturerDisabled(bytes32 indexed name);
    event ManufacturerAttributeSet(bytes32 indexed name, bytes32 indexed attributeName, string value);    
    event ManufacturerOwnershipTransferRequest(bytes32 indexed name, address indexed from, address indexed to);
    event ManufacturerOwnershipTransferAccepted(bytes32 indexed name, address indexed newOwner);

    constructor(address _storageAddress) public {
        storageAddress = _storageAddress;
    }

    modifier isARegisteredManufacturer(bytes32 _name) {
        require(VehicleManufacturerStorage.exists(storageAddress, getNum(_name)), "Manufacturer must be registered");
        _;
    }

    modifier isARegisteredManufacturerNumber(uint256 _number) {
        require(VehicleManufacturerStorage.exists(storageAddress, _number), "Manufacturer must be registered");
        _;
    }

    modifier manufacturerMustBeEnabled(bytes32 _name) {
        require(VehicleManufacturerStorage.getEnabled(storageAddress, getNum(_name)), "Manufacturer must be enabled");
        _;
    }

    modifier manufacturerMustBeDisabled(bytes32 _name) {
        require(!VehicleManufacturerStorage.getEnabled(storageAddress, getNum(_name)), "Manufacturer must be disabled");
        _;
    }      

    modifier manufacturerIsNotRegistered(bytes32 _name) {
        require(!VehicleManufacturerStorage.exists(storageAddress, getNum(_name)), "Manufacturer must not already be registered");
        _;
    }

    modifier onlyManufacturerOwner(bytes32 _name) {
        require(
            VehicleManufacturerStorage.getOwner(storageAddress, getNum(_name)) == msg.sender, 
            "Only the owner of the manufacturer can perform this task");
        _;
    }

    modifier onlyPendingManufacturerOwner(bytes32 _name) {
        require(
            VehicleManufacturerStorage.getPendingOwner(storageAddress, getNum(_name)) == msg.sender, 
            "Only the pending owner of the manufacturer can perform this task");
        _;
    }    

    modifier manufacturerTransferKeyMatches(bytes32 _name, bytes32 _keyHash) {
        bytes32 transferKey = VehicleManufacturerStorage.getTransferKey(storageAddress, getNum(_name));
        require(transferKey == _keyHash, "The key provided must match the existing transfer key");
        _;        
    }

    modifier attributeNameDoesNotExist(bytes32 _name, bytes32 _attribName) {
        require(VehicleManufacturerStorage.getAttributeNumber(storageAddress, getNum(_name), _attribName) == 0,
        "Attribute name must not already exist");
        _;
    }

    modifier attributeNameExists(bytes32 _name, bytes32 _attribName) {
        require(VehicleManufacturerStorage.getAttributeNumber(storageAddress, getNum(_name), _attribName) > 0,
        "Attribute name must exist");
        _;
    }    

    function getStorageAddress() 
        public view 
        returns(address) {
        return storageAddress;
    }      

    function isRegistered(bytes32 _name) 
        external view 
        returns (bool) {
        return VehicleManufacturerStorage.exists(storageAddress, getNum(_name));
    }

    function isEnabled(bytes32 _name) 
        external view 
        returns (bool) {
        return VehicleManufacturerStorage.getEnabled(storageAddress, getNum(_name));
    }

    function getCount() 
        external view 
        returns (uint256) {
        return VehicleManufacturerStorage.getTotalCount(storageAddress);
    }

    function getNumber(bytes32 _name) 
        external view 
        isARegisteredManufacturer(_name)
        returns (uint256) {
        return getNum(_name);
    }    

    function getName(uint256 _number)
        external view 
        isARegisteredManufacturerNumber(_number)
        returns (bytes32) {
        return VehicleManufacturerStorage.getName(storageAddress, _number);
    }

    function getAttributeCount(bytes32 _name) 
        external view
        isARegisteredManufacturer(_name)
        returns (uint256) {
        return VehicleManufacturerStorage.getAttributeCount(storageAddress, getNum(_name));
    }

    function getAttributeValue(bytes32 _name, uint256 _attributeNumber) 
        external view 
        isARegisteredManufacturer(_name)
        returns (string) {
        return VehicleManufacturerStorage.getAttributeValue(storageAddress, getNum(_name), _attributeNumber);
    }

    function getAttributeName(bytes32 _name, uint256 _attributeNumber) 
        external view 
        isARegisteredManufacturer(_name)
        returns (bytes32) {
        return VehicleManufacturerStorage.getAttributeName(storageAddress, getNum(_name), _attributeNumber);
    }

    function registerManufacturer(bytes32 _name) 
        external payable
        whenNotPaused()
        onlyOwner()
        manufacturerIsNotRegistered(_name)
        returns (uint256) {
        uint256 number = VehicleManufacturerStorage.store(storageAddress, _name, owner, true);
        emit ManufacturerRegistered(_name);
        return number;
    }

    function addAttribute(bytes32 _name, bytes32 _attributeName, string _val) 
        external payable 
        whenNotPaused()
        onlyOwner()
        isARegisteredManufacturer(_name)
        attributeNameDoesNotExist(_name, _attributeName)
        returns (uint256) {
        uint256 attribNumber = VehicleManufacturerStorage.storeAttribute(storageAddress, getNum(_name), _attributeName, _val);
        emit ManufacturerAttributeSet(_name, _attributeName, _val);
        return attribNumber;
    } 

    function setAttributeValue(bytes32 _name, bytes32 _attributeName, string _val) 
        external payable 
        whenNotPaused()
        onlyOwner()
        isARegisteredManufacturer(_name)
        attributeNameExists(_name, _attributeName) {
        uint256 attribNumber = VehicleManufacturerStorage.getAttributeNumber(storageAddress, getNum(_name), _attributeName);
        VehicleManufacturerStorage.setAttributeValue(storageAddress, getNum(_name), attribNumber, _val);
        emit ManufacturerAttributeSet(_name, _attributeName, _val);
    }        

    function getManufacturerOwner(bytes32 _name)
        external view 
        isARegisteredManufacturer(_name)
        returns (address) {
            return VehicleManufacturerStorage.getOwner(storageAddress, getNum(_name));
    }

    function disableManufacturer(bytes32 _name) 
        external payable
        whenNotPaused()
        onlyOwner()
        isARegisteredManufacturer(_name)
        manufacturerMustBeEnabled(_name)
         {
        VehicleManufacturerStorage.setEnabled(storageAddress, getNum(_name), false);    
        emit ManufacturerDisabled(_name);
    }

    function enableManufacturer(bytes32 _name) 
        external payable 
        whenNotPaused()
        onlyOwner()
        isARegisteredManufacturer(_name)
        manufacturerMustBeDisabled(_name)
        {     
        VehicleManufacturerStorage.setEnabled(storageAddress, getNum(_name), true);    
        emit ManufacturerEnabled(_name);
    }

    function transferManufacturerOwnership(bytes32 _name, address _newOwner, bytes32 _keyHash) 
        external payable 
        whenNotPaused()
        isARegisteredManufacturer(_name)
        onlyManufacturerOwner(_name)
        {
        uint256 number = getNum(_name);            
        address currentOwner = VehicleManufacturerStorage.getOwner(storageAddress, number);  
        VehicleManufacturerStorage.setPendingOwner(storageAddress, number, _newOwner);  
        VehicleManufacturerStorage.setTransferKey(storageAddress, number, _keyHash);  
        emit ManufacturerOwnershipTransferRequest(_name, currentOwner, _newOwner);
    }

    function acceptManufacturerOwnership(bytes32 _name, bytes32 _keyHash) 
        external payable
        whenNotPaused()
        isARegisteredManufacturer(_name)
        onlyPendingManufacturerOwner(_name)
        manufacturerTransferKeyMatches(_name, _keyHash)
         {  
        VehicleManufacturerStorage.setOwner(storageAddress, getNum(_name), msg.sender);
        emit ManufacturerOwnershipTransferAccepted(_name, msg.sender);
    } 

    function getNum(bytes32 _name) 
        private view 
        returns (uint256) {
        return VehicleManufacturerStorage.getNumber(storageAddress, _name);  
    }   
}