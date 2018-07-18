pragma solidity ^0.4.23;

import "./EternalStorage.sol";

library MaintenanceLogStorageLib {

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

    struct Doc {
        uint256 docNumber;
        string title;
        bytes32 ipfsAddress;
    }

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

    function storeVerification(address _storageAccount, uint256 _logNumber, address _verifier, uint256 _verificationDate) 
        public {
        setVerified(_storageAccount, _logNumber, true);
        setVerifier(_storageAccount, _logNumber, _verifier);
        setVerificationDate(_storageAccount, _logNumber, _verificationDate);
    }

    function getMaintainerCount(address _storageAccount) public view returns (uint256) {
        return EternalStorage(_storageAccount).getUint256Value
            (keccak256(abi.encodePacked("maintainerCount")));        
    }

    function setMaintainerCount(address _storageAccount, uint256 _count) public {
        EternalStorage(_storageAccount).setUint256Value
            (keccak256(abi.encodePacked("maintainerCount")), _count);        
    }    

    function getMaintainerNumber(address _storageAccount, bytes32 _maintainerId) public view returns (uint256) {
        return EternalStorage(_storageAccount).getUint256Value
            (keccak256(abi.encodePacked("maintainerNumber", _maintainerId)));          
    }

    function setMaintainerNumber(address _storageAccount, bytes32 _maintainerId, uint256 _maintainerNumber) public {
        EternalStorage(_storageAccount).setUint256Value
            (keccak256(abi.encodePacked("maintainerNumber", _maintainerId)), _maintainerNumber);          
    }   

    function addAuthorisation(address _storageAccount, bytes32 _maintainerId) public {

        uint256 maintainerNumber = getMaintainerNumber(_storageAccount, _maintainerId);

        if(maintainerNumber == 0) {
            uint256 currentCount = getMaintainerCount(_storageAccount);
            maintainerNumber = currentCount + 1;
            setMaintainerNumber(_storageAccount, _maintainerId, maintainerNumber);
            setMaintainerCount(_storageAccount, maintainerNumber);
        }

        setAuthorisation(_storageAccount, maintainerNumber, true);
    }

    function removeAuthorisation(address _storageAccount, bytes32 _maintainerId) public {
        uint256 maintainerNumber = getMaintainerNumber(_storageAccount, _maintainerId);
        setAuthorisation(_storageAccount, maintainerNumber, false);
    }

    function setAuthorisation(address _storageAccount, uint256 _maintainerNumber, bool _authorised) public {
        EternalStorage(_storageAccount).setBooleanValue
            (keccak256(abi.encodePacked("maintainerAuthorisation", _maintainerNumber)), _authorised);
    }

    function removeAllAuthorisations(address _storageAccount) public {
        for(uint256 maintainerNumber = 1; 
            maintainerNumber < getMaintainerCount(_storageAccount) + 1; 
            maintainerNumber ++ ) {
            setAuthorisation(_storageAccount, maintainerNumber, false);
        }
    }

    function isAuthorised(address _storageAccount, bytes32 _maintainerId) public view returns (bool) {
        uint256 maintainerNumber = getMaintainerNumber(_storageAccount, _maintainerId);
        
        return EternalStorage(_storageAccount).getBooleanValue
            (keccak256(abi.encodePacked("maintainerAuthorisation", maintainerNumber)));
    }

    function storeLogDoc(address _storageAccount, uint256 _logNumber, string _title, bytes32 _ipfsAddress) 
        public returns (uint256) {
        uint256 currentLogCount = getDocCount(_storageAccount, _logNumber);
        uint256 docNumber = currentLogCount + 1;

        //store doc details
        setDocTitle(_storageAccount, _logNumber, docNumber, _title);
        setDocIpfsAddress(_storageAccount, _logNumber, docNumber, _ipfsAddress);

        setDocCount(_storageAccount, _logNumber, docNumber);

        return docNumber;
    }

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

    function getDocCount(address _storageAccount, uint256 _logNumber) 
        public view returns (uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_logNumber, "docCount")));
    }

    function setDocCount(address _storageAccount, uint256 _logNumber, uint256 _count)
        public {
        return EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_logNumber, "docCount")), _count);
    }

    function setDocTitle(address _storageAccount, uint256 _logNumber, uint256 _docNumber, string _title)
        public {
        return EternalStorage(_storageAccount).setStringValue(
            keccak256(abi.encodePacked(_logNumber, _docNumber, "title")), _title);
    }  

    function setDocIpfsAddress(address _storageAccount, uint256 _logNumber, uint256 _docNumber, bytes32 _ipfsAddress)
        public {
        return EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_logNumber, _docNumber, "ipfsAddress")), _ipfsAddress);
    }   

    function getDocTitle(address _storageAccount, uint256 _logNumber, uint256 _docNumber)
        public view
        returns (string){
        return EternalStorage(_storageAccount).getStringValue(
            keccak256(abi.encodePacked(_logNumber, _docNumber, "title")));
    }  

    function getDocIpfsAddress(address _storageAccount, uint256 _logNumber, uint256 _docNumber)
        public view
        returns (bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_logNumber, _docNumber, "ipfsAddress")));
    }           

    function getCount(address _storageAccount) public view returns (uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked("count")));
    }

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

    function getId(address _storageAccount, uint256 _logNumber) public view returns (bytes32) {
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_logNumber, "id")));
    } 

    function getLogNumber(address _storageAccount, bytes32 _id) public view returns (uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_id, "logNumber")));
    }

    //index ids to log number
    function setLogNumber(address _storageAccount, bytes32 _id, uint256 _logNumber) public {
        return EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_id, "logNumber")), _logNumber);
    }

    //index log numbers to ids
    function setId(address _storageAccount, uint256 _logNumber, bytes32 _id) public {
        return EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_logNumber, "id")), _id);
    } 

    function setCount(address _storageAccount, uint256 _count) public {
        return EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked("count")), _count);
    } 

    function setDate(address _storageAccount, uint256 _logNumber, uint256 _date) public {
        return EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_logNumber, "date")), _date);
    } 

    function setMaintainerAddress(address _storageAccount, uint256 _logNumber, address _maintainer) public {
        return EternalStorage(_storageAccount).setAddressValue(
            keccak256(abi.encodePacked(_logNumber, "maintainer")), _maintainer);
    }    

    function setMaintainerId(address _storageAccount, uint256 _logNumber, bytes32 _maintainerId) public {
        return EternalStorage(_storageAccount).setBytes32Value(
            keccak256(abi.encodePacked(_logNumber, "maintainerId")), _maintainerId);
    }         

    function setVerified(address _storageAccount, uint256 _logNumber, bool _verified) public {
        return EternalStorage(_storageAccount).setBooleanValue(
            keccak256(abi.encodePacked(_logNumber, "verified")), _verified);
    }  

    function setVerifier(address _storageAccount, uint256 _logNumber, address _verifier) public {
        return EternalStorage(_storageAccount).setAddressValue(
            keccak256(abi.encodePacked(_logNumber, "verifier")), _verifier);
    }         

    function setVerificationDate(address _storageAccount, uint256 _logNumber, uint256 _verificationDate) public {
        return EternalStorage(_storageAccount).setUint256Value(
            keccak256(abi.encodePacked(_logNumber, "verificationDate")), _verificationDate);
    }

    function setTitle(address _storageAccount, uint256 _logNumber, string _title) public {
        return EternalStorage(_storageAccount).setStringValue(
            keccak256(abi.encodePacked(_logNumber, "title")), _title);
    } 

    function setDescription(address _storageAccount, uint256 _logNumber, string _description) public {
        return EternalStorage(_storageAccount).setStringValue(
            keccak256(abi.encodePacked(_logNumber, "description")), _description);
    }  

    function getMaintainerAddress(address _storageAccount, uint256 _logNumber) public view
        returns (address){
        return EternalStorage(_storageAccount).getAddressValue(
            keccak256(abi.encodePacked(_logNumber, "maintainer")));
    } 

    function getMaintainerId(address _storageAccount, uint256 _logNumber) public view
        returns (bytes32){
        return EternalStorage(_storageAccount).getBytes32Value(
            keccak256(abi.encodePacked(_logNumber, "maintainerId")));
    }       

    function getTitle(address _storageAccount, uint256 _logNumber) 
        public view returns (string) {
        return EternalStorage(_storageAccount).getStringValue(
            keccak256(abi.encodePacked(_logNumber, "title")));
    } 

    function getDescription(address _storageAccount, uint256 _logNumber) 
        public view returns (string) {
        return EternalStorage(_storageAccount).getStringValue(
            keccak256(abi.encodePacked(_logNumber, "description")));
    }  

    function getDate(address _storageAccount, uint256 _logNumber) 
        public view returns (uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_logNumber, "date")));
    }   

    function getVerified(address _storageAccount, uint256 _logNumber) 
        public view returns (bool) {
        return EternalStorage(_storageAccount).getBooleanValue(
            keccak256(abi.encodePacked(_logNumber, "verified")));
    }         

    function getVerifier(address _storageAccount, uint256 _logNumber) 
        public view returns (address) {
        return EternalStorage(_storageAccount).getAddressValue(
            keccak256(abi.encodePacked(_logNumber, "verifier")));
    }         

    function getVerificationDate(address _storageAccount, uint256 _logNumber) 
        public view returns (uint256) {
        return EternalStorage(_storageAccount).getUint256Value(
            keccak256(abi.encodePacked(_logNumber, "verificationDate")));
    }                 
  
}