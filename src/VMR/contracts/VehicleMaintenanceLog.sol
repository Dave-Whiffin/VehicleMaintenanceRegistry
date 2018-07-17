pragma solidity ^0.4.23;

import "./VehicleMaintenanceLogStorage.sol";
import "./IRegistryLookup.sol";
import "../node_modules/openzeppelin-solidity/contracts/AddressUtils.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/TokenDestructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract VehicleMaintenanceLog is TokenDestructible, Claimable, Pausable {

    using AddressUtils for address;

    address private storageAddress;
    address private vehicleRegistryAddress;
    
    event WorkAuthorisationAdded(address indexed maintainer);
    event WorkAuthorisationRemoved(address indexed maintainer);
    event LogAdded(uint indexed logNumber, address indexed maintainer);
    event LogDocAdded(uint indexed logNumber, uint indexed docNumber);
    event LogVerified(uint indexed logNumber);

    constructor(address _storageAddress, address _vehicleRegistryAddress, bytes32 _VIN) public {
        
        require(_vehicleRegistryAddress.isContract());

        require(
            IRegistryLookup(_vehicleRegistryAddress).isMemberRegisteredAndEnabled(_VIN));

        require(
            IRegistryLookup(_vehicleRegistryAddress).getMemberOwner(_VIN) == msg.sender);

        storageAddress = _storageAddress;
        vehicleRegistryAddress = _vehicleRegistryAddress;            
        VehicleMaintenanceLogStorage.setVin(storageAddress, _VIN);
    }

    function getVin() public view returns (bytes32) {
        return VehicleMaintenanceLogStorage.getVin(storageAddress);
    }

    modifier onlyVehicleOwner() {
        require(
            IRegistryLookup(vehicleRegistryAddress).getMemberOwner(getVin()) == msg.sender);
        _;
    }

    modifier isAuthorised(address _maintainer) {
        require(
            VehicleMaintenanceLogStorage.isAuthorised(storageAddress, _maintainer));
        _;
    }

    modifier logExists(bytes32 _logId) {
        require(
            VehicleMaintenanceLogStorage.getLogNumber(storageAddress, _logId) > 0);
        _;
    }

    modifier logNumberExists(uint256 _logNumber) {
        require(
            _logNumber > 0 && _logNumber <= VehicleMaintenanceLogStorage.getCount(storageAddress)
        );
        _;
    }

    modifier docNumberExists(uint256 _logNumber, uint _docNumber) {
        require(
            _docNumber > 0 && _docNumber <= VehicleMaintenanceLogStorage.getDocCount(storageAddress, _logNumber)
        );
        _;
    }    

    modifier isNotEmpty(string s) {
        require(bytes(s).length > 0);
        _;
    }

    function addWorkAuthorisation(address _maintainer) 
        whenNotPaused()
        onlyVehicleOwner()        
        external payable
         {
        VehicleMaintenanceLogStorage.addAuthorisation(storageAddress, _maintainer);
        emit WorkAuthorisationAdded(_maintainer);
    }

    function removeWorkAuthorisation(address _maintainer) 
        whenNotPaused()
        onlyVehicleOwner()        
        external payable
         {
        VehicleMaintenanceLogStorage.removeAuthorisation(storageAddress, _maintainer);
        emit WorkAuthorisationRemoved(_maintainer);
    }    
   
    function add(bytes32 _logId, uint256 _date, string _title, string _description) 
        whenNotPaused() 
        isAuthorised(msg.sender) 
        external payable {
        uint256 logNumber = VehicleMaintenanceLogStorage.storeLog(storageAddress, msg.sender, _logId, _date, _title, _description);
        emit LogAdded(logNumber, msg.sender);
    }

    function addDoc(uint256 _logNumber, string _title, bytes32 _ipfsAddressForDoc) 
        whenNotPaused() 
        isAuthorised(msg.sender)
        isNotEmpty(_title)
        logNumberExists(_logNumber)
        external payable {
        uint256 docNumber = VehicleMaintenanceLogStorage.storeLogDoc(storageAddress, _logNumber, _title, _ipfsAddressForDoc);
        emit LogDocAdded(_logNumber, docNumber);
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

    function getLog(uint256 _logNumber) 
        external view 
        logNumberExists(_logNumber)
        returns 
    (uint256 logNumber, bytes32 id, address maintainer, uint256 date, string  title, string description, bool verified) {

        VehicleMaintenanceLogStorage.Log memory log = VehicleMaintenanceLogStorage.getLog(storageAddress, _logNumber);

        logNumber = log.logNumber;
        id = log.id;
        maintainer = log.maintainer;
        date = log.date;
        title = log.title;
        description = log.description;
        verified = log.verified;
    }

    function getDocCount(uint256 _logNumber) 
        logNumberExists(_logNumber)
        external view returns (uint256) {
        return VehicleMaintenanceLogStorage.getDocCount(storageAddress, _logNumber);
    }

    function getDoc(uint256 _logNumber, uint256 _docNumber) 
        logNumberExists(_logNumber)
        docNumberExists(_logNumber, _docNumber)
        external view returns (uint256 docNumber, string title, bytes32 ipfsAddress) {
        VehicleMaintenanceLogStorage.Doc memory doc = VehicleMaintenanceLogStorage.getDoc(storageAddress, _logNumber, _docNumber);
        docNumber = doc.docNumber;
        title = doc.title;
        ipfsAddress = doc.ipfsAddress;
    }
}