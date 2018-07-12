import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var VehicleRegistry = artifacts.require('VehicleRegistry');
var EternalStorage = artifacts.require('EternalStorage');
var MockRegistryFeeChecker = artifacts.require('MockRegistryFeeChecker');

contract('ManufacturerRegistry', function (accounts) {

    let registry;
    let registryFeeChecker;
    let eternalStorage;
    let registryOwner;
    let manufacturerId;

    beforeEach(async function () {
        manufacturerId = web3.toAscii("Ford");
        registryFeeChecker = await MockRegistryFeeChecker.new(0, 0);
        eternalStorage = await EternalStorage.new();
        registry = await VehicleRegistry.new(eternalStorage.address, registryFeeChecker.address);
        registryOwner = await registry.owner.call();
        await eternalStorage.setContractAddress(registry.address);
        await eternalStorage.setStorageInitialised(true);
      });

      describe("when no vehicles are registered", function() {

        it("isManufacturerRegisteredAndEnabled returns false when not registered", async function() {
            var result = await registry.isManufacturerRegisteredAndEnabled(manufacturerId);
            assert.isFalse(result);
        });

        it("getManufacturerOwner throws", async function() {
            await assertRevert(registry.getManufacturerOwner(manufacturerId));
        });        

      });

      describe("when the manufacturer is registered", function() {

        let manufacturerOwner;
        let memberNumber;

        beforeEach(async function () {
            await registry.registerMember(manufacturerId);
            manufacturerOwner = registryOwner;
            memberNumber = await registry.getMemberNumber(manufacturerId);
          });

        it("getManufacturerOwner returns correct owner", async function() {
            var result = await registry.getManufacturerOwner(manufacturerId);
            assert.equal(manufacturerOwner, result);
        });            

        it("isManufacturerRegisteredAndEnabled returns true", async function() {
            var result = await registry.isManufacturerRegisteredAndEnabled(manufacturerId);
            assert.isTrue(result);
        });          

        describe("when the manufacturer is disabled", function() {

            beforeEach(async function () {
                await registry.disableMember(memberNumber);
              });
    
            it("isManufacturerRegisteredAndEnabled returns false", async function() {
                var result = await registry.isManufacturerRegisteredAndEnabled(manufacturerId);
                assert.isFalse(result);
            });          
    
          });        

      });
});