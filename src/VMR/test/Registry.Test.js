
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

  before(async function () {
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

  describe("when registry fee exceeds value", function() {
    before(async function(){
      await registryFeeChecker.setFeeInWei(10);
    });

    after(async function(){
      await registryFeeChecker.setFeeInWei(0);
    });

    it('registerMember fails', async function () {
      let memberId = web3.fromAscii("Ford");
      await assertRevert(registry.registerMember(memberId, {from: registryOwner}));
    });  

    it('transferMemberOwnership fails', async function () {
      var initialOwner = accounts[0];      
      let transferSecret = "TheKey";
      var transferKeyHash = web3.sha3(transferSecret);
      let newOwner = accounts[1];
      await assertRevert(registry.transferMemberOwnership(0, newOwner, transferKeyHash, {from: initialOwner}));
    });    
  });

  describe('when contract is paused', function () {
    let memberId;
    let memberNumber;

    before(async function () {
      memberNumber = 10;
      memberId = web3.fromAscii("Ford");
      await registry.pause({from: registryOwner});
    });

    after(async function () {
      await registry.unpause({from: registryOwner});
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
      let keyHash = web3.sha3(web3.toHex("test"), {encoding:"hex"});
      await assertRevert(registry.transferMemberOwnership(memberNumber, accounts[2], keyHash, {from: registryOwner}));
    });  
  
    it('acceptMemberOwnership can not be called', async function () {
      await assertRevert(registry.acceptMemberOwnership(memberNumber, 'test', {from: registryOwner}));
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

  
  describe('when a member has been registered', function () {

    let eventWatcher;
    let memberId;
    let memberNumber;
    let events;

    before(async function () {
      memberId = web3.fromAscii("Ford");
      eventWatcher = registry.MemberRegistered();
      await registry.registerMember(memberId, {from: registryOwner});
      events = await eventWatcher.get();
      memberNumber = await registry.getMemberNumber(memberId);
      //console.log("memberNumber: " + memberNumber);
    });

    it('registerMember can not be called more than once for same member id', async function () {
      await assertRevert(registry.registerMember(memberId, {from: registryOwner}));
    });      

    it('getMemberTotalCount should be return 1', async function () {
      let count = await registry.getMemberTotalCount();
      assert.equal(count, 1);
    });

    it('getMemberNumber should be return correct number', async function () {
      assert.equal(1, memberNumber);
    }); 

    it('getMember should be return correct values', async function () {
      let memberArray = await registry.getMember(memberNumber);
      console.log(memberArray);
      assert.equal(parseInt(memberNumber), parseInt(memberArray[0]), "incorrect member number");
      assert.equal(web3.toUtf8(memberId), web3.toUtf8(memberArray[1]), "incorrect member id");
      assert.equal(registryOwner, memberArray[2], "incorrect value for owner");
      assert.isTrue(memberArray[3].valueOf(), "incorrect value for enabled"); //enabled
      assert.isTrue(memberArray[4].valueOf() > 0, "expected created value to be greater than 0"); //created date
    });     

    it('isMemberRegistered should be true', async function () {      
      assert.isTrue(await registry.isMemberRegistered(memberNumber));
    });
            
    it('emits MemberRegistered event', async function () {      
      assert.equal(1, events.length, "expected number of events to be 1");
      assert.equal(memberNumber, events[0].args.memberNumber.valueOf()), 
      assert.equal(
        web3.toUtf8(memberId),
        web3.toUtf8(events[0].args.memberId.valueOf())
        );                
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
      let attribEvents;

      before(async function () {
        attribWatcher = registry.MemberAttributeChanged();
        attribName = web3.fromAscii("Country");
        attribType = web3.fromAscii('Address');
        attribVal = web3.fromAscii("USA");
        assert.equal(0, await registry.getMemberAttributeTotalCount(memberNumber));
        await registry.addMemberAttribute(memberNumber, attribName, attribType, attribVal);
        attribEvents = await attribWatcher.get();
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
        let events = attribEvents;
        assert.equal(1, events.length);
        assert.equal(memberNumber, events[0].args.memberNumber.valueOf());  
        assert.equal(attribNumber, events[0].args.attributeNumber.valueOf());  
        assert.equal(web3.toUtf8(attribName), web3.toUtf8(events[0].args.attributeName.valueOf()));
        assert.equal(web3.toUtf8(attribType), web3.toUtf8(events[0].args.attributeType.valueOf()));  
        assert.equal(web3.toUtf8(attribVal), web3.toUtf8(events[0].args.attributeValue.valueOf()));      
      });        

      describe("the attribute can be changed (set)", function() {
        let newVal = web3.fromAscii("UK");
        let newType = web3.fromAscii("Changed Type");
        let attribChangedEvents;

        before(async function() {
          await registry.setMemberAttribute(memberNumber, attribNumber, newType, newVal);
          attribChangedEvents = await attribWatcher.get();
        });

        it('which emits event', async function () {          
          let events = attribChangedEvents;
          assert.equal(1, events.length);
          assert.equal(memberNumber, events[0].args.memberNumber.valueOf());  
          assert.equal(attribNumber, events[0].args.attributeNumber.valueOf());  
          assert.equal(web3.toUtf8(attribName), web3.toUtf8(events[0].args.attributeName.valueOf()));
          assert.equal(web3.toUtf8(newType), web3.toUtf8(events[0].args.attributeType.valueOf()));  
          assert.equal(web3.toUtf8(newVal), web3.toUtf8(events[0].args.attributeValue.valueOf()));  
        }); 
        
        it("getMemberAttribute returns new values", async function() {
          var attr = await registry.getMemberAttribute(memberNumber, attribNumber);
          assert.equal(web3.toUtf8(newType), web3.toUtf8(attr[2]));  
          assert.equal(web3.toUtf8(newVal), web3.toUtf8(attr[3]));            
        });
      });
      
      it('non owner can not set attribute value', async function () {
        await assertRevert(registry.setMemberAttribute(memberNumber, attribNumber, attribType, attribVal, {from: accounts[1]}));
      });      
         
    });

    describe('The member can be disabled', function () {
      let disabledEventWatcher;

      before(async function () {
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

        before(async function () {
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

        describe('the owner can transfer the ownership of the member', function () {
          let transferKey;
          let transferKeyHash;
          let newOwner;
          let initialOwner;
          let transferEventWatcher;
          let transferEvents;
    
          before(async function () {
            transferEventWatcher = registry.MemberOwnershipTransferRequest();        
            transferKey = "Shhhhhhh";
            transferKeyHash = web3.sha3(web3.toHex(transferKey), {encoding:"hex"});
            newOwner = accounts[1];
            var member = await registry.getMember(1)
            initialOwner = member[2];
            await registry.transferMemberOwnership(memberNumber, newOwner, transferKeyHash, {from: initialOwner});
            transferEvents = await transferEventWatcher.get();
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
            await assertRevert(registry.acceptMemberOwnership(memberNumber, "wrong secret", {from: newOwner}));
          });        
          
          it('emits the MemberOwnershipTransferRequest event', async function () {
            let events = transferEvents;
            assert.equal(1, events.length);
            assert.equal(memberNumber, events[0].args.memberNumber.valueOf());
            assert.equal(events[0].args.from.valueOf(), initialOwner);
            assert.equal(events[0].args.to.valueOf(), newOwner);
          });
    
          describe('when acceptMemberOwnership is called by the pending owner', function () {
    
            let transferAcceptedEventWatcher;
            let transferAcceptedEvents;
    
            before(async function () {
              transferAcceptedEventWatcher = registry.MemberOwnershipTransferAccepted();        
              await registry.acceptMemberOwnership(memberNumber, transferKey, {from: newOwner});
              transferAcceptedEvents = await transferAcceptedEventWatcher.get();
            });
    
            it('getMember returns the new owner', async function () {  
              var member = await registry.getMember(memberNumber);     
               assert.equal(newOwner, member[2]);
            }); 
    
            it('emits MemberOwnershipTransferAccepted event', async function () {
              let events = transferAcceptedEvents;
              assert.equal(1, events.length);
              assert.equal(memberNumber, events[0].args.memberNumber.valueOf());
              assert.equal(events[0].args.newOwner.valueOf(), newOwner);
            });        
    
          });

      });
    });
    })

  });

});