pragma solidity ^0.4.23;

import "./MaintenanceLogStorageLib.sol";
import "./IRegistryLookup.sol";
import "../node_modules/openzeppelin-solidity/contracts/AddressUtils.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/TokenDestructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

/** @title Maintenance Log
  * @dev A digital equivalent of a vehicle log book (to hold service history etc) 
*/
contract MaintenanceLog is TokenDestructible, Claimable, Pausable {

    using AddressUtils for address;
    using MaintenanceLogStorageLib for address;

    bytes32 public vin;
    address public storageAddress;
    address public vehicleRegistryAddress;
    address public maintainerRegistryAddress;

    IRegistryLookup private vehicleRegistry;
    IRegistryLookup private maintainerRegistry;
    
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

        vehicleRegistryAddress = _vehicleRegistryAddress;            
        vehicleRegistry = IRegistryLookup(vehicleRegistryAddress);        
        maintainerRegistryAddress = _maintainerRegistryAddress;
        maintainerRegistry = IRegistryLookup(maintainerRegistryAddress);

        require(
            vehicleRegistry.isMemberRegisteredAndEnabled(_VIN));
        require(
            vehicleRegistry.getMemberOwner(_VIN) == msg.sender);


        storageAddress = _storageAddress;
        vin = _VIN;
    }

  /**
   * @dev Modifier throws if sender is not the vehicle owner
   */
    modifier onlyVehicleOwner() {
        require(
            vehicleRegistry.getMemberOwner(vin) == msg.sender);
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
        MaintenanceLogStorageLib.Log memory log = storageAddress.getLog(_logNumber);
        require(isAuthorisedAndSenderAllowed(log.maintainerId, msg.sender));
        _;
    }    

  /**
   * @dev Modifier throws if the logId does not exist
   */
    modifier logExists(bytes32 _logId) {
        require(
            storageAddress.getLogNumber(_logId) > 0);
        _;
    }

  /**
   * @dev Modifier throws if the logNumber does not exist
   */
    modifier logNumberExists(uint256 _logNumber) {
        require(
            _logNumber > 0 && _logNumber <= storageAddress.getCount()
        );
        _;
    }

  /**
   * @dev Modifier throws if the doc number does not exist against the specified log number
   */
    modifier docNumberExists(uint256 _logNumber, uint _docNumber) {
        require(
            _docNumber > 0 && _docNumber <= storageAddress.getDocCount(_logNumber)
        );
        _;
    }    

  /**
   * @dev Modifier throws if the log is verified
   */
    modifier logIsNotVerified(uint256 _logNumber) {
        require(storageAddress.getVerified(_logNumber) == false);
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
      * @return Whether or not the maintainer is authorised to log entries
      */  
    function isAuthorised(bytes32 _maintainerId) 
        public view 
        returns (bool) {
        return storageAddress.isAuthorised(_maintainerId);
    }

    /** @dev Authorise a maintainer to add logs.
      * @param _maintainerId The maintainerId.
      */  
    function addWorkAuthorisation(bytes32 _maintainerId) 
        whenNotPaused()
        onlyVehicleOwner()        
        external payable
         {
        storageAddress.addAuthorisation(_maintainerId);
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
        storageAddress.removeAuthorisation(_maintainerId);
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
        uint256 logNumber = storageAddress.storeLog(_maintainerId, msg.sender, _logId, _date, _title, _description);
        emit LogAdded(logNumber, _maintainerId);
    }

    /** @dev Add a doc to a log entry.
      * @param _logNumber The log number to add the doc to.
      * @param _title The title for the doc.
      * @param _ipfsAddressForDoc The ipfs address for the doc.
      */    
    function addDoc(uint256 _logNumber, string _title, string _ipfsAddressForDoc) 
        whenNotPaused() 
        isNotEmpty(_title)
        logNumberExists(_logNumber)
        logIsNotVerified(_logNumber)
        isMaintainerAuthorisedForLogNumber(_logNumber)        
        external payable {
        uint256 docNumber = storageAddress.storeLogDoc(_logNumber, _title, _ipfsAddressForDoc);
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
        storageAddress.storeVerification(_logNumber, msg.sender, now);
        emit LogVerified(_logNumber);
    }

    /** @dev Returns the count of log entries
      */ 
    function getLogCount() external view returns (uint256) {
        return storageAddress.getCount();
    }

    /** @dev Returns the log number for the a given logId
      * @param _logId The maintainer specified unique reference to the log entry.
      * @return The count of log entries
      */ 
    function getLogNumber(bytes32 _logId)
        logExists(_logId)
        external view 
        returns (uint256) {
        return storageAddress.getLogNumber(_logId);
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

        MaintenanceLogStorageLib.Log memory log = storageAddress.getLog(_logNumber);

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
      * @return The doc count
      */ 
    function getDocCount(uint256 _logNumber) 
        logNumberExists(_logNumber)
        external view returns (uint256) {
        return storageAddress.getDocCount(_logNumber);
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
        external view returns (uint256 docNumber, string title, string ipfsAddress) {
        MaintenanceLogStorageLib.Doc memory doc = storageAddress.getDoc(_logNumber, _docNumber);
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
        whenNotPaused() 
        public {
        Claimable.claimOwnership();
        storageAddress.removeAllAuthorisations();
    }    

  /**
   * @dev Private function that returns if a maintainer is authorised, enabled and the maintainer address equals the maintainer owner
   * @param _maintainerId The id of the maintainer
   * @param _maintainerAddress The address of the caller expected to be the maintainer owner
   * @return if the maintainer and maintainer address are authorised
   */   
    function isAuthorisedAndSenderAllowed(bytes32 _maintainerId, address _maintainerAddress) 
        private view
        returns (bool) {

        return
            storageAddress.isAuthorised(_maintainerId) &&
            maintainerRegistry.isMemberRegisteredAndEnabled(_maintainerId) &&
            _maintainerAddress == maintainerRegistry.getMemberOwner(_maintainerId);
    }    

    /**
     * @dev Sets the address of the eternal storage contract
     * Only to be called by owner and when paused
     */
    function setStorageAddress(address _storageAddress) 
        onlyOwner()
        whenPaused()
        public {
        require(_storageAddress.isContract());
        storageAddress = _storageAddress;
    }

    /**
     * @dev Sets the address of the vehicle registry address
     * Only to be called by owner and when paused
     */
    function setVehicleRegistryAddress(address _vehicleRegistryAddress) 
        onlyOwner()
        whenPaused()
        public {
        require(_vehicleRegistryAddress.isContract());
        vehicleRegistryAddress = _vehicleRegistryAddress;
    }

    /**
     * @dev Sets the address of the maintainer registry address
     * Only to be called by owner and when paused
     */
    function setMaintainerRegistryAddress(address _maintainerRegistryAddress) 
        onlyOwner()
        whenPaused()
        public {
        require(_maintainerRegistryAddress.isContract());
        maintainerRegistryAddress = _maintainerRegistryAddress;
    }        

    /**
      * @dev Returns the number of maintainer who have ever been linked to this log  
    */
    function getMaintainerCount() public view returns(uint256) {
        return storageAddress.getMaintainerCount();
    }

    /**
    * @dev Returns the values stored against a maintainer who is or has been linked to this log
    * @param _maintainerNumber the log allocated maintainer number
     */
    function getMaintainer(uint256 _maintainerNumber) 
        public view 
        returns (uint256 maintainerNumber, bytes32 maintainerId, bool authorised) {
        return storageAddress.getMaintainerValues(_maintainerNumber);
    }
}