pragma solidity ^0.4.23;

interface IVehicleMaintenanceLog {
    function addAuthorisation(address _maintainer) external payable;
    function removeAuthorisation(address _maintainer) external payable;

    function add(bytes32 _logId, string _title, string _description, uint256 date) external payable;
    function addDoc(bytes32 _logId, string _title, bytes32 _ipfsAddressForDoc) external payable;

    function verify(bytes32 _logId) external payable;

    function getLogCount() external view returns (uint256);
    function getLogNumber(bytes32 _logId) external view returns (uint256);
    function getId(uint256 _logNumber) external view returns (bytes32);
    function getTitle(uint256 _logNumber) external view returns (string);
    function getDate(uint256 _logNumber) external view returns (uint256);
    function getDescription(uint256 _logNumber) external view returns (string);
    function getMaintainer(uint256 _logNumber) external view returns (address);
    function getVerified(uint256 _logNumber) external view returns (bool);
    function getDocCount(uint256 _logNumber) external view returns (uint256);
    function getDocTitle(uint256 _logNumber, uint256 _docNumber) external view returns (string);
    function getDocIpfsAddress(uint256 _logNumber, uint256 _docNumber) external view returns (bytes32);

    event AuthorisationAdded(address indexed maintainer);
    event AuthorisationRemoved(address indexed maintainer);
    event LogAdded(uint indexed logNumber, address indexed maintainer);
    event LogDocAdded(uint indexed logNumber, uint indexed docNumber);
    event LogVerified(uint indexed logNumber);
}