pragma solidity ^0.4.23;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";

contract EternalStorage is Claimable {

    mapping(bytes32 => uint256) private UIntStorage;
    mapping(bytes32 => int) private IntStorage;
    mapping(bytes32 => string) private StringStorage;
    mapping(bytes32 => address) private AddressStorage;    
    mapping(bytes32 => bytes32) private BytesStorage;    
    mapping(bytes32 => bool) private BooleanStorage;    

    modifier onlyRegisteredCaller() {
        if(getStorageInitialised()) {
            require(getContractAddress() == msg.sender, "Once storage is initialised - only the contract address can invoke this function");
        }
        else{
            require(msg.sender == owner, "Until the storage is initialised - only the owner can invoke this function");
        }
        _;
    }    

    function setContractAddress(address _address) onlyOwner() public {
        AddressStorage[keccak256("contract.address")] = _address;
    }

    function getContractAddress() public view returns (address) {
        return AddressStorage[keccak256("contract.address")];
    }    

    function setStorageInitialised(bool _initialised) onlyOwner() public {
        BooleanStorage[keccak256("contract.storage.initialised")] = _initialised;
    }

    function getStorageInitialised() public view returns (bool) {
        return BooleanStorage[keccak256("contract.storage.initialised")];
    }

    function getUint256Value(bytes32 record) public view returns (uint256){
        return UIntStorage[record];
    }

    function setUint256Value(bytes32 record, uint256 value256) onlyRegisteredCaller() public
    {
        UIntStorage[record] = value256;
    }

    function getStringValue(bytes32 record)  public view returns (string){
        return StringStorage[record];
    }

    function setStringValue(bytes32 record, string value) onlyRegisteredCaller() public
    {
        StringStorage[record] = value;
    }

    function getAddressValue(bytes32 record)  public view returns (address){
        return AddressStorage[record];
    }

    function setAddressValue(bytes32 record, address value) onlyRegisteredCaller() public
    {
        AddressStorage[record] = value;
    }

    function getBytes32Value(bytes32 record)  public view returns (bytes32){
        return BytesStorage[record];
    }

    function setBytes32Value(bytes32 record, bytes32 value)  onlyRegisteredCaller() public
    {
        BytesStorage[record] = value;
    }

    function getBooleanValue(bytes32 record)  public view returns (bool){
        return BooleanStorage[record];
    }

    function setBooleanValue(bytes32 record, bool value) onlyRegisteredCaller() public
    {
        BooleanStorage[record] = value;
    }
}