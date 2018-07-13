
import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var Registry = artifacts.require('Registry');
var EternalStorage = artifacts.require('EternalStorage');
var MockFeeChecker = artifacts.require('MockFeeChecker');

function logEthStatus(accounts) {
  var block = web3.eth.getBlock("latest");
  console.log("gasLimit: " + block.gasLimit); 

  var gasPrice = web3.eth.gasPrice;
  console.log("gas price: " +  gasPrice.toString(10));

  var balance = web3.eth.getBalance(accounts[0]);
  console.log("account balance: " + balance.toNumber());
}

contract('Registry', function (accounts) {
  let registry;
  let registryFeeChecker;
  let eternalStorage;
  let eternalStorageOwner;
  let registryAddress;
  let registryOwner;

  logEthStatus(accounts);

  beforeEach(async function () {
    registryFeeChecker = await MockFeeChecker.new(0);
    //console.log("Deploying Eternal Storage");
    eternalStorage = await EternalStorage.new();
    eternalStorageOwner = await eternalStorage.owner.call();
    //console.log('eternalstorage deployed');
    //console.log('deploying new Registry instance');
    registry = await Registry.new(eternalStorage.address, registryFeeChecker.address);
    registryAddress = registry;
    registryOwner = await registry.owner.call();
    await eternalStorage.setContractAddress(registryAddress.address);
    await eternalStorage.setStorageInitialised(true);
  });

  it('should have an owner', async function () {
    let owner = await registry.owner();
    assert.isTrue(owner == eternalStorageOwner);
  });

  it('getMemberTotalCount should return 0 initially', async function () {
    let count = await registry.getMemberTotalCount();
    assert.equal(0, count);
  }); 

  it('getStorageAddress should return expected storage address', async function () {
    let storageAddress = await registry.storageAddress.call();
    assert.isTrue(storageAddress == eternalStorage.address);
  });  

  it('isMemberRegistered should return false', async function () {
    assert.isFalse(await registry.isMemberRegistered(1));
  }); 

  it('registerMember can not be called by non owners', async function () {
    let memberId = web3.fromAscii("Ford");
    let nonOwner = accounts[1];
    await assertRevert(registry.registerMember(memberId, {from: nonOwner}));
  });

  it('registerMember fails when sender sends insufficient value', async function () {
    await registryFeeChecker.setFeeInWei(10);
    let memberId = web3.fromAscii("Ford");
    await assertRevert(registry.registerMember(memberId, {from: registryOwner}));
  });  

  describe('when contract is paused', function () {
    let memberId;
    let memberNumber;

    beforeEach(async function () {
      memberNumber = 10;
      memberId = web3.fromAscii("Ford");
      await registry.pause({from: registryOwner});
    });

    it('registerMember can not be called', async function () {
      await assertRevert(registry.registerMember(memberId, {from: registryOwner}));
    });
    
    it('disableMember can not be called', async function () {
      await assertRevert(registry.disableMember(memberNumber, {from: registryOwner}));
    });  
  
    it('enableMember can not be called', async function () {
      await assertRevert(registry.enableMember(memberNumber, {from: registryOwner}));
    });  
    
    it('transferMemberOwnership can not be called', async function () {
      await assertRevert(registry.transferMemberOwnership(memberNumber, accounts[2], web3.fromAscii('test'), {from: registryOwner}));
    });  
  
    it('acceptMemberOwnership can not be called', async function () {
      await assertRevert(registry.acceptMemberOwnership(memberNumber, web3.fromAscii('test'), {from: registryOwner}));
    });   
    
    it('addMemberAttribute can not be called', async function () {
      await assertRevert(
        registry.addMemberAttribute(
          memberNumber, 
          web3.fromAscii('test'), 
          web3.fromAscii('attrib type'), 
          web3.fromAscii('attrib val'), {from: registryOwner}));
    });       

    it('setMemberAttribute can not be called', async function () {
      await assertRevert(registry.setMemberAttribute(
        memberNumber, 0, web3.fromAscii('attrib val'), web3.fromAscii('attrib val'), {from: registryOwner}));
    });           

  });

  it('registerMember can not be called more than once for same member id', async function () {
    let memberId = web3.fromAscii("Ford");
    await registry.registerMember(memberId, {from: registryOwner})
    await assertRevert(registry.registerMember(memberId, {from: registryOwner}));
  });    
  
  describe('when a member has been registered', function () {

    let eventWatcher;
    let memberId;
    let memberNumber;

    beforeEach(async function () {
      memberId = web3.fromAscii("Ford");
      eventWatcher = registry.MemberRegistered();
      await registry.registerMember(memberId, {from: registryOwner});
      memberNumber = await registry.getMemberNumber(memberId);
    });

    it('getMemberTotalCount should be return 1', async function () {
      let count = await registry.getMemberTotalCount();
      assert.equal(count, 1);
    });

    it('getMemberNumber from name should be return 1', async function () {
      let count = await registry.getMemberNumber(memberId);
      assert.equal(count, 1);
    }); 

    it('isMemberRegistered should be true', async function () {      
      assert.isTrue(await registry.isMemberRegistered(memberNumber));
    });
            
    it('emits MemberRegistered event', async function () {      
      let events = await eventWatcher.get();
      assert.equal(1, events.length);
      assert.equal(memberNumber, events[0].args.memberNumber.valueOf()), 
      assert.equal(
        web3.toUtf8(events[0].args.memberId.valueOf()), 
        web3.toUtf8(memberId));                
    });

    it('the attribute count should be 0', async function () {
      assert.equal(0, await registry.getMemberAttributeTotalCount(memberNumber));
    });  

    it('non owner can not add attribute', async function () {
      await assertRevert(
        registry.addMemberAttribute(
          memberNumber, 
          web3.fromAscii("Attr Name"), 
          web3.fromAscii("Attr Type"), 
          web3.fromAscii("Attr Val"), 
          {from: accounts[1]}));
    });

    describe('Attributes can be added', function () {
      let attribName;
      let attribVal;
      let attribType;
      let attribWatcher;
      let attribNumber = 1;

      beforeEach(async function () {
        attribWatcher = registry.MemberAttributeChanged();
        attribName = web3.fromAscii("Country");
        attribType = web3.fromAscii('Address');
        attribVal = web3.fromAscii("USA");
        assert.equal(0, await registry.getMemberAttributeTotalCount(memberNumber));
        await registry.addMemberAttribute(memberNumber, attribName, attribType, attribVal);
        attribNumber = await registry.getMemberAttributeNumber(memberNumber, attribName);
        assert.equal(1, attribNumber);
      });

      it('the attribute count should be 1', async function () {
        assert.equal(1, await registry.getMemberAttributeTotalCount(memberNumber));
      });  

      it('can not add duplicate', async function () {
        await assertRevert(registry.addMemberAttribute(memberNumber, attribName, attribType, attribVal));
      });        

      it('the attribute name should be correct', async function () {
        var attribute = await registry.getMemberAttribute(memberNumber, attribNumber);
        assert.equal(
          web3.toUtf8(attribName), 
          web3.toUtf8(attribute[1]));
      }); 
 
      it('emits expected event', async function () {
        let events = await attribWatcher.get();
        assert.equal(1, events.length);
        assert.equal(memberNumber, events[0].args.memberNumber.valueOf());  
        assert.equal(attribNumber, events[0].args.attributeNumber.valueOf());  
        assert.equal(web3.toUtf8(attribName), web3.toUtf8(events[0].args.attributeName.valueOf()));
        assert.equal(web3.toUtf8(attribType), web3.toUtf8(events[0].args.attributeType.valueOf()));  
        assert.equal(web3.toUtf8(attribVal), web3.toUtf8(events[0].args.attributeValue.valueOf()));      
      });        
      
      it('the attribute value can be changed and emits event', async function () {
        //(uint256 indexed memberNumber, uint256 indexed _attributeNumber, bytes32 indexed _attributeName, string attributeType, string attributeValue);    
        let newVal = web3.fromAscii("UK");
        let newType = web3.fromAscii("Changed Type");
        await registry.setMemberAttribute(memberNumber, attribNumber, newType, newVal);
        
        //TODO
        //assert.equal(newVal, await registry.getMemberAttributeValue(memberId, attribNumber));        
        
        let events = await attribWatcher.get();
        assert.equal(1, events.length);
        assert.equal(memberNumber, events[0].args.memberNumber.valueOf());  
        assert.equal(attribNumber, events[0].args.attributeNumber.valueOf());  
        assert.equal(web3.toUtf8(attribName), web3.toUtf8(events[0].args.attributeName.valueOf()));
        assert.equal(web3.toUtf8(newType), web3.toUtf8(events[0].args.attributeType.valueOf()));  
        assert.equal(web3.toUtf8(newVal), web3.toUtf8(events[0].args.attributeValue.valueOf()));  
      });
            
      it('non owner can not set attribute value', async function () {
        await assertRevert(registry.setMemberAttribute(memberNumber, attribNumber, attribType, attribVal, {from: accounts[1]}));
      });      
         
    });

    describe('The member can be disabled', function () {
      let disabledEventWatcher;

      beforeEach(async function () {
        disabledEventWatcher = registry.MemberDisabled();
        await registry.disableMember(memberNumber, {registryOwner});
      });

      it('which emits the expected MemberDisabled event', async function () {      
        let events = await disabledEventWatcher.get();
        assert.equal(1, events.length);
        assert.equal(memberNumber, events[0].args.memberNumber.valueOf());  
      });  

      it('isMemberEnabled returns false', async function () {
        var member = await registry.getMember(memberNumber);
        assert.isFalse(member[3]);
      });

      describe("and re-enabled", function () {

        let enabledEventWatcher;

        beforeEach(async function () {
          enabledEventWatcher = registry.MemberEnabled();          
          await registry.enableMember(memberNumber, {registryOwner});
        });

        it('isMemberEnabled returns true', async function () {
          var member = await registry.getMember(memberNumber);
          assert.isTrue(member[3]);
        });    

        it('emitting expected event', async function () {
          let events = await enabledEventWatcher.get();
          assert.equal(1, events.length);
          assert.equal(memberNumber, events[0].args.memberNumber.valueOf());
        });            
      });
    });

    it('transferMemberOwnership fails when value is below transfer fee', async function () {
      var member = await registry.getMember(1);
      var initialOwner = member[2];      
      var transferKey = web3.sha3("transfer secret");
      let newOwner = accounts[1];

      await registryFeeChecker.setFeeInWei(10);
      await assertRevert(registry.transferMemberOwnership(memberNumber, newOwner, transferKey, {from: initialOwner}));
    });

    describe('the owner can transfer the ownership of the member', function () {
      let transferKey;
      let newOwner;
      let initialOwner;
      let transferEventWatcher;

      beforeEach(async function () {
        transferEventWatcher = registry.MemberOwnershipTransferRequest();        
        transferKey = web3.sha3("transfer secret");
        newOwner = accounts[1];
        var member = await registry.getMember(1)
        initialOwner = member[2];
        await registry.transferMemberOwnership(memberNumber, newOwner, transferKey, {from: initialOwner});
      });

      it('the ownership does not change until the new owner has accepted', async function () { 
        var member = await registry.getMember(memberNumber);     
        assert.equal(initialOwner, member[2]);
      }); 

      it('a non pending owner can not accept ownership', async function () {      
        let rogue = accounts[2];
        await assertRevert(registry.acceptMemberOwnership(memberNumber, transferKey, {from: rogue}));
      });       

      it('the transfer key must match', async function () {      
        let incorrectTransferKey = web3.sha3("wrong secret");
        await assertRevert(registry.acceptMemberOwnership(memberNumber, incorrectTransferKey, {from: newOwner}));
      });        
      
      it('emits the MemberOwnershipTransferRequest event', async function () {
        let events = await transferEventWatcher.get();
        assert.equal(1, events.length);
        assert.equal(memberNumber, events[0].args.memberNumber.valueOf());
        assert.equal(events[0].args.from.valueOf(), initialOwner);
        assert.equal(events[0].args.to.valueOf(), newOwner);
      });

      describe('when acceptMemberOwnership is called by the pending owner', function () {

        let transferAcceptedEventWatcher;

        beforeEach(async function () {
          transferAcceptedEventWatcher = registry.MemberOwnershipTransferAccepted();        
          await registry.acceptMemberOwnership(memberNumber, transferKey, {from: newOwner});
        });

        it('getMember returns the new owner', async function () {  
          var member = await registry.getMember(memberNumber);     
           assert.equal(newOwner, member[2]);
        }); 

        it('emits MemberOwnershipTransferAccepted event', async function () {
          let events = await transferAcceptedEventWatcher.get();
          assert.equal(1, events.length);
          assert.equal(memberNumber, events[0].args.memberNumber.valueOf());
          assert.equal(events[0].args.newOwner.valueOf(), newOwner);
        });        

      });
    })

  });

});