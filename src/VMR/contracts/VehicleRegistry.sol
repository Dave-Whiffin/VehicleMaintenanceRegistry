pragma solidity ^0.4.23;

import "./ByteUtilsLib.sol";
import "./Registry.sol";
import "./IRegistryLookup.sol";
import "../node_modules/openzeppelin-solidity/contracts/AddressUtils.sol";
import "./RegistryStorageLib.sol";

contract VehicleRegistry is Registry {

    using ByteUtilsLib for bytes32;
    using AddressUtils for address;


    bytes32 public maintenanceLogAttributeName;
    bytes32 public maintenanceLogAttributeType;
    bytes32 public manufacturerAttributeName;
    bytes32 public manufacturerAttributeType;
    address private manufacturerRegistryStorageAddress;

    constructor(address _storageAddress, address _feeLookupAddres, address _manufacturerRegistryStorageAddress) 
        Registry(_storageAddress, _feeLookupAddres)
        public {
        manufacturerRegistryStorageAddress = _manufacturerRegistryStorageAddress;
        manufacturerAttributeName = "manufacturer";
        manufacturerAttributeType = "id";
        maintenanceLogAttributeName = "maintenanceLog";
        maintenanceLogAttributeType = "address";
    }

//modifiers
    modifier registeredAndEnabledManufacturer (bytes32 _manufacturerId) {
        require(
            IRegistryLookup(manufacturerRegistryStorageAddress).isMemberRegisteredAndEnabled(_manufacturerId));
        _;
    }

    modifier senderIsManufacturerOwner (bytes32 _manufacturerId) {
        require(
            IRegistryLookup(manufacturerRegistryStorageAddress).getMemberOwner(_manufacturerId) == msg.sender);
        _;
    }

    modifier isContractAddress(address _address) {
        require(_address.isContract());
        _;
    }

    modifier validVinLength(bytes32 _vin) {
        require(_vin.getStringLength() == 17);
        _;
    }

//base overrides
    //override base function to disable it - must use registerVehicle
    function registerMember(bytes32) 
        public payable
        returns (uint256) {
        require(false, "Function disabled. use registerVehicle instead");
        return 0;
    }    


//external VehicleRegistry specific
    function registerVehicle(bytes32 _vin, bytes32 _manufacturerId) 
        public payable
        whenNotPaused()
        validVinLength(_vin)
        memberIdNotRegistered(_vin)
        paidMemberRegistrationFee()
        registeredAndEnabledManufacturer(_manufacturerId)
        senderIsManufacturerOwner(_manufacturerId)        
        returns (uint256) {

        emit LogInfo("Begin registerVehicle");
        uint256 memberNumber = RegistryStorageLib.storeMember(storageAddress, _vin, msg.sender);
        RegistryStorageLib.storeMemberAttribute
        (storageAddress, memberNumber, manufacturerAttributeName, manufacturerAttributeType, _manufacturerId);
        emit MemberRegistered(memberNumber, _vin);
        emit LogInfo("End registerVehicle");
        return memberNumber;
    }    

    function setMaintenanceLogAddress(uint256 _memberNumber, address _address) 
        public payable 
        whenNotPaused()
        memberNumberEnabled(_memberNumber)
        memberNumberOwner(_memberNumber)
        isContractAddress(_address) {

        RegistryStorageLib.storeOrSetAttribute(
            storageAddress, _memberNumber, maintenanceLogAttributeName, maintenanceLogAttributeType, bytes32(_address));
    }

    function getMaintenanceLogAddress(uint256 _memberNumber) public view returns (address) {
        RegistryStorageLib.Attribute memory attribute = 
            RegistryStorageLib.getAttribute(storageAddress, _memberNumber, maintenanceLogAttributeName);
        return address(attribute.value);
    }
}