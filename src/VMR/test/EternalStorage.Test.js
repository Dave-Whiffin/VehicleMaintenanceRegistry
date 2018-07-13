
import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var EternalStorage = artifacts.require('EternalStorage');

contract('EternalStorage', function (accounts) {
  let eternalStorage;

  /*
  var block = web3.eth.getBlock("latest");
  console.log("gasLimit: " + block.gasLimit); 

  var gasPrice = web3.eth.gasPrice;
  console.log("gas price: " +  gasPrice.toString(10));

  var balance = web3.eth.getBalance(accounts[0]);
  console.log("account balance: " + balance.toNumber());
  */

  beforeEach(async function () {

    eternalStorage = await EternalStorage.new();
  });

  it('should have an owner', async function () {
    let owner = await eternalStorage.owner();
    assert.isTrue(owner !== 0);
  });

  it('changes pendingOwner after transfer', async function () {
    let newOwner = accounts[1];
    await eternalStorage.transferOwnership(newOwner);
    let pendingOwner = await eternalStorage.pendingOwner();

    assert.isTrue(pendingOwner === newOwner);
  });

  it('should prevent to claimOwnership from no pendingOwner', async function () {
    await assertRevert(eternalStorage.claimOwnership({ from: accounts[2] }));
  });

  it('should prevent non-owners from transfering', async function () {
    const other = accounts[2];
    const owner = await eternalStorage.owner.call();

    assert.isTrue(owner !== other);
    await assertRevert(eternalStorage.transferOwnership(other, { from: other }));
  });

  it('only owners can set contract address', async function () {
    const other = accounts[2];
    const owner = await eternalStorage.owner.call();

    assert.isTrue(owner !== other);
    await assertRevert(eternalStorage.setContractAddress(other, { from: other }));
    await eternalStorage.setContractAddress(other, { from: owner });
  });  

  it('only owners can set storage initialised', async function () {
    const other = accounts[2];
    const owner = await eternalStorage.owner.call();

    assert.isTrue(owner !== other);
    await assertRevert(eternalStorage.setStorageInitialised(true, { from: other }));
    await eternalStorage.setStorageInitialised(true, { from: owner });
  });    

  describe('when storage is not initialised', function () {
    let owner;
    let key;
    let rogueAddress;
    let contractAddress;

    beforeEach(async function () {
      key = web3.sha3("myval");
      owner = await eternalStorage.owner.call();
      rogueAddress = accounts[2];
      contractAddress = accounts[1];
      await eternalStorage.setContractAddress(contractAddress);
      await eternalStorage.setStorageInitialised(false);
    });

    it('the owner can call setters', async function () {
      await eternalStorage.setAddressValue(key, owner, { from: owner });      
      await eternalStorage.setBytes32Value(key, web3.sha3("test"), { from: owner });
      await eternalStorage.setBooleanValue(key, true, { from: owner });
      await eternalStorage.setStringValue(key, "test", { from: owner });
      await eternalStorage.setUint256Value(key, 9, { from: owner });      
    });
  
    it('the contract address can not call setters', async function () {
      await assertRevert(eternalStorage.setAddressValue(key, owner, { from: contractAddress }));      
      await assertRevert(eternalStorage.setBytes32Value(key, web3.sha3("test"), { from: contractAddress }));
      await assertRevert(eternalStorage.setBooleanValue(key, true, { from: contractAddress }));
      await assertRevert(eternalStorage.setStringValue(key, "test", { from: contractAddress }));
      await assertRevert(eternalStorage.setUint256Value(key, 9, { from: contractAddress }));  
    }); 

    it('a rogue address can not call setters', async function () {
      await assertRevert(eternalStorage.setAddressValue(key, owner, { from: rogueAddress }));      
      await assertRevert(eternalStorage.setBytes32Value(key, web3.sha3("test"), { from: rogueAddress }));
      await assertRevert(eternalStorage.setBooleanValue(key, true, { from: rogueAddress }));
      await assertRevert(eternalStorage.setStringValue(key, "test", { from: rogueAddress }));
      await assertRevert(eternalStorage.setUint256Value(key, 9, { from: rogueAddress }));   
    });  
       
  });    

  describe('when storage is initialised', function () {
    let contractAddress;
    let owner;
    let key;
    let rogueAddress;

    beforeEach(async function () {
      key = web3.sha3("myval");
      owner = await eternalStorage.owner.call();
      contractAddress = accounts[1];
      rogueAddress = accounts[2];
      await eternalStorage.setContractAddress(contractAddress);
      await eternalStorage.setStorageInitialised(true);
    });

    it('the contract address can call setters', async function () {
      await eternalStorage.setAddressValue(key, contractAddress, { from: contractAddress });      
      await eternalStorage.setBytes32Value(key, web3.sha3("test"), { from: contractAddress });
      await eternalStorage.setBooleanValue(key, true, { from: contractAddress });
      await eternalStorage.setStringValue(key, "test", { from: contractAddress });
      await eternalStorage.setUint256Value(key, 9, { from: contractAddress });      
    });

    it('the owner can no longer call setters', async function () {
      await assertRevert(eternalStorage.setAddressValue(key, owner, { from: owner }));      
      await assertRevert(eternalStorage.setBytes32Value(key, web3.sha3("test"), { from: owner }));
      await assertRevert(eternalStorage.setBooleanValue(key, true, { from: owner }));
      await assertRevert(eternalStorage.setStringValue(key, "test", { from: owner }));
      await assertRevert(eternalStorage.setUint256Value(key, 9, { from: owner })); 
    }); 
    
    it('a rogue address can not call setters', async function () {
      await assertRevert(eternalStorage.setAddressValue(key, owner, { from: rogueAddress }));      
      await assertRevert(eternalStorage.setBytes32Value(key, web3.sha3("test"), { from: rogueAddress }));
      await assertRevert(eternalStorage.setBooleanValue(key, true, { from: rogueAddress }));
      await assertRevert(eternalStorage.setStringValue(key, "test", { from: rogueAddress }));
      await assertRevert(eternalStorage.setUint256Value(key, 9, { from: rogueAddress }));  
    });     
  });  

  describe('after initiating a transfer', function () {
    let newOwner;

    beforeEach(async function () {
      newOwner = accounts[1];
      await eternalStorage.transferOwnership(newOwner);
    });

    it('changes allow pending owner to claim ownership', async function () {
      await eternalStorage.claimOwnership({ from: newOwner });
      let owner = await eternalStorage.owner();

      assert.isTrue(owner === newOwner);
    });
  });
});