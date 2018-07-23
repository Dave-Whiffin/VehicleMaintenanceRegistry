import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var MaintainerRegistry = artifacts.require('MaintainerRegistry');
var EternalStorage = artifacts.require('EternalStorage');
var MockFeeChecker = artifacts.require('MockFeeChecker');

contract('MaintainerRegistry', function (accounts) {

    let registry;
    let registryFeeChecker;
    let eternalStorage;
    let registryOwner;
    let maintainerId;

    beforeEach(async function () {
        maintainerId = web3.toAscii("Vehicle Service One LTD");
        registryFeeChecker = await MockFeeChecker.new(0);
        eternalStorage = await EternalStorage.new();
        registry = await MaintainerRegistry.new(eternalStorage.address, registryFeeChecker.address);
        registryOwner = await registry.owner.call();
        await eternalStorage.setContractAddress(registry.address);
        await eternalStorage.setStorageInitialised(true);
      });

      describe("when no maintainers are registered", function() {

        it("isMemberRegisteredAndEnabled returns false when not registered", async function() {
            var result = await registry.isMemberRegisteredAndEnabled(maintainerId);
            assert.isFalse(result);
        });

        it("getMemberOwner returns empty address when id does not exist", async function() {
            assert.equal(0, await registry.getMemberOwner(maintainerId));
        });        

      });

      describe("when the maintainer is registered", function() {

        let maintainerOwner;
        let memberNumber;

        beforeEach(async function () {
            await registry.registerMember(maintainerId);
            maintainerOwner = registryOwner;
            memberNumber = await registry.getMemberNumber(maintainerId);
          });

        it("getMemberOwner returns correct owner", async function() {
            var result = await registry.getMemberOwner(maintainerId);
            assert.equal(maintainerOwner, result);
        });            

        it("isMemberRegisteredAndEnabled returns true", async function() {
            var result = await registry.isMemberRegisteredAndEnabled(maintainerId);
            assert.isTrue(result);
        });          

        describe("when the maintainer is disabled", function() {

            beforeEach(async function () {
                await registry.disableMember(memberNumber);
              });
    
            it("isMemberRegisteredAndEnabled returns false", async function() {
                var result = await registry.isMemberRegisteredAndEnabled(maintainerId);
                assert.isFalse(result);
            });          
    
          });        

      });
});