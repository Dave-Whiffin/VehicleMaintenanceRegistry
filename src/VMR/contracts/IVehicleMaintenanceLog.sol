pragma solidity ^0.4.23;

import "./IVehicleRegistry.sol";
import "../node_modules/openzeppelin-solidity/contracts/AddressUtils.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/TokenDestructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

interface IVehicleMaintenanceLog {
    function registerGarage(address _garage) external payable;
    function unRegisterGarage(address _garage) external payable;

    function logWork(bytes32 _workId, string _title, string _description) external payable;
    function addDoc(bytes32 _workId, bytes32 _ipfsAddressForDoc) external payable;

    function verifyWork(bytes32 _workId) external payable;

    function getLogCount() external view returns (uint256);

    function getWorkId(uint256 _logNumber) external view returns (bytes32);

    function getLogTitle(bytes32 _workdId) external view returns (string);
    function getLogDescription(bytes32 _workdId) external view returns (string);
    function getLogDocCount(bytes32 _workId) external view returns (uint256);
    function getLogDoc(bytes32 _workId, uint256 number) external view returns (bytes32);
}

contract VehicleMaintenanceLog is IVehicleMaintenanceLog, TokenDestructible, Claimable, Pausable {

    using AddressUtils for address;

    bytes32 public vin;
    address private storageAddress;
    address private vehicleRegistryAddress;
    mapping(address => bool) private registeredGarages;

    constructor(address _storageAddress, address _vehicleRegistryAddress, bytes32 _VIN) public {
        require(_vehicleRegistryAddress.isContract(), "The vehicle registry address must be a contract address");
        storageAddress = _storageAddress;
        vehicleRegistryAddress = _vehicleRegistryAddress;
        vin = _VIN;
    }

    modifier isVehicleOwner() {
        require(
            IVehicleRegistry(vehicleRegistryAddress).getVehicleOwner(vin) == msg.sender, 
            "You must be the vehicle owner to perform this function");
        _;
    }

    modifier isRegisteredGarage(address _garage) {
        require(registeredGarages[_garage], "The caller must be a registered garage to invoke this function");
        _;
    }

    function registerGarage(address _garage) 
        external payable
        isVehicleOwner()        
         {
        registeredGarages[_garage] = true;
    }

    function unRegisterGarage(address _garage) 
        external payable
        isVehicleOwner()        
         {
        registeredGarages[_garage] = false;
    }    
   
    function logWork(bytes32 _workId, string _title, string _description) isRegisteredGarage(msg.sender) external payable {
        //save work
    }

    function addDoc(bytes32 _workId, bytes32 _ipfsAddressForDoc) external payable {

    }

    function verifyWork(bytes32 _workId) isVehicleOwner() external payable {

    }
}