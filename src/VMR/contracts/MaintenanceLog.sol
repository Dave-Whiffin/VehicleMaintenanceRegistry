pragma solidity ^0.4.23;

import "./MaintenanceLogStorageLib.sol";
import "./IRegistryLookup.sol";
import "../node_modules/openzeppelin-solidity/contracts/AddressUtils.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/TokenDestructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract MaintenanceLog is TokenDestructible, Claimable, Pausable {

    using AddressUtils for address;

    bytes32 public vin;
    address public storageAddress;
    address public vehicleRegistryAddress;
    address public maintainerRegistryAddress;
    
    event WorkAuthorisationAdded(bytes32 indexed maintainerId);
    event WorkAuthorisationRemoved(bytes32 indexed maintainerId);
    event LogAdded(uint indexed logNumber, bytes32 indexed maintainerId);
    event DocAdded(uint indexed logNumber, uint indexed docNumber);
    event LogVerified(uint indexed logNumber);

    constructor(address _storageAddress, address _vehicleRegistryAddress, address _maintainerRegistryAddress, bytes32 _VIN) public {
        
        require(_storageAddress.isContract());
        require(_vehicleRegistryAddress.isContract());
        require(_maintainerRegistryAddress.isContract());

        require(
            IRegistryLookup(_vehicleRegistryAddress).isMemberRegisteredAndEnabled(_VIN));
        require(
            IRegistryLookup(_vehicleRegistryAddress).getMemberOwner(_VIN) == msg.sender);

        storageAddress = _storageAddress;
        vehicleRegistryAddress = _vehicleRegistryAddress;            
        maintainerRegistryAddress = _maintainerRegistryAddress;
        vin = _VIN;
    }

    modifier onlyVehicleOwner() {
        require(
            IRegistryLookup(vehicleRegistryAddress).getMemberOwner(vin) == msg.sender);
        _;
    }

    modifier isMaintainerAuthorised(bytes32 _maintainerId) {
        require(isAuthorisedAndSenderAllowed(_maintainerId, msg.sender));
        _;
    }

    modifier isMaintainerAuthorisedForLogNumber(uint256 _logNumber) {
        MaintenanceLogStorageLib.Log memory log = MaintenanceLogStorageLib.getLog(storageAddress, _logNumber);
        require(isAuthorisedAndSenderAllowed(log.maintainerId, msg.sender));
        _;
    }    

    modifier logExists(bytes32 _logId) {
        require(
            MaintenanceLogStorageLib.getLogNumber(storageAddress, _logId) > 0);
        _;
    }

    modifier logNumberExists(uint256 _logNumber) {
        require(
            _logNumber > 0 && _logNumber <= MaintenanceLogStorageLib.getCount(storageAddress)
        );
        _;
    }

    modifier docNumberExists(uint256 _logNumber, uint _docNumber) {
        require(
            _docNumber > 0 && _docNumber <= MaintenanceLogStorageLib.getDocCount(storageAddress, _logNumber)
        );
        _;
    }    

    modifier logIsNotVerified(uint256 _logNumber) {
        require(MaintenanceLogStorageLib.getVerified(storageAddress, _logNumber) == false);
        _;
    }

    modifier isNotEmpty(string s) {
        require(bytes(s).length > 0);
        _;
    }

    function isAuthorised(bytes32 _maintainerId) 
        public view 
        returns (bool) {
        return MaintenanceLogStorageLib.isAuthorised(storageAddress, _maintainerId);
    }

    function addWorkAuthorisation(bytes32 _maintainerId) 
        whenNotPaused()
        onlyVehicleOwner()        
        external payable
         {
        MaintenanceLogStorageLib.addAuthorisation(storageAddress, _maintainerId);
        emit WorkAuthorisationAdded(_maintainerId);
    }

    function removeWorkAuthorisation(bytes32 _maintainerId) 
        whenNotPaused()
        onlyVehicleOwner()        
        external payable
         {
        MaintenanceLogStorageLib.removeAuthorisation(storageAddress, _maintainerId);
        emit WorkAuthorisationRemoved(_maintainerId);
    }    
   
    function add(bytes32 _logId, bytes32 _maintainerId, uint256 _date, string _title, string _description) 
        whenNotPaused() 
        isMaintainerAuthorised(_maintainerId) 
        external payable {
        uint256 logNumber = MaintenanceLogStorageLib.storeLog(storageAddress, _maintainerId, msg.sender, _logId, _date, _title, _description);
        emit LogAdded(logNumber, _maintainerId);
    }

    function addDoc(uint256 _logNumber, string _title, bytes32 _ipfsAddressForDoc) 
        whenNotPaused() 
        isNotEmpty(_title)
        logNumberExists(_logNumber)
        logIsNotVerified(_logNumber)
        isMaintainerAuthorisedForLogNumber(_logNumber)        
        external payable {
        uint256 docNumber = MaintenanceLogStorageLib.storeLogDoc(storageAddress, _logNumber, _title, _ipfsAddressForDoc);
        emit DocAdded(_logNumber, docNumber);
    }

    function verify(uint256 _logNumber) 
        whenNotPaused() 
        onlyVehicleOwner() 
        logNumberExists(_logNumber) 
        external payable {
        MaintenanceLogStorageLib.setVerified(storageAddress, _logNumber, true);
        emit LogVerified(_logNumber);
    }

    function getLogCount() external view returns (uint256) {
        return MaintenanceLogStorageLib.getCount(storageAddress);
    }

    function getLogNumber(bytes32 _logId)
        logExists(_logId)
        external view 
        returns (uint256) {
        return MaintenanceLogStorageLib.getLogNumber(storageAddress, _logId);
    }

    function getLog(uint256 _logNumber) 
        external view 
        logNumberExists(_logNumber)
        returns 
    (uint256 logNumber, bytes32 id, bytes32 maintainerId, address maintainerAddress, uint256 date, string  title, string description, bool verified) {

        MaintenanceLogStorageLib.Log memory log = MaintenanceLogStorageLib.getLog(storageAddress, _logNumber);

        logNumber = log.logNumber;
        id = log.id;
        maintainerId = log.maintainerId;
        maintainerAddress = log.maintainerAddress;
        date = log.date;
        title = log.title;
        description = log.description;
        verified = log.verified;
    }

    function getDocCount(uint256 _logNumber) 
        logNumberExists(_logNumber)
        external view returns (uint256) {
        return MaintenanceLogStorageLib.getDocCount(storageAddress, _logNumber);
    }

    function getDoc(uint256 _logNumber, uint256 _docNumber) 
        logNumberExists(_logNumber)
        docNumberExists(_logNumber, _docNumber)
        external view returns (uint256 docNumber, string title, bytes32 ipfsAddress) {
        MaintenanceLogStorageLib.Doc memory doc = MaintenanceLogStorageLib.getDoc(storageAddress, _logNumber, _docNumber);
        docNumber = doc.docNumber;
        title = doc.title;
        ipfsAddress = doc.ipfsAddress;
    }  

  /**
   * @dev Allows the pendingOwner address to finalize the transfer BUT only if they own the vehicle.
   */
    function claimOwnership() 
        onlyPendingOwner() 
        onlyVehicleOwner()
        public {
        Claimable.claimOwnership();
        MaintenanceLogStorageLib.removeAllAuthorisations(storageAddress);
    }    

    function isAuthorisedAndSenderAllowed(bytes32 _maintainerId, address _maintainerAddress) 
        private view
        returns (bool) {

        IRegistryLookup maintainerLookup = IRegistryLookup(maintainerRegistryAddress);

        return
            MaintenanceLogStorageLib.isAuthorised(storageAddress, _maintainerId) &&
            maintainerLookup.isMemberRegisteredAndEnabled(_maintainerId) &&
            _maintainerAddress == maintainerLookup.getMemberOwner(_maintainerId);
    }    
}