pragma solidity ^0.4.23;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";

/** @title Eternal Storage - a key value storage vault. */
contract EternalStorage is Claimable {

    mapping(bytes32 => uint256) private UIntStorage;
    mapping(bytes32 => int) private IntStorage;
    mapping(bytes32 => string) private StringStorage;
    mapping(bytes32 => address) private AddressStorage;    
    mapping(bytes32 => bytes32) private BytesStorage;    
    mapping(bytes32 => bool) private BooleanStorage;    

  /**
   * @dev Modifier throws when A: is initialised and sender isn't the bound contract address.  B: not initialised and sender is not owner.
   */
    modifier onlyRegisteredCaller() {
        if(getStorageInitialised()) {
            require(getContractAddress() == msg.sender, "Once storage is initialised - only the contract address can invoke this function");
        }
        else{
            require(msg.sender == owner, "Until the storage is initialised - only the owner can invoke this function");
        }
        _;
    }    

    /** @dev Binds the eternal storage to a specific contract.
      * @param _address the contract address to attach to
      */
    function setContractAddress(address _address) onlyOwner() public {
        AddressStorage[keccak256("contract.address")] = _address;
    }

    /** @dev Returns the contract address the eternal storage is bound to.
      */
    function getContractAddress() public view returns (address) {
        return AddressStorage[keccak256("contract.address")];
    }    

    /** @dev Setting the storage as initialized prevents anyone but the contract address calling setters.
      * @param _initialised A bool flag to indicate whether or not the storage should be initialised.
      */
    function setStorageInitialised(bool _initialised) onlyOwner() public {
        BooleanStorage[keccak256("contract.storage.initialised")] = _initialised;
    }

    /** @dev Returns the storage initialised flag
      */
    function getStorageInitialised() public view returns (bool) {
        return BooleanStorage[keccak256("contract.storage.initialised")];
    }

    /** @dev Returns a uint256 from storage
      * @param key The storage key
      */
    function getUint256Value(bytes32 key) public view returns (uint256){
        return UIntStorage[key];
    }

    /** @dev Set a uint256 in storage
      * @param key The storage key
      * @param value The value to store
      */
    function setUint256Value(bytes32 key, uint256 value) onlyRegisteredCaller() public {
        UIntStorage[key] = value;
    }

    /** @dev Returns a string from storage
      * @param key The storage key
      */
    function getStringValue(bytes32 key)  public view returns (string){
        return StringStorage[key];
    }

    /** @dev Set a bytes32 in storage
      * @param key The storage key
      * @param value The value to store
      */
    function setStringValue(bytes32 key, string value) onlyRegisteredCaller() public {
        StringStorage[key] = value;
    }

    /** @dev Returns an address from storage
      * @param key The storage key
      */
    function getAddressValue(bytes32 key)  public view returns (address){
        return AddressStorage[key];
    }

    /** @dev Set an address in storage
      * @param key The storage key
      * @param value The value to store
      */
    function setAddressValue(bytes32 key, address value) onlyRegisteredCaller() public {
        AddressStorage[key] = value;
    }

    /** @dev Returns a bytes32 from storage
      * @param key The storage key
      */
    function getBytes32Value(bytes32 key)  public view returns (bytes32){
        return BytesStorage[key];
    }

    /** @dev Set a bytes32 in storage
      * @param key The storage key
      * @param value The value to store
      */
    function setBytes32Value(bytes32 key, bytes32 value) onlyRegisteredCaller() public {
        BytesStorage[key] = value;
    }

    /** @dev Returns a bool from storage
      * @param key The storage key
      */
    function getBooleanValue(bytes32 key)  public view returns (bool){
        return BooleanStorage[key];
    }

    /** @dev Set a bool in storage
      * @param key The storage key
      * @param value The value to store
      */
    function setBooleanValue(bytes32 key, bool value) onlyRegisteredCaller() public {
        BooleanStorage[key] = value;
    }

}