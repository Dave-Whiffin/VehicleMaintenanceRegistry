pragma solidity ^0.4.23;

import "./ByteUtilsLib.sol";
import "./Registry.sol";
import "./IRegistryLookup.sol";
import "../node_modules/openzeppelin-solidity/contracts/AddressUtils.sol";
import "./RegistryStorageLib.sol";

/** @title Vehicle Registry
  * @dev A registry of vehicles inheriting from Registry.
  * With some vehicle specific functions and overrides of base Registry functions.
 */
contract VehicleRegistry is Registry {

    using ByteUtilsLib for bytes32;
    using AddressUtils for address;
    using RegistryStorageLib for address;


    /** @dev the attribute name used for the maintenance log. */
    bytes32 public maintenanceLogAttributeName;
    /** @dev the attribute type assigned to the maintenance log. */
    bytes32 public maintenanceLogAttributeType;
    /** @dev the attribute name for manufacturer name. */
    bytes32 public manufacturerAttributeName;
    /** @dev the attribute type for the manufacturer. */
    bytes32 public manufacturerAttributeType;
    /** @dev the address of the manufacturer registry contract (IRegistryLookup). */
    address public manufacturerRegistryAddress;

    IRegistryLookup private manufacturerRegistry;

    /** @dev The Constructor
      * @param _storageAddress the address of the eternal storage contract where the registry data will be stored.
      * @param _feeLookupAddress the address of the contract implementing IFeeLookup for returning registration transfer fees.
      * @param _manufacturerRegistryAddress the address of the manufacturer registry contract implementing IRegistryLookup.
     */
    constructor(address _storageAddress, address _feeLookupAddress, address _manufacturerRegistryAddress) 
        Registry(_storageAddress, _feeLookupAddress)
        public {
        require(_manufacturerRegistryAddress.isContract());
        manufacturerRegistryAddress = _manufacturerRegistryAddress;
        manufacturerAttributeName = "manufacturer";
        manufacturerAttributeType = "id";
        maintenanceLogAttributeName = "maintenanceLog";
        maintenanceLogAttributeType = "address";
        manufacturerRegistry = IRegistryLookup(manufacturerRegistryAddress);
    }

//modifiers
    /** @dev Modifier - throws if manufacturer is not registered or not enabled.
      * @param _manufacturerId the manufacturer id.
    */
    modifier registeredAndEnabledManufacturer (bytes32 _manufacturerId) {
        require(
            manufacturerRegistry.isMemberRegisteredAndEnabled(_manufacturerId));
        _;
    }

    /** @dev Modifier - throws if sender is not the owner of the manufacturer.
      * @param _manufacturerId the manufacturer id.
    */
    modifier senderIsManufacturerOwner (bytes32 _manufacturerId) {
        require(
            manufacturerRegistry.getMemberOwner(_manufacturerId) == msg.sender);
        _;
    }

    /** @dev Modifier - throws if the address is not a contract address.
      * @param _address the address to check
     */
    modifier isContractAddress(address _address) {
        require(_address.isContract());
        _;
    }

    /** @dev Modifier - throws if the length of the vin is not 17
      * @param _vin the vehicle identification number to check
     */
    modifier validVinLength(bytes32 _vin) {
        require(_vin.getStringLength() == 17);
        _;
    }

    /** @dev Modifier - (Override base in Registry) throws if attribute name belonging to attribute is the manafacturer attribute name.
      * @param _memberNumber the member number.
      * @param _attributeNumber the attribute number
     */
    modifier allowedToSetAttribute(uint256 _memberNumber, uint256 _attributeNumber) {
        bytes32 name = storageAddress.getAttributeName(_memberNumber, _attributeNumber);
        require(name != manufacturerAttributeName);        
        _;
    }     

    /** @dev Disabled - DOT NOT USE!! use registerVehicle instead.
      * Will throw if called.
     */
    function registerMember(bytes32) 
        public payable
        returns (uint256) {
        require(false);
        return 0;
    }    

//external VehicleRegistry specific
    /** @dev adds a vehicle to the registry and stores the manufacturer against it.
      * Throws if contract is paused
      * Throws if the vin length is invalid
      * Throws if the vin is already registered
      * Throws if the msg.value is below the registration fee
      * Throws if the manufacturer is not registered and enabled
      * Throws if the sender is not the manufacturer owner
      * @param _vin the vehicle identification number - must be unique to register
      * @param _manufacturerId the id of the manufacturer of the vehicle
      * @return the vehicle number allocated by the registry (aka the member number)
     */
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
        uint256 memberNumber = storageAddress.storeMember(_vin, msg.sender);
        storageAddress.storeMemberAttribute
            (memberNumber, manufacturerAttributeName, manufacturerAttributeType, _manufacturerId);
        emit MemberRegistered(memberNumber, _vin);
        emit LogInfo("End registerVehicle");
        return memberNumber;
    }    

    /** @dev sets the address of the maintenance log for the vehicle.  Stores as an attribute with a pre defined name.
      * Throws if the contract is paused.
      * Throws if the member number is not registered
      * Throws if the member number is not enabled.
      * Throws if the sender is not the owner of the member
      * Throws if the address is not a contract address
      * @param _memberNumber the member number
      * @param _address the address of the maintenance log contract
     */
    function setMaintenanceLogAddress(uint256 _memberNumber, address _address) 
        public payable 
        whenNotPaused()
        memberNumberRegisteredEnabledAndOwnedBySender(_memberNumber)
        isContractAddress(_address) {

        storageAddress.storeOrSetAttribute(
            _memberNumber, maintenanceLogAttributeName, maintenanceLogAttributeType, bytes32(_address));
    }

    /** @dev Returns the address of the maintenance log contract (if it is present)
      * @param _memberNumber the member number
     */
    function getMaintenanceLogAddress(uint256 _memberNumber) 
        public view 
        returns (address) {
        RegistryStorageLib.Attribute memory attribute = 
            storageAddress.getAttribute(_memberNumber, maintenanceLogAttributeName);
        return address(attribute.value);
    }

    /** @dev Sets the address of the Manufacturer Registry contract (IRegistryLookup). 
      * Must be called by owner and contract is paused.
      * Requires a different addres to the current address.  
      * @param _manufacturerRegistryAddress the address of the manufacturer registry contract.     */

    function setManufacturerRegistryAddress(address _manufacturerRegistryAddress) 
        onlyOwner()
        applyContractAddressRules(manufacturerRegistryAddress, _manufacturerRegistryAddress)
        public
         {
        manufacturerRegistryAddress = _manufacturerRegistryAddress;
    }        

    
}