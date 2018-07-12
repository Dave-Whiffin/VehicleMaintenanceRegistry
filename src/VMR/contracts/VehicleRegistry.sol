pragma solidity ^0.4.23;

import "./Registry.sol";
import "./IVehicleRegistry.sol";
import "./IManufacturerRegistry.sol";

contract VehicleRegistry is Registry, IVehicleRegistry {

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
}