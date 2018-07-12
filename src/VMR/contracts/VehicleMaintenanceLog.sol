pragma solidity ^0.4.23;

import "./IVehicleMaintenanceLog.sol";
import "./VehicleMaintenanceLogStorage.sol";
import "./IVehicleRegistry.sol";
import "../node_modules/openzeppelin-solidity/contracts/AddressUtils.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/TokenDestructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract VehicleMaintenanceLog is IVehicleMaintenanceLog, TokenDestructible, Claimable, Pausable {

    using AddressUtils for address;

    address private storageAddress;
    address private vehicleRegistryAddress;
    
    event AuthorisationAdded(address indexed maintainer);
    event AuthorisationRemoved(address indexed maintainer);
    event LogAdded(uint indexed logNumber, address indexed maintainer);
    event LogDocAdded(uint indexed logNumber, uint indexed docNumber);
    event LogVerified(uint indexed logNumber);

    constructor(address _storageAddress, address _vehicleRegistryAddress, bytes32 _VIN) public {
        require(_vehicleRegistryAddress.isContract(), "The vehicle registry address must be a contract address");
        
        storageAddress = _storageAddress;
        vehicleRegistryAddress = _vehicleRegistryAddress;

        require(
            IVehicleRegistry(vehicleRegistryAddress).isVehicleRegisteredAndEnabled(_VIN), 
            "The vehicle must be registered before a maintenance log can be created");

        require(
            IVehicleRegistry(vehicleRegistryAddress).getVehicleOwner(_VIN) == msg.sender, 
            "The vehicle owner is the only one allowed to create a maintenance log");

        VehicleMaintenanceLogStorage.setVin(storageAddress, _VIN);
    }

    function getVin() public view returns (bytes32) {
        return VehicleMaintenanceLogStorage.getVin(storageAddress);
    }

    modifier onlyVehicleOwner() {
        require(
            IVehicleRegistry(vehicleRegistryAddress).getVehicleOwner(getVin()) == msg.sender, 
            "You must be the vehicle owner to perform this function");
        _;
    }

    modifier isAuthorised(address _maintainer) {
        require(
            VehicleMaintenanceLogStorage.isAuthorised(storageAddress, _maintainer), 
            "The caller must be a registered garage to invoke this function");
        _;
    }

    modifier logExists(bytes32 _logId) {
        require(
            VehicleMaintenanceLogStorage.getLogNumber(storageAddress, _logId) > 0,
            "The log Id must exist to invoke this function");
        _;
    }

    modifier logNumberExists(uint256 _logNumber) {
        require(
            _logNumber > 0 && _logNumber <= VehicleMaintenanceLogStorage.getCount(storageAddress),
            "The log number must exist to invoke this function"
        );
        _;
    }

    modifier docNumberExists(uint256 _logNumber, uint _docNumber) {
        require(
            _docNumber > 0 && _docNumber <= VehicleMaintenanceLogStorage.getDocCount(storageAddress, _logNumber),
            "The log number must exist to invoke this function"
        );
        _;
    }    

    function addAuthorisation(address _maintainer) 
        external payable
        whenNotPaused()
        onlyVehicleOwner()        
         {
        VehicleMaintenanceLogStorage.addAuthorisation(storageAddress, _maintainer);
        emit AuthorisationAdded(_maintainer);
    }

    function removeAuthorisation(address _maintainer) 
        external payable
        whenNotPaused()
        onlyVehicleOwner()        
         {
        VehicleMaintenanceLogStorage.removeAuthorisation(storageAddress, _maintainer);
        emit AuthorisationRemoved(_maintainer);
    }    
   
    function add(bytes32 _logId, uint256 _date, string _title, string _description) 
        whenNotPaused() 
        isAuthorised(msg.sender) 
        external payable {
        uint256 logNumber = VehicleMaintenanceLogStorage.storeLog(storageAddress, msg.sender, _logId, _date, _title, _description);
        emit LogAdded(logNumber, msg.sender);
    }

    function addDoc(bytes32 _logId, string _title, bytes32 _ipfsAddressForDoc) 
        whenNotPaused() 
        isAuthorised(msg.sender)
        logExists(_logId)
        external payable {
        uint256 logNumber = VehicleMaintenanceLogStorage.getLogNumber(storageAddress, _logId);
        uint256 docNumber = VehicleMaintenanceLogStorage.storeLogDoc(storageAddress, logNumber, _title, _ipfsAddressForDoc);
        emit LogDocAdded(logNumber, docNumber);
    }

    function verify(bytes32 _logId) 
        whenNotPaused() 
        onlyVehicleOwner() 
        logExists(_logId) 
        external payable {
        uint256 logNumber = VehicleMaintenanceLogStorage.getLogNumber(storageAddress, _logId);
        VehicleMaintenanceLogStorage.setVerified(storageAddress, logNumber, true);
        emit LogVerified(logNumber);
    }

    function getLogCount() external view returns (uint256) {
        return VehicleMaintenanceLogStorage.getCount(storageAddress);
    }

    function getLogNumber(bytes32 _logId)
        logExists(_logId)
        external view 
        returns (uint256) {
        return VehicleMaintenanceLogStorage.getLogNumber(storageAddress, _logId);
    }

    function getId(uint256 _logNumber) 
        logNumberExists(_logNumber)
        external view returns (bytes32) {
        return VehicleMaintenanceLogStorage.getId(storageAddress, _logNumber);
    }

    function getMaintainer(uint256 _logNumber) 
        logNumberExists(_logNumber)
        external view returns (address) {
        return VehicleMaintenanceLogStorage.getMaintainer(storageAddress, _logNumber);
    }

    function getVerified(uint256 _logNumber) 
        logNumberExists(_logNumber)
        external view returns (bool) {
        return VehicleMaintenanceLogStorage.getVerified(storageAddress, _logNumber);
    }

    function getTitle(uint256 _logNumber) 
        logNumberExists(_logNumber)
        external view returns (string) {
        return VehicleMaintenanceLogStorage.getTitle(storageAddress, _logNumber);
    }

    function getDate(uint256 _logNumber) 
        logNumberExists(_logNumber)
        external view returns (uint256) {
        return VehicleMaintenanceLogStorage.getDate(storageAddress, _logNumber);
    }

    function getDescription(uint256 _logNumber) external view returns (string) {
        return VehicleMaintenanceLogStorage.getDescription(storageAddress, _logNumber);
    }

    function getDocCount(uint256 _logNumber) 
        logNumberExists(_logNumber)
        external view returns (uint256) {
        return VehicleMaintenanceLogStorage.getDocCount(storageAddress, _logNumber);
    }

    function getDocTitle(uint256 _logNumber, uint256 _docNumber) 
        logNumberExists(_logNumber)
        docNumberExists(_logNumber, _docNumber)
        external view returns (string) {
        return VehicleMaintenanceLogStorage.getDocTitle(storageAddress, _logNumber, _docNumber);
    }

    function getDocIpfsAddress(uint256 _logNumber, uint256 _docNumber) 
        logNumberExists(_logNumber)
        docNumberExists(_logNumber, _docNumber)
        external view returns (bytes32) {
        return VehicleMaintenanceLogStorage.getDocIpfsAddress(storageAddress, _logNumber, _docNumber);
    }

}