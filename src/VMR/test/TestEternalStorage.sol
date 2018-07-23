pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EternalStorage.sol";

contract EmptyContract { 
}

contract TestEternalStorage {

    function testBindAndUnbindToContract() public {
        EternalStorage eternalStorage = new EternalStorage();
        EmptyContract emptyContract = new EmptyContract();
        Assert.equal(eternalStorage.getContractAddress(), address(0x0), "The un-initialised contract address should be 0");
        eternalStorage.bindToContract(address(emptyContract));

        Assert.equal(eternalStorage.getContractAddress(), address(emptyContract), 
            "The contract address should equal the empty contract address.");
        Assert.isTrue(eternalStorage.getStorageInitialised(),  
            "Storage should be initialised after binding to a contract.");   

        eternalStorage.unBindFromContract();
        Assert.equal(address(0x0), eternalStorage.getContractAddress(),  
            "The contract address should be 0 after unbinding.");            
        Assert.isFalse(eternalStorage.getStorageInitialised(),  
            "Storage should not be initialised after unbinding from a contract.");                        
    }  

    function testGetAndSetUint256() public {
        EternalStorage eternalStorage = new EternalStorage();
        bytes32 key = keccak256("my.int");
        Assert.equal(eternalStorage.getUint256Value(key), 0, "The un-initialised value should be 0");
        eternalStorage.setUint256Value(key, 15);
        Assert.equal(eternalStorage.getUint256Value(key), 15, "It should store the value 15.");
    }  

    function testGetAndSetBoolean() public {
        EternalStorage eternalStorage = new EternalStorage();
        bytes32 key = keccak256("my.bool");
        Assert.equal(eternalStorage.getBooleanValue(key), false, "The un-initialised value should be false");
        eternalStorage.setBooleanValue(key, true);
        Assert.equal(eternalStorage.getBooleanValue(key), true, "It should store the value true.");
    }    

    function testGetAndSetString() public {
        EternalStorage eternalStorage = new EternalStorage();
        bytes32 key = keccak256("my.string");
        Assert.equal(eternalStorage.getStringValue(key), "", "The un-initialised value should be empty");
        eternalStorage.setStringValue(key, "test");
        Assert.equal(eternalStorage.getStringValue(key), "test", "It should store the value 'test'.");
    }  

    function testGetAndSetAddress() public {
        EternalStorage eternalStorage = new EternalStorage();
        bytes32 key = keccak256("my.address");
        Assert.equal(eternalStorage.getAddressValue(key), address(0x0), "The un-initialised value should be 0");
        eternalStorage.setAddressValue(key, address(eternalStorage));
        Assert.equal(eternalStorage.getAddressValue(key), address(eternalStorage), 
            "It should store the address of the eternalStorage contract.");
    }   

    function testGetAndSetBytes32() public {
        EternalStorage eternalStorage = new EternalStorage();
        bytes32 key = keccak256("my.address");
        bytes32 val = keccak256("my.value");
        bytes32 emptyVal;
        Assert.equal(eternalStorage.getBytes32Value(key), emptyVal, "The un-initialised value should be the same as an empty bytes32 object");
        eternalStorage.setBytes32Value(key, val);
        Assert.equal(eternalStorage.getBytes32Value(key), val, "It should store the value passed in the set function.");
    }
}
