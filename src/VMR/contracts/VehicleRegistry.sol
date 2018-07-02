pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/AddressUtils.sol";

interface IVehicleRegistry {
    //VIN must be 17 digits long
    function register(bytes32 _VIN, bytes32 _licencePlate) external payable;
    function isRegistered(bytes32 _VIN) external view returns (bool);
    function getVehicle(bytes32 _VIN) 
        external view returns (bytes32 _vin, bytes32 _licencePlate, address _owner, address _maintenanceContractAddress, uint256 _registered);

    function transferVehicleOwnership(bytes32 _VIN, address _newOwner) external payable;
    function setContractMaintenanceAddress(bytes32 _VIN, address _maintenanceContractAddress) external payable;

    event Registered (bytes _VIN);
    event VehicleOwnershipTransferred(bytes _VIN, address _from, address _to);
    event VehicleMaintenanceContractChanged(bytes _VIN, address _from, address _to);
}

contract Mortal {
    //TODO:
}

contract Owned {
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner () {
        require(msg.sender == owner, "Only the owner can perform this function"); 
        _;
    }    
}

contract EmergencyStop is Owned {
    bool private enabled = true;

    modifier isEnabled() {
        require(enabled);
        _;
    }

    modifier isDisabled() {
        require(!enabled);
        _;
    }    

    function disable()
        onlyOwner()
        isEnabled()
        public payable {
        enabled = false;
    }

    function enable()
        onlyOwner()
        isDisabled()
        public payable {
        enabled = true;
    }    
}

/** @title Vehicle Registry. */
contract VehicleRegistry is IVehicleRegistry, Owned, EmergencyStop {

//todo
//emergency stop
//use deferral to allow registry to be upgraded
//use eternal storage 
//-- new storage for each vehicle
// master storage of VIN to eternal storage contracts

//charge for each registration
//charge for transferral
//use oracle for current price ??

    using AddressUtils for address;

    struct Vehicle {
        bytes32 vin;
        bytes32 licencePlate;
        address owner;
        address maintenanceContractAddress;
        uint256 registered;
    }

    mapping(bytes32 => bytes32) private licencePlateToVIN;
    mapping(bytes32 => Vehicle) private vehicles;

    //events
    event Registered(bytes32 _VIN);
    event VehicleOwnershipTransferred(bytes32 _VIN, address _from, address _to);
    event VehicleMaintenanceContractChanged(bytes32 _VIN, address _from, address _to);

    //modifiers
    modifier vehicleOwner (bytes32 _VIN) {
        require(msg.sender == vehicles[_VIN].owner, "Only the vehicle owner can perform this function"); 
        _;
    }

    modifier registered (bytes32 _VIN) {
        require(privateIsRegistered(_VIN), "The vehicle must be registered to perform this function"); 
        _;
    }

    modifier unregistered (bytes32 _VIN) {
        require(privateIsUnRegistered(_VIN), "The vehicle must be unregistered to perform this function"); 
        _;
    }    

    modifier addressIsContract(address _address) {
        require(_address.isContract(), "The address specified must be a contract address"); 
        _;
    }

//TODO - ensure it's 17 digits long
    modifier validVin(bytes32 _VIN) {
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

    function getVehicle(bytes32 _VIN) 
        external view 
        validVin(_VIN) 
        registered(_VIN)
        returns (bytes32 _vin, bytes32 _licencePlate, address _owner, address _maintenanceContractAddress, uint256 _registered) {

        Vehicle memory v = vehicles[_vin];
        return (v.vin, v.licencePlate, v.owner, v.maintenanceContractAddress, v.registered);
    }    

//state altering

    /** @dev Registers a vehicle.
      * @param _VIN the vehicle identification number.
      * @param _licencePlate the licence / number plate of the vehicle.
      */
    function register(bytes32 _VIN, bytes32 _licencePlate) 
        external payable 
        isEnabled()
        validVin(_VIN) 
        unregistered(_VIN) {
        //can't already be registered
        Vehicle memory v = Vehicle({
            vin : _VIN, licencePlate : _licencePlate, owner : msg.sender, maintenanceContractAddress: 0, registered : now});
        vehicles[_VIN] = v;

        //deploy new ContractMaintenanceAddress
        //set contract address
        //v.maintenanceContractAddress = newAddress;

        emit Registered(_VIN);
    }

    function transferVehicleOwnership(bytes32 _VIN, address _newOwner) 
        external payable 
        isEnabled()
        validVin(_VIN) 
        registered(_VIN) 
        vehicleOwner(_VIN) 
        {
        Vehicle memory v = vehicles[_VIN];
        address oldOwner = v.owner;
        v.owner = _newOwner;
        emit VehicleOwnershipTransferred(_VIN, oldOwner, v.owner);
    }

    function setContractMaintenanceAddress(bytes32 _VIN, address _maintenanceContractAddress) 
        external payable
        isEnabled()
        validVin(_VIN)
        registered(_VIN)
        vehicleOwner(_VIN)
        addressIsContract(_maintenanceContractAddress)
         {
        address oldAddress = vehicles[_VIN].maintenanceContractAddress;
        require(oldAddress != _maintenanceContractAddress, "The new address must be different to the old address");
        vehicles[_VIN].maintenanceContractAddress = _maintenanceContractAddress;
        emit VehicleMaintenanceContractChanged(_VIN, oldAddress, _maintenanceContractAddress);
    }    

//private functions

    function privateIsUnRegistered(bytes32 _VIN) private view returns(bool) {
        return !privateIsRegistered(_VIN);
    }      

    function privateIsRegistered(bytes32 _VIN) private view returns(bool)  {
        return vehicles[_VIN].owner != 0;
    }    
 
}