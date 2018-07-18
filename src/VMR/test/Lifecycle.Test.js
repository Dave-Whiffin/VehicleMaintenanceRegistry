import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var ManufacturerRegistry = artifacts.require("ManufacturerRegistry");
var VehicleRegistry = artifacts.require("VehicleRegistry");
var MaintenanceLog = artifacts.require('MaintenanceLog');
var EternalStorage = artifacts.require('EternalStorage');
var MockFeeChecker = artifacts.require("MockFeeChecker");

contract('MaintenanceLog Vehicle Lifecycle', function (accounts) {

    let vin;
    let vehicleNumber;
    let manufacturerId;
    let manufacturerNumber;

    let vehicleRegistryOwner;
    let manufacturerRegistryOwner;

    let manufacturerAccount;
    let firstOwnerAccount;
    let secondOwnerAccount;

    let vehicleRegistryFeeChecker;
    let vehicleRegistry;
    let vehicleRegistryStorage;

    let manufacturerRegistryFeeChecker;
    let manufacturerRegistry;
    let manufacturerStorage;

    let maintenanceLog;
    let maintenanceLogStorage;

    let mechanic1;
    let mechanic2;
    let mechanic3;

    let manufacturerRegistryFee;
    let vehicleRegistryFee;

    before(async function () {

        manufacturerId = web3.fromAscii("Ford Motor Company");
        vin = web3.fromAscii("01234567890123456");

        vehicleRegistryOwner = accounts[0];
        manufacturerRegistryOwner = accounts[1];
        manufacturerAccount = accounts[2];
        firstOwnerAccount = accounts[3];
        secondOwnerAccount = accounts[4];
        mechanic1 = accounts[5];
        mechanic2 = accounts[6];
        mechanic3 = accounts[7];

        manufacturerRegistryFee = 20;
        vehicleRegistryFee = 10;
        vehicleRegistryFeeChecker = await MockFeeChecker.new(vehicleRegistryFee);
        manufacturerRegistryFeeChecker = await MockFeeChecker.new(manufacturerRegistryFee);
        

        console.log("deploying manufacturer storage");
        manufacturerStorage = await EternalStorage.new({from: manufacturerRegistryOwner});
        console.log("deploying manufacturer registry");
        manufacturerRegistry = await ManufacturerRegistry.new(manufacturerStorage.address, manufacturerRegistryFeeChecker.address, {from: manufacturerRegistryOwner});
        console.log("Assigning manufacture storage to registry");
        await manufacturerStorage.setContractAddress(manufacturerRegistry.address, {from: manufacturerRegistryOwner});
        console.log("Setting manufacturer registry storage as initialised");
        await manufacturerStorage.setStorageInitialised(true, {from: manufacturerRegistryOwner});

        console.log("Deploying vehicle registry storage")
        vehicleRegistryStorage = await EternalStorage.new({from: vehicleRegistryOwner});
        console.log("deploying vehicle registry");
        vehicleRegistry = await VehicleRegistry.new(vehicleRegistryStorage.address, vehicleRegistryFeeChecker.address, manufacturerRegistry.address, {from: vehicleRegistryOwner});
        console.log("Assigning vehicle registry storage to registry");
        await vehicleRegistryStorage.setContractAddress(vehicleRegistry.address, {from: vehicleRegistryOwner});
        console.log("Setting vehicle registry storage as initialised");
        await vehicleRegistryStorage.setStorageInitialised(true, {from: vehicleRegistryOwner});        
      });

      it("the vehicle registry is referencing the expected manufacturer registry", async function () {
        assert.equal(manufacturerRegistry.address, await vehicleRegistry.manufacturerRegistryAddress.call());
      });

    describe("manufacturer registers with manufacturer registry", function () {

        before(async function () {
            console.log("registering manufacturer");
            await manufacturerRegistry.registerMember(manufacturerId, {from: manufacturerRegistryOwner, value: manufacturerRegistryFee});
            console.log("retrieving manufacturer number");
            manufacturerNumber = await manufacturerRegistry.getMemberNumber(manufacturerId);

            let manufacturerTransferKey = web3.sha3("TransferSecretKey");
            console.log("transferring ownership from manufacture registry to manufacturer");
            await manufacturerRegistry.transferMemberOwnership(manufacturerNumber, manufacturerAccount, manufacturerTransferKey, {from: manufacturerRegistryOwner, value: manufacturerRegistryFee});
            console.log("accepting manufacturer ownership");
            await manufacturerRegistry.acceptMemberOwnership(manufacturerNumber, manufacturerTransferKey, {from: manufacturerAccount});
            console.log("manufacturer ownership transfer is complete");
        });

        it("The manufacturer is owned my the correct account", async function() {
            assert.equal(manufacturerAccount, await manufacturerRegistry.getMemberOwner(manufacturerId), "Unexpected manufacturer owner");
        });

        it("The manufacturer is registered and enabled", async function() {
            assert.isTrue(await manufacturerRegistry.isMemberRegisteredAndEnabled(manufacturerId), "Unexpected manufacturer to be registered and enabled");
        });        

        describe("manufacturer registers vehicle", function () {
            before(async function () {
                console.log("registering new vehicle");
                await vehicleRegistry.registerVehicle(vin, manufacturerId, {from: manufacturerAccount, value: vehicleRegistryFee});
                console.log("vehicle regisered");
                console.log("retrieving vehicle number");
                vehicleNumber = await vehicleRegistry.getMemberNumber(vin);
                console.log("vehicle number retrieved");
            });

            describe("manufacturer creates maintenance log", function () { 
                before(async function () {
                    maintenanceLogStorage = await EternalStorage.new({from: manufacturerAccount});
                    maintenanceLog = await MaintenanceLog.new(maintenanceLogStorage.address, vehicleRegistry.address, vin, {from: manufacturerAccount});
                    await maintenanceLogStorage.setContractAddress(maintenanceLog.address, {from: manufacturerAccount});
                    await maintenanceLogStorage.setStorageInitialised(true, {from: manufacturerAccount});
                });

                describe("manufacturer assigns maintenance log to vehicle registry", function () { 
                    before(async function () {
                        await vehicleRegistry.setMaintenanceLogAddress(vehicleNumber, maintenanceLog.address, {from: manufacturerAccount});
                    });

                    describe("manufacturer adds work authorisation to mechanic 1", function () { 
                        before(async function () {
                            await maintenanceLog.addWorkAuthorisation(mechanic1, {from: manufacturerAccount});
                        });

                        describe("mechanic1 adds log", function () { 
                            let jobId;
                            let date;
                            let title;
                            let description;
                            let ipfsAddress;
                            let docTitle;
                            let logNumber;
                            let docNumber;

                            before(async function () {
                                jobId = web3.fromAscii("PostManufactureCheck1");
                                date = Math.round(new Date().getTime() / 1000);
                                title = "Post Manufacture Check 1";
                                description = "Full vehicle inspection to prove vehicle is fit to be sold";
                                docTitle = "Post Manufacture Check Certificate";
                                ipfsAddress = web3.fromAscii("SomeAddres");

                                await maintenanceLog.add(jobId, date, title, description, {from: mechanic1});
                                logNumber = await maintenanceLog.getLogNumber(jobId);
                                await maintenanceLog.addDoc(logNumber, docTitle, ipfsAddress, {from: mechanic1});
                                docNumber = 1;
                            });

                            it("The log can be returned", async function() {
                                let log = maintenanceLog.getLog(logNumber);
                                assert.equal(parseInt(logNumber), parseInt(log[0]));
                                assert.equal(web3.toUtf8(jobId), web3.toUtf8(log[1]));
                                assert.equal(mechanic1, log[2]);
                                assert.equal(title, log[4]);
                                assert.equal(description, log[5]);
                                assert.isFalse(log[6]);
                            });

                            it("The doc can be returned", async function() {
                                let doc = maintenanceLog.getDoc(logNumber, docNumber);
                                assert.equal(docTitle, doc[1]);
                                assert.equal(web3.toUtf8(ipfsAddress), web3.toUtf8(doc[2]));
                            });

                            describe("manufacturer verifies log", function () { 
                                before(async function () {
                                    await maintenanceLog.verify(logNumber, {from: manufacturerAccount});
                                });

                                it("the log is now verified", async function() {
                                    let log = await maintenanceLog.getLog(logNumber);
                                    assert.isTrue(log[6]);
                                });
                            });
                        });   
                    });
                });  
            });      
        }); 
    });  
});  
