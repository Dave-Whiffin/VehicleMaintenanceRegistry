pragma solidity ^0.4.23;

contract EternalStorage{

    mapping(bytes32 => uint256) private UIntStorage;
    mapping(bytes32 => int) private IntStorage;
    mapping(bytes32 => string) private StringStorage;
    mapping(bytes32 => address) private AddressStorage;    
    mapping(bytes32 => bytes32) private BytesStorage;    
    mapping(bytes32 => bool) private BooleanStorage;    

    function getUint256Value(bytes32 record) public view returns (uint256){
        return UIntStorage[record];
    }

    function setUint256Value(bytes32 record, uint256 value256) public
    {
        UIntStorage[record] = value256;
    }

    function getStringValue(bytes32 record)  public view returns (string){
        return StringStorage[record];
    }

    function setStringValue(bytes32 record, string value) public
    {
        StringStorage[record] = value;
    }

    function getAddressValue(bytes32 record)  public view returns (address){
        return AddressStorage[record];
    }

    function setAddressValue(bytes32 record, address value) public
    {
        AddressStorage[record] = value;
    }

    function getBytes32Value(bytes32 record)  public view returns (bytes32){
        return BytesStorage[record];
    }

    function setBytes32Value(bytes32 record, bytes32 value) public
    {
        BytesStorage[record] = value;
    }

    function getBooleanValue(bytes32 record)  public view returns (bool){
        return BooleanStorage[record];
    }

    function setBooleanValue(bytes32 record, bool value) public
    {
        BooleanStorage[record] = value;
    }
    
    function getIntValue(bytes32 record) public view returns (int){
        return IntStorage[record];
    }

    function setIntValue(bytes32 record, int value) public
    {
        IntStorage[record] = value;
    }
}