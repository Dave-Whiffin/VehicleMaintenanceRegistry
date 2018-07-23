import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var ManufacturerRegistry = artifacts.require('ManufacturerRegistry');
var EternalStorage = artifacts.require('EternalStorage');
var MockFeeChecker = artifacts.require('MockFeeChecker');

contract('ManufacturerRegistry', function (accounts) {

    let registry;
    let registryFeeChecker;
    let eternalStorage;
    let registryOwner;
    let manufacturerId;

    before(async function () {
        manufacturerId = web3.toAscii("Ford");
        registryFeeChecker = await MockFeeChecker.new(0);
        eternalStorage = await EternalStorage.new();
        registry = await ManufacturerRegistry.new(eternalStorage.address, registryFeeChecker.address);
        registryOwner = await registry.owner.call();
        await eternalStorage.bindToContract(registry.address);
      });

      describe("when no manufacturers are registered", function() {

        it("isMemberRegisteredAndEnabled returns false when not registered", async function() {
            var result = await registry.isMemberRegisteredAndEnabled(manufacturerId);
            assert.isFalse(result);
        });

        it("getMemberOwner returns empty address when id does not exist", async function() {
            assert.equal(0, await registry.getMemberOwner(manufacturerId));
        });        

      });

      describe("when the manufacturer is registered", function() {

        let manufacturerOwner;
        let memberNumber;

        before(async function () {
            await registry.registerMember(manufacturerId);
            manufacturerOwner = registryOwner;
            memberNumber = await registry.getMemberNumber(manufacturerId);
          });

        it("getMemberOwner returns correct owner", async function() {
            var result = await registry.getMemberOwner(manufacturerId);
            assert.equal(manufacturerOwner, result);
        });            

        it("isMemberRegisteredAndEnabled returns true", async function() {
            var result = await registry.isMemberRegisteredAndEnabled(manufacturerId);
            assert.isTrue(result);
        });          

        describe("when the manufacturer is disabled", function() {

            before(async function () {
                await registry.disableMember(memberNumber);
              });
    
            it("isMemberRegisteredAndEnabled returns false", async function() {
                var result = await registry.isMemberRegisteredAndEnabled(manufacturerId);
                assert.isFalse(result);
            });          
    
          });        

      });
});