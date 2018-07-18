pragma solidity ^0.4.23;

import "./MaintenanceLogStorageLib.sol";
import "./IRegistryLookup.sol";
import "../node_modules/openzeppelin-solidity/contracts/AddressUtils.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/TokenDestructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

/** @title Maintenance Log - a digital equivalent of a vehicle log book (to hold service history etc) */
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

    /** @dev The constructor
      * @param _storageAddress The address of the EternalStorage contract.
      * @param _vehicleRegistryAddress The address of the contract implementing IVehicleRegistry for vehicles.
      * @param _maintainerRegistryAddress The address of the contract implementing IRegistry for maintainers.
      * @param _VIN The vehicle identification number (must be unique and present in the VehicleRegistry).
      */   
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

  /**
   * @dev Modifier throws if sender is not the vehicle owner
   */
    modifier onlyVehicleOwner() {
        require(
            IRegistryLookup(vehicleRegistryAddress).getMemberOwner(vin) == msg.sender);
        _;
    }

  /**
   * @dev Modifier throws if sender is maintainer is not authorised or if the sender is not the maintainer owner
   */
    modifier isMaintainerAuthorised(bytes32 _maintainerId) {
        require(isAuthorisedAndSenderAllowed(_maintainerId, msg.sender));
        _;
    }

  /**
   * @dev Modifier throws if sender is not the owner relating to the maintainer on the log or the maintainer is not authorised
   */
    modifier isMaintainerAuthorisedForLogNumber(uint256 _logNumber) {
        MaintenanceLogStorageLib.Log memory log = MaintenanceLogStorageLib.getLog(storageAddress, _logNumber);
        require(isAuthorisedAndSenderAllowed(log.maintainerId, msg.sender));
        _;
    }    

  /**
   * @dev Modifier throws if the logId does not exist
   */
    modifier logExists(bytes32 _logId) {
        require(
            MaintenanceLogStorageLib.getLogNumber(storageAddress, _logId) > 0);
        _;
    }

  /**
   * @dev Modifier throws if the logNumber does not exist
   */
    modifier logNumberExists(uint256 _logNumber) {
        require(
            _logNumber > 0 && _logNumber <= MaintenanceLogStorageLib.getCount(storageAddress)
        );
        _;
    }

  /**
   * @dev Modifier throws if the doc number does not exist against the specified log number
   */
    modifier docNumberExists(uint256 _logNumber, uint _docNumber) {
        require(
            _docNumber > 0 && _docNumber <= MaintenanceLogStorageLib.getDocCount(storageAddress, _logNumber)
        );
        _;
    }    

  /**
   * @dev Modifier throws if the log is verified
   */
    modifier logIsNotVerified(uint256 _logNumber) {
        require(MaintenanceLogStorageLib.getVerified(storageAddress, _logNumber) == false);
        _;
    }

  /**
   * @dev Modifier throws if the string is empty
   */
    modifier isNotEmpty(string s) {
        require(bytes(s).length > 0);
        _;
    }

    /** @dev Indicates if a maintainer is authorised.
      * @param _maintainerId The maintainerId.
      */  
    function isAuthorised(bytes32 _maintainerId) 
        public view 
        returns (bool) {
        return MaintenanceLogStorageLib.isAuthorised(storageAddress, _maintainerId);
    }

    /** @dev Authorise a maintainer to add logs.
      * @param _maintainerId The maintainerId.
      */  
    function addWorkAuthorisation(bytes32 _maintainerId) 
        whenNotPaused()
        onlyVehicleOwner()        
        external payable
         {
        MaintenanceLogStorageLib.addAuthorisation(storageAddress, _maintainerId);
        emit WorkAuthorisationAdded(_maintainerId);
    }

    /** @dev Remove authorisation from a maintainer to add logs.
      * @param _maintainerId The maintainerId.
      */ 
    function removeWorkAuthorisation(bytes32 _maintainerId) 
        whenNotPaused()
        onlyVehicleOwner()        
        external payable
         {
        MaintenanceLogStorageLib.removeAuthorisation(storageAddress, _maintainerId);
        emit WorkAuthorisationRemoved(_maintainerId);
    }    
   
    /** @dev Add a log entry.
      * @param _logId A unique reference to the work done.
      * @param _maintainerId The maintainerId who did the work.
      * @param _date The date the work was done.
      * @param _title The title of the work.
      * @param _description The description of the work.
      */    
    function add(bytes32 _logId, bytes32 _maintainerId, uint256 _date, string _title, string _description) 
        whenNotPaused() 
        isMaintainerAuthorised(_maintainerId) 
        external payable {
        uint256 logNumber = MaintenanceLogStorageLib.storeLog(storageAddress, _maintainerId, msg.sender, _logId, _date, _title, _description);
        emit LogAdded(logNumber, _maintainerId);
    }

    /** @dev Add a doc to a log entry.
      * @param _logNumber The log number to add the doc to.
      * @param _title The title for the doc.
      * @param _ipfsAddressForDoc The ipfs address for the doc.
      */    
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

    /** @dev Marks a log entry as verified to ensure the vin owner is satisfied the work was done.
      * @param _logNumber The log number to add the doc to.
      */ 
    function verify(uint256 _logNumber) 
        whenNotPaused() 
        onlyVehicleOwner() 
        logNumberExists(_logNumber) 
        external payable {
        MaintenanceLogStorageLib.storeVerification(storageAddress, _logNumber, msg.sender, now);
        emit LogVerified(_logNumber);
    }

    /** @dev Returns the count of log entries
      */ 
    function getLogCount() external view returns (uint256) {
        return MaintenanceLogStorageLib.getCount(storageAddress);
    }

    /** @dev Returns the log number for the a given logId
      * @param _logId The maintainer specified unique reference to the log entry.
      */ 
    function getLogNumber(bytes32 _logId)
        logExists(_logId)
        external view 
        returns (uint256) {
        return MaintenanceLogStorageLib.getLogNumber(storageAddress, _logId);
    }

    /** @dev Returns a specific log entry
      * @param _logNumber The Log Number for the entry.
      * @return logNumber The Log Number for the entry.
      * @return id The maintainer specified unique id for the log entry.
      * @return maintainerId The maintainerId.
      * @return maintainerAddress The maintainer address that added the log.
      * @return date The date the work was done.
      * @return title The title for the work.
      * @return description The description of the work.
      * @return verified Indicates if the vin owner verified the work.
      * @return verifier The address of the verifier.
      * @return verificationDate The date of the verification.
      */
    function getLog(uint256 _logNumber) 
        external view 
        logNumberExists(_logNumber)
        returns 
    (uint256 logNumber, bytes32 id, bytes32 maintainerId, 
    address maintainerAddress, uint256 date, string title, string description, 
    bool verified, address verifier, uint256 verificationDate) {

        MaintenanceLogStorageLib.Log memory log = MaintenanceLogStorageLib.getLog(storageAddress, _logNumber);

        logNumber = log.logNumber;
        id = log.id;
        maintainerId = log.maintainerId;
        maintainerAddress = log.maintainerAddress;
        date = log.date;
        title = log.title;
        description = log.description;
        verified = log.verified;
        verifier = log.verifier;
        verificationDate = log.verificationDate;
    }

    /** @dev Returns the number of docs attached to a log entry
      * @param _logNumber The log number for the entry
      */ 
    function getDocCount(uint256 _logNumber) 
        logNumberExists(_logNumber)
        external view returns (uint256) {
        return MaintenanceLogStorageLib.getDocCount(storageAddress, _logNumber);
    }

    /** @dev Returns a specific doc relating to a log
      * @param _logNumber The Log Number for the entry.
      * @param _docNumber The Document Number.
      * @return docNumber The Document Number.
      * @return title The Document Title.
      * @return ipfsAddress The IPFS address for the doc.
      */
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
   * @dev Allows the pendingOwner address to finalize the transfer (only if they own the vehicle in the vehicle registry).
   */
    function claimOwnership() 
        onlyPendingOwner() 
        onlyVehicleOwner()
        public {
        Claimable.claimOwnership();
        MaintenanceLogStorageLib.removeAllAuthorisations(storageAddress);
    }    

  /**
   * @dev Private function that returns if a maintainer is authorised, enabled and the maintainer address equals the maintainer owner
   */
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