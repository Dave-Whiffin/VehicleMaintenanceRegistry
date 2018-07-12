import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var VehicleRegistry = artifacts.require('VehicleRegistry');
var EternalStorage = artifacts.require('EternalStorage');
var MockRegistryFeeChecker = artifacts.require('MockRegistryFeeChecker');
var MockManufacturerRegistry = artifacts.require("MockManufacturerRegistry");

contract('VehicleRegistry', function (accounts) {

    let registry;
    let registryFeeChecker;
    let eternalStorage;
    let registryOwner;
    let vin;
    let manufacturerId;
    let manufacturerRegistry;

    beforeEach(async function () {
        vin = web3.fromAscii("01234567890123456");
        manufacturerId = web3.fromAscii("Ford");
        registryFeeChecker = await MockRegistryFeeChecker.new(0, 0);
        manufacturerRegistry = await MockManufacturerRegistry.new();
        eternalStorage = await EternalStorage.new();
        registry = await VehicleRegistry.new(eternalStorage.address, registryFeeChecker.address, manufacturerRegistry.address);
        registryOwner = await registry.owner.call();
        await eternalStorage.setContractAddress(registry.address);
        await eternalStorage.setStorageInitialised(true);
        await manufacturerRegistry.setMock(manufacturerId, registryOwner, true);
      });

    it("isVehicleRegisteredAndEnabled returns false when not registered", async function() {
        assert.isFalse(await registry.isVehicleRegisteredAndEnabled(vin));
    });

    it("getVehicleOwner throws", async function() {
        await assertRevert(registry.getVehicleOwner(vin));
    });    


      /*
      it("Base function 'Registry.registerMember' is disabled and will throw if called", async function() {
        await assertRevert(registry.registerMember(vin));
      });
      */

      describe("when the vehicle is registered", function() {

        let vehicleOwner;
        let memberNumber;

        beforeEach(async function () {
            await registry.registerVehicle(vin, manufacturerId);
            vehicleOwner = registryOwner;
            memberNumber = await registry.getMemberNumber(vin);
          });

        it("getVehicleOwner returns correct owner", async function() {
            var result = await registry.getVehicleOwner(vin);
            assert.equal(manufacturerOwner, result);
        });            

        it("isVehicleRegisteredAndEnabled returns true", async function() {
            var result = await registry.isVehicleRegisteredAndEnabled(vin);
            assert.isTrue(result);
        });          

        describe("when the vehicle is disabled", function() {

            beforeEach(async function () {
                await registry.disableMember(memberNumber);
              });
    
            it("isVehicleRegisteredAndEnabled returns false", async function() {
                var result = await registry.isVehicleRegisteredAndEnabled(vin);
                assert.isFalse(result);
            });          
    
          });        

      });
});