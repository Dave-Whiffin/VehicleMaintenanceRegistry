pragma solidity ^0.4.23;

import "./EternalStorage.sol";

/** @title Maintenance Log Storage Library
  * @dev Controls how maintenance log contracts store data in the eternal storage contract */
library MaintenanceLogStorageLib {

    /** @dev Struct defining the values in a log entry.
      */  
    struct Log {
        uint256 logNumber;
        bytes32 id;
        bytes32 maintainerId;
        address maintainerAddress;
        uint256 date;
        string  title;
        string description;
        bool verified;
        address verifier;
        uint256 verificationDate;
    }

    /** @dev Struct defining the values in a doc for a log entry.
      */  
    struct Doc {
        uint256 docNumber;
        string title;
        string ipfsAddress;
    }

    /** Struct defining the values stored against a vehicle maintainer */
    struct Maintainer {
        uint256 maintainerNumber;
        bytes32 maintainerId;
        bool authorised;
    }

    /** @dev Adds an entry to the log and increments the log count and relates id to log number.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _maintainerId The maintainer Id logging the work.
      * @param _maintainerAddress The address of the maintainer.
      * @param _id The unique id for the log entry.
      * @param _date The date the work was done.
      * @param _title A title of the work done.
      * @param _description A description of the work done.
      * @return The log number.
      */ 
    function storeLog (
        address _storageAccount, 
        bytes32 _maintainerId,
        address _maintainerAddress,
        bytes32 _id,
        uint256 _date,
        string _title,
        string _description) 
        public 
        returns (uint256 _logNumber) {

        uint256 currentCount = getCount(_storageAccount);
        uint256 logNumber = currentCount + 1;

        setLogNumber(_storageAccount, _id, logNumber);
        setId(_storageAccount, logNumber, _id);
        setMaintainerId(_storageAccount, logNumber, _maintainerId);
        setMaintainerAddress(_storageAccount, logNumber, _maintainerAddress);
        setDate(_storageAccount, logNumber, _date);
        setTitle(_storageAccount, logNumber, _title);
        setDescription(_storageAccount, logNumber, _description);
        setVerified(_storageAccount, logNumber, false);

        setCount(_storageAccount, logNumber);

        return logNumber;
    }

    /** @dev Adds verification data to a log entry.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _verifier The address of the party verifiying the work.
      * @param _verificationDate The date the work was verified.
      */ 
    function storeVerification(address _storageAccount, uint256 _logNumber, address _verifier, uint256 _verificationDate) 
        public {
        setVerified(_storageAccount, _logNumber, true);
        setVerifier(_storageAccount, _logNumber, _verifier);
        setVerificationDate(_storageAccount, _logNumber, _verificationDate);
    }

    /** @dev A count of maintainers (authorised or not) added to the log.
      * @param _storageAccount The address of the EternalStorage contract.
      * @return the number of maintainers.
      */ 
    function getMaintainerCount(address _storageAccount) public view returns (uint256) {
        return EternalStorage(_storageAccount).getUint256Value
            (keccak256(abi.encodePacked("maintainerCount")));        
    }

    /** @dev Gets a Maintainer struct relating to the maintainer number
     * @param _storageAccount the address of the EternalStorage contract
     * @param _maintainerNumber the storage allocated maintainer number
     * @return the Maintainer struct
     */
    function getMaintainerStruct(address _storageAccount, uint256 _maintainerNumber) 
        internal view 
        returns (Maintainer memory) {
        bytes32 maintainerId = getMappedMaintainerId(_storageAccount, _maintainerNumber);

        return Maintainer({
            maintainerNumber: _maintainerNumber,
            maintainerId : maintainerId,
            authorised : isAuthorised(_storageAccount, maintainerId)
        });
    }

    /** @dev Gets a Maintainer struct relating to the maintainer number
     * @param _storageAccount the address of the EternalStorage contract
     * @param _maintainerNumber the storage allocated maintainer number
     * @return the values for a maintainer
     */
    function getMaintainerValues(address _storageAccount, uint256 _maintainerNumber) 
        public view returns (uint256 maintainerNumber, bytes32 maintainerId, bool authorised) {
        Maintainer memory m = getMaintainerStruct(_storageAccount, _maintainerNumber);
        maintainerNumber = m.maintainerNumber;
        maintainerId = m.maintainerId;
        authorised = m.authorised;
    }

    /** @dev Set the current maintainer count (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _count The count of maintainers.
      */ 
    function setMaintainerCount(address _storageAccount, uint256 _count) private {
        EternalStorage(_storageAccount).setUint256Value
            (keccak256(abi.encodePacked("maintainerCount")), _count);        
    }    

    /** @dev Get the maintainer number relating to a maintainer id.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _maintainerId The maintainer id.
      * @return the maintainer number.
      */ 
    function getMaintainerNumber(address _storageAccount, bytes32 _maintainerId) public view returns (uint256) {
        return EternalStorage(_storageAccount).getUint256Value
            (keccak256(abi.encodePacked("maintainerNumber", _maintainerId)));          
    }

    /** @dev Set the maintainer number relating to a maintainer id (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _maintainerId The maintainer id.
      * @param _maintainerNumber The maintainer number.
      */ 
    function setMaintainerNumber(address _storageAccount, bytes32 _maintainerId, uint256 _maintainerNumber) private {
        EternalStorage(_storageAccount).setUint256Value
            (keccak256(abi.encodePacked("maintainerNumber", _maintainerId)), _maintainerNumber);          
    }  

    /** @dev Sets a mapping from a maintainer number to an id
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _maintainerNumber The maintainer number.
       * @param _maintainerId The maintainer id.
      */ 
    function setMappedMaintainerId(address _storageAccount, uint256 _maintainerNumber, bytes32 _maintainerId) private {
        EternalStorage(_storageAccount).setBytes32Value
            (keccak256(abi.encodePacked("mappedMaintainerId", _maintainerNumber)), _maintainerId);          
    }  

    /** @dev Gets the maintainer id from the maintainer number mapping
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _maintainerNumber The maintainer number.
      */ 
    function getMappedMaintainerId(address _storageAccount, uint256 _maintainerNumber) public view
        returns(bytes32)
     {
        return EternalStorage(_storageAccount).getBytes32Value
            (keccak256(abi.encodePacked("mappedMaintainerId", _maintainerNumber)));          
    }           

    /** @dev Adds a maintainer to the list of authorised maintainers - or sets it if authorised if it already exists.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _maintainerId The maintainer id.
      */ 
    function addAuthorisation(address _storageAccount, bytes32 _maintainerId) public {

        uint256 maintainerNumber = getMaintainerNumber(_storageAccount, _maintainerId);

        if(maintainerNumber == 0) {
            uint256 currentCount = getMaintainerCount(_storageAccount);
            maintainerNumber = currentCount + 1;
            setMappedMaintainerId(_storageAccount, maintainerNumber, _maintainerId);
            setMaintainerNumber(_storageAccount, _maintainerId, maintainerNumber);
            setMaintainerCount(_storageAccount, maintainerNumber);
        }

        setAuthorisation(_storageAccount, maintainerNumber, true);
    }

    /** @dev Flags a maintainer as unuathorised to add logs.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _maintainerId The maintainer id.
      */ 
    function removeAuthorisation(address _storageAccount, bytes32 _maintainerId) public {
        uint256 maintainerNumber = getMaintainerNumber(_storageAccount, _maintainerId);
        setAuthorisation(_storageAccount, maintainerNumber, false);
    }

    /** @dev Sets the boolean authorised flag against a maintainer (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _maintainerNumber The maintainer number.
      * @param _authorised the authorised flag to set.
      */ 
    function setAuthorisation(address _storageAccount, uint256 _maintainerNumber, bool _authorised) private {
        EternalStorage(_storageAccount).setBooleanValue
            (keccak256(abi.encodePacked("maintainerAuthorisation", _maintainerNumber)), _authorised);
    }

    /** @dev Flags all current maintainers as unuathorised.
      * @param _storageAccount The address of the EternalStorage contract.
      */ 
    function removeAllAuthorisations(address _storageAccount) public {
        for(uint256 maintainerNumber = 1; 
            maintainerNumber < getMaintainerCount(_storageAccount) + 1; 
            maintainerNumber ++ ) {
            setAuthorisation(_storageAccount, maintainerNumber, false);
        }
    }

    /** @dev Is a maintainer authorised.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _maintainerId The maintainer id.
      * @return whether the maintainer is authorised.
      */ 
    function isAuthorised(address _storageAccount, bytes32 _maintainerId) public view returns (bool) {
        uint256 maintainerNumber = getMaintainerNumber(_storageAccount, _maintainerId);
        
        return EternalStorage(_storageAccount).getBooleanValue
            (keccak256(abi.encodePacked("maintainerAuthorisation", maintainerNumber)));
    }

    /** @dev Adds a document to a log creating a document number.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _title The document title.
      * @param _ipfsAddress The document IPFS address.
      * @return the document number.
      */ 
    function storeLogDoc(address _storageAccount, uint256 _logNumber, string _title, string _ipfsAddress) 
        public returns (uint256) {
        uint256 currentLogCount = getDocCount(_storageAccount, _logNumber);
        uint256 docNumber = currentLogCount + 1;

        //store doc details
        setDocTitle(_storageAccount, _logNumber, docNumber, _title);
        setDocIpfsAddress(_storageAccount, _logNumber, docNumber, _ipfsAddress);

        setDocCount(_storageAccount, _logNumber, docNumber);

        return docNumber;
    }

    /** @dev Gets a document stored against a log entry.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _docNumber The document number.
      * @return the Doc struct relating to the doc (docNumber, title, ipfsAddress).
      */ 
    function getDoc(address _storageAccount, uint256 _logNumber, uint256 _docNumber)
        internal view
        returns (Doc memory) {

        Doc memory doc = Doc({
            docNumber: _docNumber, 
            title: getDocTitle(_storageAccount, _logNumber, _docNumber),
            ipfsAddress: getDocIpfsAddress(_storageAccount, _logNumber, _docNumber)
        });
        return doc;

    }

    /** @dev Gets the count of documents stored against a log entry.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @return the number of documents.
      */ 
    function getDocCount(address _storageAccount, uint256 _logNumber) 
        public view returns (uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_logNumber, "docCount")));
    }

    /** @dev Sets the count of documents stored against a log entry (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _count The number of documents.
      */ 
    function setDocCount(address _storageAccount, uint256 _logNumber, uint256 _count)
        private {
        return EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_logNumber, "docCount")), _count);
    }

    /** @dev Sets the document title (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _docNumber The document number.
      * @param _title The document title.
      */ 
    function setDocTitle(address _storageAccount, uint256 _logNumber, uint256 _docNumber, string _title)
        private {
        return EternalStorage(_storageAccount).setStringValue(
            keccak256(abi.encodePacked(_logNumber, _docNumber, "title")), _title);
    }  

    /** @dev Sets the document IPFS address (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _docNumber The document number.
      * @param _ipfsAddress The document IPFS address.
      */ 
    function setDocIpfsAddress(address _storageAccount, uint256 _logNumber, uint256 _docNumber, string _ipfsAddress)
        private {
        return EternalStorage(_storageAccount).setStringValue(
            keccak256(abi.encodePacked(_logNumber, _docNumber, "ipfsAddress")), _ipfsAddress);
    }   

    /** @dev Gets the doc title.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _docNumber The document number.
      */ 
    function getDocTitle(address _storageAccount, uint256 _logNumber, uint256 _docNumber)
        public view
        returns (string){
        return EternalStorage(_storageAccount).getStringValue(
            keccak256(abi.encodePacked(_logNumber, _docNumber, "title")));
    }  

    /** @dev Gets the doc IPFS address.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _docNumber The document number.
      */ 
    function getDocIpfsAddress(address _storageAccount, uint256 _logNumber, uint256 _docNumber)
        public view
        returns (string) {
        return EternalStorage(_storageAccount).getStringValue(
            keccak256(abi.encodePacked(_logNumber, _docNumber, "ipfsAddress")));
    }           

    /** @dev Gets the count of all log entries.
      * @param _storageAccount The address of the EternalStorage contract.
      */ 
    function getCount(address _storageAccount) public view returns (uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked("count")));
    }

    /** @dev Gets a specific log entry.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @return a log (see Log struct).
      */ 
    function getLog(address _storageAccount, uint256 _logNumber)
        internal view
        returns (Log memory) {

        Log memory log = Log({
            logNumber: _logNumber,
            id: getId(_storageAccount, _logNumber),
            maintainerId: getMaintainerId(_storageAccount, _logNumber),
            maintainerAddress: getMaintainerAddress(_storageAccount, _logNumber),
            date: getDate(_storageAccount, _logNumber),
            title: getTitle(_storageAccount, _logNumber),
            description: getDescription(_storageAccount, _logNumber),
            verified: getVerified(_storageAccount, _logNumber),
            verifier: getVerifier(_storageAccount, _logNumber),
            verificationDate: getVerificationDate(_storageAccount, _logNumber)
        });

        return log;
    }    

    /** @dev Gets the unique id for a log number.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @return the id.
      */ 
    function getId(address _storageAccount, uint256 _logNumber) public view returns (bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_logNumber, "id")));
    } 

    /** @dev Gets the log number relating to a unique id.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _id The unique id for the log entry.
      * @return the log number.
      */ 
    function getLogNumber(address _storageAccount, bytes32 _id) public view returns (uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_id, "logNumber")));
    }

    /** @dev Links id to log number (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _id The unique id for the log entry.
      * @param _logNumber The log number.
      */ 
    function setLogNumber(address _storageAccount, bytes32 _id, uint256 _logNumber) private {
        return EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_id, "logNumber")), _logNumber);
    }

    /** @dev Links log number to id (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _id The unique id for the log entry.
      */ 
    function setId(address _storageAccount, uint256 _logNumber, bytes32 _id) private {
        return EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_logNumber, "id")), _id);
    } 

    /** @dev Sets total count of logs (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _count The number of log entries.
      */ 
    function setCount(address _storageAccount, uint256 _count) private {
        return EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked("count")), _count);
    } 

    /** @dev Sets the log date  (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _date The date the work was done.
      */ 
    function setDate(address _storageAccount, uint256 _logNumber, uint256 _date) private {
        return EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_logNumber, "date")), _date);
    } 

    /** @dev Sets the address of the maintainer logging the work  (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _maintainer The address of the maintainer.
      */ 
    function setMaintainerAddress(address _storageAccount, uint256 _logNumber, address _maintainer) private {
        return EternalStorage(_storageAccount).setAddressValue(
            keccak256(abi.encodePacked(_logNumber, "maintainer")), _maintainer);
    }    

    /** @dev Sets the id of the maintainer logging the work  (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _maintainerId The id of the maintainer.
      */ 
    function setMaintainerId(address _storageAccount, uint256 _logNumber, bytes32 _maintainerId) private {
        return EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_logNumber, "maintainerId")), _maintainerId);
    }         

    /** @dev Sets the verified flag on a log entry  (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _verified verified.
      */ 
    function setVerified(address _storageAccount, uint256 _logNumber, bool _verified) private {
        return EternalStorage(_storageAccount).setBooleanValue(
            keccak256(abi.encodePacked(_logNumber, "verified")), _verified);
    }  

    /** @dev Sets the account of the verifier on a log entry  (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _verifier The address of the verifier.
      */
    function setVerifier(address _storageAccount, uint256 _logNumber, address _verifier) private {
        return EternalStorage(_storageAccount).setAddressValue(
            keccak256(abi.encodePacked(_logNumber, "verifier")), _verifier);
    }         

    /** @dev Sets the date of the verification on a log entry  (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _verificationDate The verification date.
      */
    function setVerificationDate(address _storageAccount, uint256 _logNumber, uint256 _verificationDate) private {
        return EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_logNumber, "verificationDate")), _verificationDate);
    }

    /** @dev Sets the title of the log entry  (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _title The title.
      */
    function setTitle(address _storageAccount, uint256 _logNumber, string _title) private {
        return EternalStorage(_storageAccount).setStringValue(
            keccak256(abi.encodePacked(_logNumber, "title")), _title);
    } 

    /** @dev Sets the description of the log entry (private).
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @param _description The description.
      */
    function setDescription(address _storageAccount, uint256 _logNumber, string _description) private {
        return EternalStorage(_storageAccount).setStringValue(
            keccak256(abi.encodePacked(_logNumber, "description")), _description);
    }  

    /** @dev Gets the maintainer address for a log entry.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @return The address of the maintainer.
      */
    function getMaintainerAddress(address _storageAccount, uint256 _logNumber) public view
        returns (address){
        return EternalStorage(_storageAccount).getAddressValue(
            keccak256(abi.encodePacked(_logNumber, "maintainer")));
    } 

    /** @dev Gets the maintainer address for a log entry.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @return The address of the maintainer.
      */
    function getMaintainerId(address _storageAccount, uint256 _logNumber) public view
        returns (bytes32){
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_logNumber, "maintainerId")));
    }       

    /** @dev Gets the title for a log entry.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @return The title.
      */
    function getTitle(address _storageAccount, uint256 _logNumber) 
        public view returns (string) {
        return EternalStorage(_storageAccount).getStringValue(
            keccak256(abi.encodePacked(_logNumber, "title")));
    } 

    /** @dev Gets the description for a log entry.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @return The description.
      */
    function getDescription(address _storageAccount, uint256 _logNumber) 
        public view returns (string) {
        return EternalStorage(_storageAccount).getStringValue(
            keccak256(abi.encodePacked(_logNumber, "description")));
    }  

    /** @dev Gets the date for a log entry.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @return The date.
      */
    function getDate(address _storageAccount, uint256 _logNumber) 
        public view returns (uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_logNumber, "date")));
    }   

    /** @dev Gets the verified flag for a log entry.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @return A boolean indicated whether the log is verified.
      */
    function getVerified(address _storageAccount, uint256 _logNumber) 
        public view returns (bool) {
        return EternalStorage(_storageAccount).getBooleanValue(
            keccak256(abi.encodePacked(_logNumber, "verified")));
    }         

    /** @dev Gets the verifier account for a log entry.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @return The address of the verifier.
      */
    function getVerifier(address _storageAccount, uint256 _logNumber) 
        public view returns (address) {
        return EternalStorage(_storageAccount).getAddressValue(
            keccak256(abi.encodePacked(_logNumber, "verifier")));
    }         

    /** @dev Gets the verification date for a log entry.
      * @param _storageAccount The address of the EternalStorage contract.
      * @param _logNumber The log number.
      * @return The verification date.
      */
    function getVerificationDate(address _storageAccount, uint256 _logNumber) 
        public view returns (uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_logNumber, "verificationDate")));
    }                 
  
}