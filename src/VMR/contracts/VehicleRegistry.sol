pragma solidity ^0.4.23;

import "./IVehicleRegistry.sol";
import "./IVehicleManufacturerRegistry.sol";
import "./ByteUtils.sol";
import "./VehicleRegistryStorage.sol";
import "./VehicleManufacturerRegistry.sol";
import "../node_modules/openzeppelin-solidity/contracts/AddressUtils.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/TokenDestructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

/** @title Vehicle Registry. */
contract VehicleRegistry is IVehicleRegistry, TokenDestructible, Claimable, Pausable {
    
    using ByteUtils for bytes32;
    using AddressUtils for address;

    address private vehicleRegistryStorageAddress;
    address private vehicleManufacturerRegistryAddress;

    constructor(address _vehicleRegistryStorageAddress, address _vehicleManufacturerRegistryAddress) public {
        vehicleRegistryStorageAddress = _vehicleRegistryStorageAddress;
        vehicleManufacturerRegistryAddress = _vehicleManufacturerRegistryAddress;
    }

    //events
    event Registered(bytes32 _VIN);
    event VehicleOwnershipTransferRequest(bytes32 _VIN, address _from, address _to);
    event VehicleOwnershipTransferAccepted(bytes32 _VIN, address _newOwner);
    event VehicleServiceHistoryAddressChanged(bytes32 _VIN, address _from, address _to);

    //modifiers
    modifier vehicleOwner (bytes32 _VIN) {
        address owner = VehicleRegistryStorage.getOwner(vehicleRegistryStorageAddress, _VIN);
        require(msg.sender == owner, "Only the vehicle owner can perform this function"); 
        _;
    }

    modifier pendingVehicleOwner (bytes32 _VIN) {
        address owner = VehicleRegistryStorage.getPendingOwner(vehicleRegistryStorageAddress, _VIN);
        require(msg.sender == owner, "Only the pending vehicle owner can perform this function"); 
        _;
    }    

    modifier transferKeyMatches(bytes32 _VIN, bytes32 _keyHash) {
        bytes32 transferKey = VehicleRegistryStorage.getTransferKey(vehicleRegistryStorageAddress, _VIN);
        require(transferKey == _keyHash, "The key provided must match the existing transfer key");
        _;        
    }

    modifier registered(bytes32 _VIN) {
        require(privateIsRegistered(_VIN), "The vehicle must be registered to perform this function"); 
        _;
    }

    modifier unregistered(bytes32 _VIN) {
        require(privateIsUnRegistered(_VIN), "The vehicle must be unregistered to perform this function"); 
        _;
    }    

    modifier addressIsContract(address _address) {
        require(_address.isContract(), "The address specified must be a contract address"); 
        _;
    }

    modifier validVin(bytes32 _VIN) {
        require(_VIN.getStringLength() == 17);
        _;
    }

    modifier paidEnoughToRegister() {
        uint minRegistrationFee = getMinRegistrationFee();
        require(msg.value < minRegistrationFee, "Not enough Eth was sent to cover a registration");
        _;
    }

    modifier paidEnoughToTransfer() {
        uint minTransferFee = getMinTransferFee();
        require(msg.value < minTransferFee, "Not enough Eth was sent to cover a transfer");
        _;
    }    

    modifier isARegisteredManufacturer(bytes32 _name) {
        require (
            IVehicleManufacturerRegistry(vehicleManufacturerRegistryAddress).isRegistered(_name),
            "The manufacturer must be registered to invoke this function");
        _;
    }

    modifier manufacturerMustBeEnabled(bytes32 _name) {
        require (
            IVehicleManufacturerRegistry(vehicleManufacturerRegistryAddress).isEnabled(_name),
            "The manufacturer must be enabled to invoke this function");
        _;
    }    
  
    //external methods

//view
    function isRegistered(bytes32 _VIN) 
        external view 
        validVin(_VIN)
        returns(bool) {
        return privateIsRegistered(_VIN);
    }

    function getVehicleManufacturerName(bytes32 _VIN) external view validVin(_VIN) registered(_VIN) returns (bytes32 manufacturerName) {
        return VehicleRegistryStorage.getManufacturerName(vehicleRegistryStorageAddress, _VIN);
    }

    function getVehicleLicencePlate(bytes32 _VIN) external view validVin(_VIN) registered(_VIN) returns (bytes32 licencePlate) {
        return VehicleRegistryStorage.getLicencePlate(vehicleRegistryStorageAddress, _VIN);
    }

    function getVehicleOwner(bytes32 _VIN) external view validVin(_VIN) registered(_VIN) returns (address owner) {
        return VehicleRegistryStorage.getOwner(vehicleRegistryStorageAddress, _VIN);
    }

    function getVehicleServiceHistoryAddress(bytes32 _VIN) 
        external view 
        validVin(_VIN) registered(_VIN) 
        returns (address serviceHistoryAddress) {
        return VehicleRegistryStorage.getServiceHistoryAddress(vehicleRegistryStorageAddress, _VIN);
    }

    function getVehicleRegisteredDate(bytes32 _VIN) external view validVin(_VIN) registered(_VIN) returns (uint256 registeredDate) {
        return VehicleRegistryStorage.getRegistered(vehicleRegistryStorageAddress, _VIN);
    }

//state altering

    /** @dev Registers a vehicle.
      * @param _VIN the vehicle identification number.
      * @param _licencePlate the licence / number plate of the vehicle.
      * @param _manufacturerName - the unique id of the manufacturer
      */
    function register(bytes32 _VIN, bytes32 _licencePlate, bytes32 _manufacturerName) 
        external payable 
        whenNotPaused()
        validVin(_VIN) 
        unregistered(_VIN) 
        paidEnoughToRegister()
        isARegisteredManufacturer(_manufacturerName)
        manufacturerMustBeEnabled(_manufacturerName)
        {

        VehicleRegistryStorage.storeVehicle(vehicleRegistryStorageAddress, _VIN, _manufacturerName, _licencePlate, msg.sender, 0, now);
        VehicleRegistryStorage.setServiceHistoryAddress(vehicleRegistryStorageAddress, _VIN, 0);
        //deploy new serviceHistoryAddress
        //which contract - how do we know...?
        //set contract address
        //v.maintenanceContractAddress = newAddress;

        emit Registered(_VIN);
    }

    function transferVehicleOwnership(bytes32 _VIN, address _newOwner, bytes32 _keyHash) 
        external payable 
        whenNotPaused()
        validVin(_VIN) 
        registered(_VIN) 
        vehicleOwner(_VIN) 
        paidEnoughToTransfer()
        {
        address oldOwner = VehicleRegistryStorage.getOwner(vehicleRegistryStorageAddress, _VIN);
        VehicleRegistryStorage.setPendingOwner(vehicleRegistryStorageAddress, _VIN, _newOwner);
        VehicleRegistryStorage.setTransferKey(vehicleRegistryStorageAddress, _VIN, _keyHash);
        emit VehicleOwnershipTransferRequest(_VIN, oldOwner, _newOwner);
    }

    function acceptVehicleOwnership(bytes32 _VIN, bytes32 _keyHash)
        external payable
        whenNotPaused()
        validVin(_VIN)
        registered(_VIN)
        pendingVehicleOwner(_VIN)
        transferKeyMatches(_VIN, _keyHash)
        {
        VehicleRegistryStorage.setOwner(vehicleRegistryStorageAddress, _VIN, msg.sender);
        VehicleRegistryStorage.setPendingOwner(vehicleRegistryStorageAddress, _VIN, 0);
        emit VehicleOwnershipTransferAccepted(_VIN, msg.sender);         
    }

    //allow contract to be upgraded
    function setServiceHistoryAddress(bytes32 _VIN, address _serviceHistoryAddress) 
        external payable
        whenNotPaused()
        validVin(_VIN)
        registered(_VIN)
        vehicleOwner(_VIN)
        addressIsContract(_serviceHistoryAddress)
        {
        address oldAddress = VehicleRegistryStorage.getServiceHistoryAddress(vehicleRegistryStorageAddress, _VIN);
        require(oldAddress != _serviceHistoryAddress, "The new address must be different to the old address");
        VehicleRegistryStorage.setServiceHistoryAddress(vehicleRegistryStorageAddress, _VIN, _serviceHistoryAddress);
        emit VehicleServiceHistoryAddressChanged(_VIN, oldAddress, _serviceHistoryAddress);
    }    

//private functions

    function privateIsUnRegistered(bytes32 _VIN) private view returns(bool) {
        return !privateIsRegistered(_VIN);
    }      

    function privateIsRegistered(bytes32 _VIN) private view returns(bool)  {
        return VehicleRegistryStorage.exists(vehicleRegistryStorageAddress, _VIN);
    }    

    function getMinRegistrationFee() private pure returns(uint) {
        return 100;
    }

    function getMinTransferFee() private pure returns(uint) {
        return 100;
    }    
 
}