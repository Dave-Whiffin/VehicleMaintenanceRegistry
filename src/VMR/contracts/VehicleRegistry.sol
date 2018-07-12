pragma solidity ^0.4.23;

import "./Registry.sol";
import "./IVehicleRegistry.sol";
import "./IManufacturerRegistry.sol";
import "../node_modules/openzeppelin-solidity/contracts/AddressUtils.sol";

contract VehicleRegistry is Registry, IVehicleRegistry {

    using AddressUtils for address;

    address private manufacturerRegistryStorageAddress;

    constructor(address _storageAddress, address _feeLookupAddres, address _manufacturerRegistryStorageAddress) 
        Registry(_storageAddress, _feeLookupAddres)
        public {
        manufacturerRegistryStorageAddress = _manufacturerRegistryStorageAddress;
    }

//modifiers
    modifier registeredAndEnabledManufacturer (bytes32 _manufacturerId) {
        require(
            IManufacturerRegistry(manufacturerRegistryStorageAddress).isManufacturerRegisteredAndEnabled(_manufacturerId), 
            "Manufacturer must be registered and enabled");
        _;
    }

    modifier senderIsManufacturerOwner (bytes32 _manufacturerId) {
        require(
            IManufacturerRegistry(manufacturerRegistryStorageAddress).getManufacturerOwner(_manufacturerId) == msg.sender, 
            "Only the owner of the manufacturer can call this function");
        _;
    }

    modifier isContractAddress(address _address) {
        require(_address.isContract(), "Address must be a contract");
        _;
    }

//IVehicleRegistry
    function getVehicleOwner(bytes32 _vin) 
        external 
        memberIdRegistered(_vin)
        returns (address) {
        uint256 memberNumber = getMemberNumber(_vin);
        Member memory member = getMemberInternal(memberNumber);
        return member.owner;
    }

    function isVehicleRegistered(bytes32 _vin) 
        external 
        returns (bool) {
        uint256 memberNumber = getMemberNumber(_vin);
        return isMemberRegistered(memberNumber);
    }

//base overrides
    //override base function to disable it - must use registerVehicle
    function registerMember(bytes32) 
        public payable
        returns (uint256) {
        require(false, "This function is disabled on this contract");
        return 0;
    }    

//external VehicleRegistry specific
    function registerVehicle(bytes32 _vin, bytes32 _manufacturerId) 
        external payable
        whenNotPaused()
        paidMemberRegistrationFee()
        memberIdNotRegistered(_vin)
        registeredAndEnabledManufacturer(_manufacturerId)
        senderIsManufacturerOwner(_manufacturerId)
        returns (uint256) {
        uint256 memberNumber = RegistryStorageLib.storeMember(storageAddress, _vin, msg.sender);
        bytes32 attributeName = "manufacturer";
        bytes32 attributeType = "id";
        RegistryStorageLib.storeMemberAttribute(storageAddress, memberNumber, attributeName, attributeType, _manufacturerId);
        emit MemberRegistered(memberNumber, _vin);
        return memberNumber;
    }

    function setMaintenanceLogAddress(bytes32 _vin, address _address) 
    external payable 
        whenNotPaused()    
        memberIdRegistered(_vin)
        memberIdOwner(_vin)
        isContractAddress(_address)
    {
        uint256 memberNumber = RegistryStorageLib.getMemberNumber(storageAddress, _vin);
        bytes32 attributeName = "maintenanceLogAddress";
        bytes32 attributeType = "address";
        RegistryStorageLib.storeMemberAttribute(storageAddress, memberNumber, attributeName, attributeType, bytes32(_address));
    }

    function getMaintenanceLogAddress(bytes32 _vin) 
    external payable 
        whenNotPaused()    
        memberIdRegistered(_vin)
        returns (address)
    {
        uint256 memberNumber = RegistryStorageLib.getMemberNumber(storageAddress, _vin);
        bytes32 attributeName = "maintenanceLogAddress";
        uint256 attributeNumber = RegistryStorageLib.getAttributeNumber(storageAddress, memberNumber, attributeName);
        return address(RegistryStorageLib.getAttributeValue(storageAddress, memberNumber, attributeNumber));
    }    
}