pragma solidity ^0.4.23;

import "./ByteUtilsLib.sol";
import "./Registry.sol";
import "./IRegistryLookup.sol";
import "../node_modules/openzeppelin-solidity/contracts/AddressUtils.sol";
import "./RegistryStorageLib.sol";

contract VehicleRegistry is Registry {

    using ByteUtilsLib for bytes32;
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
            IRegistryLookup(manufacturerRegistryStorageAddress).isMemberRegisteredAndEnabled(_manufacturerId), 
            "Manufacturer must be registered and enabled");
        _;
    }

    modifier senderIsManufacturerOwner (bytes32 _manufacturerId) {
        require(
            IRegistryLookup(manufacturerRegistryStorageAddress).getMemberOwner(_manufacturerId) == msg.sender, 
            "Only the owner of the manufacturer can call this function");
        _;
    }

    modifier isContractAddress(address _address) {
        require(_address.isContract(), "Address must be a contract");
        _;
    }

//base overrides
    //override base function to disable it - must use registerVehicle
    function registerMember(bytes32) 
        public payable
        returns (uint256) {
        require(false, "This function is disabled on this contract, use registerVehicle instead");
        return 0;
    }    


//external VehicleRegistry specific
    function registerVehicle(bytes32 _memberId, bytes32 _manufacturerId) 
        public payable
        whenNotPaused()
        memberIdNotRegistered(_memberId)
        paidMemberRegistrationFee()
        registeredAndEnabledManufacturer(_manufacturerId)
        senderIsManufacturerOwner(_manufacturerId)        
        returns (uint256) {

        emit LogInfo("Begin registerVehicle");
        uint256 memberNumber = RegistryStorageLib.storeMember(storageAddress, _memberId, msg.sender);
        bytes32 attributeName = "manufacturer";
        bytes32 attributeType = "id";
        RegistryStorageLib.storeMemberAttribute(storageAddress, memberNumber, attributeName, attributeType, _manufacturerId);
        emit MemberRegistered(memberNumber, _memberId);
        emit LogInfo("End registerVehicle");
        return memberNumber;
    }    
}