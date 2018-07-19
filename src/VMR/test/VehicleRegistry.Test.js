import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var VehicleRegistry = artifacts.require('VehicleRegistry');
var EternalStorage = artifacts.require('EternalStorage');
var MockFeeChecker = artifacts.require('MockFeeChecker');
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
    let memberRegisteredEventWatcher;

    before(async function () {
        vin = web3.fromAscii("01234567890123456");
        manufacturerId = web3.fromAscii("Ford");
        registryFeeChecker = await MockFeeChecker.new(0);
        manufacturerRegistry = await MockRegistryLookup.new();
        eternalStorage = await EternalStorage.new();
        registry = await VehicleRegistry.new(eternalStorage.address, registryFeeChecker.address, manufacturerRegistry.address);
        logInfoEventWatcher = registry.LogInfo();
        memberRegisteredEventWatcher = registry.MemberRegistered();
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

    it("vin can't be less than 17 characters", async function() {
        await assertRevert(registry.registerVehicle("123456", manufacturerId));
    });

    it("vin can't be more than 17 characters", async function() {
        await assertRevert(registry.registerVehicle("12345678901234567890", manufacturerId));
    });    
    
    describe("When contract is paused", function() {

        before(async function() {
            await registry.pause();
        });

        after(async function() {
            await registry.unpause();
        });

        it("registerVehicle can't be called when the contract is paused", async function() {
            await assertRevert(registry.registerVehicle(vin, manufacturerId));
        });       
        
        it("The maintenance log address can not be set", async function() {
            await assertRevert(registry.setMaintenanceLogAddress(0, registry.address));
        });
    })

    describe("When a registration fee is set", function () {
        
        before(async function() {
            await registryFeeChecker.setFeeInWei(10);
        });
        after(async function() {
            await registryFeeChecker.setFeeInWei(0);
        });        

        it("registerVehicle can't be called when value is below fee", async function() {
            await assertRevert(registry.registerVehicle(vin, manufacturerId));
        });    
    })
    
      describe("when the vehicle is registered", function() {

        let vehicleOwner;
        let memberNumber;
        let logInfoEvents;
        let memberRegisteredEvents;

        before(async function () {
            //console.log("vin: " + web3.toUtf8(vin));
            //console.log("manufacturerId: " + web3.toUtf8(manufacturerId));
            //console.log("begin registry.registerVehicle")
            await registry.registerVehicle(vin, manufacturerId);
            logInfoEvents = await logInfoEventWatcher.get();
            memberRegisteredEvents = await memberRegisteredEventWatcher.get();
            //console.log("end registry.registerVehicle")
            vehicleOwner = registryOwner;
            //console.log("begin registry.GetMemberNumber");
            memberNumber = await registry.getMemberNumber(vin);
            //console.log("end registry.GetMemberNumber");
          });

        it("emits LogInfo event for before and after registration", async function() {
            let events = logInfoEvents;
            assert.equal(2, events.length);
            assert.equal("Begin registerVehicle", events[0].args.message);
            assert.equal("End registerVehicle", events[1].args.message);
        });

        it("emits MemberRegistered event", async function() {
            let events = memberRegisteredEvents;
            assert.equal(1, events.length);
            assert.equal(parseInt(memberNumber), parseInt(events[0].args.memberNumber), "unexpected member number");
            assert.equal(web3.toUtf8(vin), web3.toUtf8(events[0].args.memberId), "unexpected member id");
        });        

        it("registerVehicle can't be called with duplicate vin", async function() {
            await assertRevert(registry.registerVehicle(vin, manufacturerId));
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

        it("The manafucturer can not be changed", async function() {
            let attributeNumber = await registry.getMemberAttributeNumber(memberNumber, "manufacturer");
            await assertRevert(registry.setMemberAttribute(memberNumber, attributeNumber, web3.fromAscii("type"),  web3.fromAscii("val")));
        })

        it("The maintenance log address can be set and returned", async function() {
            //requires a contract address
            let maintenancelogAddress = registry.address;
            await registry.setMaintenanceLogAddress(memberNumber, maintenancelogAddress);
            let storedAddress = await registry.getMaintenanceLogAddress(memberNumber);
            assert.equal(maintenancelogAddress, storedAddress, "unexpected maintenance log address");
        });

        it("The maintenance log address can not be set by a non owner", async function() {
            await assertRevert(registry.setMaintenanceLogAddress(memberNumber, registry.address, {from: accounts[2]}));
        });         

        it("The maintenance log address must be a contract address", async function() {
            await assertRevert(registry.setMaintenanceLogAddress(memberNumber, ""));
        });        

        describe("when the vehicle is disabled", function() {

            before(async function () {
                await registry.disableMember(memberNumber);
              });

            after(async function () {
                await registry.enableMember(memberNumber);
            });              
    
            it("isMemberRegisteredAndEnabled returns false", async function() {
                var result = await registry.isMemberRegisteredAndEnabled(vin);
                assert.isFalse(result);
            });          

            it("The maintenance log address can not be set", async function() {
                await assertRevert(registry.setMaintenanceLogAddress(memberNumber, registry.address));
            });            

          });        

      });
});