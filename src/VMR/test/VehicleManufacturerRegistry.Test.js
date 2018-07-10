
import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var VehicleManufacturerRegistry = artifacts.require('VehicleManufacturerRegistry');
var EternalStorage = artifacts.require('EternalStorage');

contract('VehicleManufacturerRegistry', function (accounts) {
  let registry;
  let eternalStorage;
  let eternalStorageOwner;
  let registryAddress;
  let registryOwner;

  beforeEach(async function () {
    eternalStorage = await EternalStorage.new();
    eternalStorageOwner = await eternalStorage.owner.call();
    registry = await VehicleManufacturerRegistry.new(eternalStorage.address);
    registryAddress = registry;
    registryOwner = await registry.owner.call();
    await eternalStorage.setContractAddress(registryAddress.address);
    await eternalStorage.setStorageInitialised(true);
  });

  it('should have an owner', async function () {
    let owner = await registry.owner();
    assert.isTrue(owner == eternalStorageOwner);
  });

  it('should have expected storage address', async function () {
    let storageAddress = await registry.getStorageAddress();
    assert.isTrue(storageAddress == eternalStorage.address);
  });  

  it('should report unregistered manufacturers correctly', async function () {
    let name = web3.fromAscii("Ford");
    let isEnabled = await registry.isEnabled(name);
    let isRegistered = await registry.isRegistered(name);
    assert.isFalse(isEnabled);
    assert.isFalse(isRegistered);
  }); 

  it('registerManufacturer can not be called by non owners', async function () {
    let name = web3.fromAscii("Ford");
    let nonOwner = accounts[1];
    await assertRevert(registry.registerManufacturer(name, {from: nonOwner}));
  });

  it('registerManufacturer can not be called when contract is paused', async function () {
    let name = web3.fromAscii("Ford");
    await registry.pause({from: registryOwner});
    await assertRevert(registry.registerManufacturer(name, {from: registryOwner}));
  });  

  it('registerManufacturer can not be called more than once for same manufacturer', async function () {
    let name = web3.fromAscii("Ford");
    await registry.registerManufacturer(name, {from: registryOwner})
    await assertRevert(registry.registerManufacturer(name, {from: registryOwner}));
  });    
  
  describe('when a manufacturer has been registered', function () {

    let eventWatcher;
    let name;

    beforeEach(async function () {
      name = web3.fromAscii("Ford");
      eventWatcher = registry.ManufacturerRegistered();
      await registry.registerManufacturer(name, {from: registryOwner});
    });

    it('isRegistered should be true', async function () {      
      assert.isTrue(await registry.isRegistered(name));
    });
    
    it('isEnabled should be true', async function () {      
      assert.isTrue(await registry.isEnabled(name));
    }); 

    it('getManufacturerOwner should return the current owner', async function () {      
      assert.equal(registryOwner, await registry.getManufacturerOwner(name));
    });  
        
    it('emits ManufacturerRegistered event', async function () {      
      let events = await eventWatcher.get();
      assert.equal(1, events.length);
      assert.equal(
        web3.toUtf8(events[0].args.name.valueOf()), 
        web3.toUtf8(name));
    });     

    describe('The manufacturer can be disabled', function () {
      let disabledEventWatcher;

      beforeEach(async function () {
        disabledEventWatcher = registry.ManufacturerDisabled();
        await registry.disableManufacturer(name, {registryOwner});
      });

      it('which raises the expected event', async function () {      
        let events = await disabledEventWatcher.get();
        assert.equal(1, events.length);
        assert.equal(
          web3.toUtf8(events[0].args.name.valueOf()), 
          web3.toUtf8(name));      
      });  

      it('marks manufacturer as disabled', async function () {
        assert.isFalse(await registry.isEnabled(name));
      });

      describe("and re-enabled", function () {

        let enabledEventWatcher;

        beforeEach(async function () {
          enabledEventWatcher = registry.ManufacturerEnabled();          
          await registry.enableManufacturer(name, {registryOwner});
        });

        it('marking as enabled', async function () {
          assert.isTrue(await registry.isEnabled(name));
        });    

        it('emitting expected event', async function () {
          let events = await enabledEventWatcher.get();
          assert.equal(1, events.length);
          assert.equal(
            web3.toUtf8(events[0].args.name.valueOf()), 
            web3.toUtf8(name));           
        });            
      });
    });

    describe('the owner can transfer the ownership of the manufacturer', function () {
      let transferKey;
      let newOwner;
      let initialOwner;

      beforeEach(async function () {
        transferKey = web3.sha3("transfer secret");
        newOwner = accounts[1];
        initialOwner = await registry.getManufacturerOwner(name);
        await registry.transferManufacturerOwnership(name, newOwner, transferKey, {from: initialOwner});
      });

      it('the ownership does not change until the new owner has accepted', async function () {      
        assert.equal(initialOwner, await registry.getManufacturerOwner(name));
      }); 

      it('a non pending owner can not accept ownership', async function () {      
        let rogue = accounts[2];
        await assertRevert(registry.acceptManufacturerOwnership(name, transferKey, {from: rogue}));
      });       

      it('the transfer key must match', async function () {      
        let incorrectTransferKey = web3.sha3("wrong secret");
        await assertRevert(registry.acceptManufacturerOwnership(name, incorrectTransferKey, {from: newOwner}));
      });        
      
      it('the new owner can accept the transfer', async function () {      
        await registry.acceptManufacturerOwnership(name, transferKey, {from: newOwner});
        assert.equal(newOwner, await registry.getManufacturerOwner(name));
      });       

    })


  });



});