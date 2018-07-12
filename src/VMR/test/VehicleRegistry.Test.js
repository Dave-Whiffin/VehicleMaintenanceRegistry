import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var VehicleRegistry = artifacts.require('VehicleRegistry');
var EternalStorage = artifacts.require('EternalStorage');
var MockRegistryFeeChecker = artifacts.require('MockRegistryFeeChecker');
var MockRegistryLookup = artifacts.require("MockRegistryLookup");

contract('VehicleRegistry', function (accounts) {

    let registry;
    let registryFeeChecker;
    let eternalStorage;
    let registryOwner;
    let vin;
    let manufacturerId;
    let manufacturerRegistry;
    let logInfoEventWatcher;

    beforeEach(async function () {
        vin = web3.fromAscii("01234567890123456");
        manufacturerId = web3.fromAscii("Ford");
        registryFeeChecker = await MockRegistryFeeChecker.new(0, 0);
        manufacturerRegistry = await MockRegistryLookup.new();
        eternalStorage = await EternalStorage.new();
        registry = await VehicleRegistry.new(eternalStorage.address, registryFeeChecker.address, manufacturerRegistry.address);
        logInfoEventWatcher = registry.LogInfo();
        registryOwner = await registry.owner.call();
        await eternalStorage.setContractAddress(registry.address);
        await eternalStorage.setStorageInitialised(true);
        await manufacturerRegistry.setMock(manufacturerId, registryOwner, true);
      });

    it("isMemberRegisteredAndEnabled returns false when not registered", async function() {
        assert.isFalse(await registry.isMemberRegisteredAndEnabled(vin));
    });

    it("getMemberOwner throws", async function() {
        await assertRevert(registry.getMemberOwner(vin));
    });    


    it("Base function 'Registry.registerMember' is disabled and will throw if called", async function() {
        await assertRevert(registry.registerMember(vin));
    });

    it("registerVehicle won't accept an unregistered manufacturer", async function() {
        await assertRevert(registry.registerVehicle(vin, web3.fromUtf8("Fake")));
    });

    it("registerVehicle can't be called by someone who is not the manufacturer", async function() {
        await assertRevert(registry.registerVehicle(vin, manufacturerId, {from : accounts[1]}));
    });    

    it("registerVehicle can't be called when the contract is paused", async function() {
        await registry.pause();
        await assertRevert(registry.registerVehicle(vin, manufacturerId, {from : accounts[1]}));
    });   
    
    it("registerVehicle can't be called when value is below fee", async function() {
        await registryFeeChecker.setRegistrationFeeWei(10);
        await assertRevert(registry.registerVehicle(vin, manufacturerId));
    });    
    
    it("registerVehicle can't be called with duplicate vin", async function() {
        registry.registerVehicle(vin, manufacturerId);
        await assertRevert(registry.registerVehicle(vin, manufacturerId));
    });        

      describe("when the vehicle is registered", function() {

        let vehicleOwner;
        let memberNumber;

        beforeEach(async function () {
            //console.log("begin registerVehicle")
            //console.log("vin: " + web3.toUtf8(vin));
            //console.log("manufacturerId: " + web3.toUtf8(manufacturerId));
            //console.log("begin registry.registerVehicle")
            await registry.registerVehicle(vin, manufacturerId);
            //console.log("end registry.registerVehicle")
            vehicleOwner = registryOwner;
            //console.log("begin registry.GetMemberNumber");
            memberNumber = await registry.getMemberNumber(vin);
            //console.log("end registry.GetMemberNumber");
          });

        it("getMemberOwner returns correct owner", async function() {
            var result = await registry.getMemberOwner(vin);
            assert.equal(vehicleOwner, result);
        });            

        it("isMemberRegisteredAndEnabled returns true", async function() {
            var result = await registry.isMemberRegisteredAndEnabled(vin);
            assert.isTrue(result);
        });   
        
        it("Manufacturer is added automatically as an attribute", async function() {
            assert.equal(1, await registry.getMemberAttributeTotalCount(memberNumber));
            let result = await registry.getMemberAttribute(memberNumber, 1);
            let number = result[0];
            //console.log(result);
            let name = web3.toUtf8(result[1]);
            let type = web3.toUtf8(result[2]);
            let value = web3.toUtf8(result[3]);

            assert.equal(1, number);
            assert.equal("manufacturer", name);
            assert.equal("id", type);
            assert.equal(web3.toUtf8(manufacturerId), value);
        });           

        describe("when the vehicle is disabled", function() {

            beforeEach(async function () {
                await registry.disableMember(memberNumber);
              });
    
            it("isMemberRegisteredAndEnabled returns false", async function() {
                var result = await registry.isMemberRegisteredAndEnabled(vin);
                assert.isFalse(result);
            });          
    
          });        

      });
});