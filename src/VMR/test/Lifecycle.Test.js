import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var ManufacturerRegistry = artifacts.require("ManufacturerRegistry");
var VehicleRegistry = artifacts.require("VehicleRegistry");
var MaintainerRegistry = artifacts.require("MaintainerRegistry");
var MaintenanceLog = artifacts.require('MaintenanceLog');
var EternalStorage = artifacts.require('EternalStorage');
var MockFeeChecker = artifacts.require("MockFeeChecker");

contract('MaintenanceLog Vehicle Lifecycle', function (accounts) {

    let vin;
    let vehicleNumber;
    let manufacturerId;
    let manufacturerNumber;
    let maintainerId1;
    let maintainerAddress1;
    let maintainerNumber1;
    let maintainerId2;
    let maintainerAddress2;    
    let maintainerNumber2;

    let vehicleRegistryOwner;
    let manufacturerRegistryOwner;
    let maintainerRegistryOwner;

    let manufacturerAccount;
    let firstOwnerAccount;
    let secondOwnerAccount;

    let vehicleRegistryFeeChecker;
    let vehicleRegistry;
    let vehicleRegistryStorage;

    let manufacturerRegistryFeeChecker;
    let manufacturerRegistry;
    let manufacturerStorage;

    let maintainerRegistryFeeChecker;
    let maintainerRegistry;
    let maintainerStorage;

    let maintenanceLog;
    let maintenanceLogStorage;

    let manufacturerRegistryFee;
    let vehicleRegistryFee;
    let maintainerRegistryFee;

    let jobId;
    let date;
    let title;
    let description;
    let ipfsAddress;
    let docTitle;
    let logNumber;
    let docNumber;

    before(async function () {

        vin = web3.fromAscii("01234567890123456");
        manufacturerId = web3.fromAscii("Ford Motor Company");
        maintainerId1 = web3.fromAscii("Service Centre 1");
        maintainerId2 = web3.fromAscii("Service Centre 2");

        vehicleRegistryOwner = accounts[0];
        manufacturerRegistryOwner = accounts[1];
        manufacturerAccount = accounts[2];
        maintainerRegistryOwner = accounts[3];
        firstOwnerAccount = accounts[4];
        secondOwnerAccount = accounts[5];
        maintainerAddress1 = accounts[6];
        maintainerAddress2 = accounts[7];

        manufacturerRegistryFee = 100;
        vehicleRegistryFee = 10;
        maintainerRegistryFee = 50;

        vehicleRegistryFeeChecker = await MockFeeChecker.new(vehicleRegistryFee);
        manufacturerRegistryFeeChecker = await MockFeeChecker.new(manufacturerRegistryFee);
        maintainerRegistryFeeChecker = await MockFeeChecker.new(maintainerRegistryFee);
        
        manufacturerStorage = await EternalStorage.new({from: manufacturerRegistryOwner});
        manufacturerRegistry = await ManufacturerRegistry.new(manufacturerStorage.address, manufacturerRegistryFeeChecker.address, {from: manufacturerRegistryOwner});
        await manufacturerStorage.setContractAddress(manufacturerRegistry.address, {from: manufacturerRegistryOwner});
        await manufacturerStorage.setStorageInitialised(true, {from: manufacturerRegistryOwner});

        vehicleRegistryStorage = await EternalStorage.new({from: vehicleRegistryOwner});
        vehicleRegistry = await VehicleRegistry.new(vehicleRegistryStorage.address, vehicleRegistryFeeChecker.address, manufacturerRegistry.address, {from: vehicleRegistryOwner});
        await vehicleRegistryStorage.setContractAddress(vehicleRegistry.address, {from: vehicleRegistryOwner});
        await vehicleRegistryStorage.setStorageInitialised(true, {from: vehicleRegistryOwner});        

        maintainerStorage = await EternalStorage.new({from: maintainerRegistryOwner});
        maintainerRegistry = await MaintainerRegistry.new(maintainerStorage.address, maintainerRegistryFeeChecker.address, {from: maintainerRegistryOwner});
        await maintainerStorage.setContractAddress(maintainerRegistry.address, {from: maintainerRegistryOwner});
        await maintainerStorage.setStorageInitialised(true, {from: maintainerRegistryOwner});                
      });

      it("the vehicle registry is referencing the expected manufacturer registry", async function () {
        assert.equal(manufacturerRegistry.address, await vehicleRegistry.manufacturerRegistryAddress.call());
      });

    describe("maintainer registers with maintainer registry", function() {
        before(async function () {
            await maintainerRegistry.registerMember(maintainerId1, {from: maintainerRegistryOwner, value: maintainerRegistryFee});
            maintainerNumber1 = await maintainerRegistry.getMemberNumber(maintainerId1);

            let secretKey = web3.sha3("TransferSecretKey");
            await maintainerRegistry.transferMemberOwnership(maintainerNumber1, maintainerAddress1, secretKey, {from: maintainerRegistryOwner, value: maintainerRegistryFee});
            await maintainerRegistry.acceptMemberOwnership(maintainerNumber1, secretKey, {from: maintainerAddress1});
        });

        it("The maintainer is owned my the correct account", async function() {
            assert.equal(maintainerAddress1, await maintainerRegistry.getMemberOwner(maintainerId1), "Unexpected maintainer owner");
        });

        it("The maintainer is registered and enabled", async function() {
            assert.isTrue(await maintainerRegistry.isMemberRegisteredAndEnabled(maintainerId1), "Expected maintainer to be registered and enabled");
        });    
    });

    describe("manufacturer registers with manufacturer registry", function () {

        before(async function () {
            await manufacturerRegistry.registerMember(manufacturerId, {from: manufacturerRegistryOwner, value: manufacturerRegistryFee});
            manufacturerNumber = await manufacturerRegistry.getMemberNumber(manufacturerId);

            let manufacturerTransferKey = web3.sha3("TransferSecretKey");
            await manufacturerRegistry.transferMemberOwnership(manufacturerNumber, manufacturerAccount, manufacturerTransferKey, {from: manufacturerRegistryOwner, value: manufacturerRegistryFee});
            await manufacturerRegistry.acceptMemberOwnership(manufacturerNumber, manufacturerTransferKey, {from: manufacturerAccount});
        });

        it("The manufacturer is owned my the correct account", async function() {
            assert.equal(manufacturerAccount, await manufacturerRegistry.getMemberOwner(manufacturerId), "Unexpected manufacturer owner");
        });

        it("The manufacturer is registered and enabled", async function() {
            assert.isTrue(await manufacturerRegistry.isMemberRegisteredAndEnabled(manufacturerId), "Unexpected manufacturer to be registered and enabled");
        });
    });        

    describe("manufacturer registers vehicle", function () {
        before(async function () {
            await vehicleRegistry.registerVehicle(vin, manufacturerId, {from: manufacturerAccount, value: vehicleRegistryFee});
            vehicleNumber = await vehicleRegistry.getMemberNumber(vin);
        });

        it("vehicle is registered and enabled", async function() {
            assert.isTrue(await vehicleRegistry.isMemberRegisteredAndEnabled(vin));
        });
    });

    describe("manufacturer creates maintenance log", function () { 
        before(async function () {
            maintenanceLogStorage = await EternalStorage.new({from: manufacturerAccount});
            maintenanceLog = await MaintenanceLog.new(maintenanceLogStorage.address, vehicleRegistry.address, maintainerRegistry.address, vin, {from: manufacturerAccount});
            await maintenanceLogStorage.setContractAddress(maintenanceLog.address, {from: manufacturerAccount});
            await maintenanceLogStorage.setStorageInitialised(true, {from: manufacturerAccount});
        });

        it("log exists with correct vin", async function() {
            assert.equal(web3.toUtf8(vin), web3.toUtf8(await maintenanceLog.vin.call()));
        });
    });

    describe("manufacturer assigns maintenance log to vehicle registry", function () { 
        before(async function () {
            await vehicleRegistry.setMaintenanceLogAddress(vehicleNumber, maintenanceLog.address, {from: manufacturerAccount});
        });

        it("maintaince log address is correct", async function() {
            assert.equal(maintenanceLog.address, await vehicleRegistry.getMaintenanceLogAddress(vehicleNumber));
        });
    });  

    describe("manufacturer adds work authorisation to maintainer 1", function () { 
        before(async function () {
            await maintenanceLog.addWorkAuthorisation(maintainerId1, {from: manufacturerAccount});
        }); 

        it("isAuthorised returns true", async function() {
            assert.isTrue(await maintenanceLog.isAuthorised(maintainerId1));
        });
    });    

    describe("maintainer1 adds log", function () { 

        before(async function () {
            jobId = web3.fromAscii("PostManufactureCheck1");
            date = Math.round(new Date().getTime() / 1000);
            title = "Post Manufacture Check 1";
            description = "Full vehicle inspection to prove vehicle is fit to be sold";
            docTitle = "Post Manufacture Check Certificate";
            ipfsAddress = web3.fromAscii("SomeAddres");

            await maintenanceLog.add(jobId, maintainerId1, date, title, description, {from: maintainerAddress1});
            logNumber = await maintenanceLog.getLogNumber(jobId);
            await maintenanceLog.addDoc(logNumber, docTitle, ipfsAddress, {from: maintainerAddress1});
            docNumber = 1;
        });

        it("The log can be returned", async function() {
            let log = await maintenanceLog.getLog(logNumber);
            assert.equal(parseInt(logNumber), parseInt(log[0]));
            assert.equal(web3.toUtf8(jobId), web3.toUtf8(log[1]));
            assert.equal(web3.toUtf8(maintainerId1), web3.toUtf8(log[2]));
            assert.equal(maintainerAddress1, log[3]);
            assert.equal(date, parseInt(log[4]));
            assert.equal(title, log[5]);
            assert.equal(description, log[6]);
            assert.isFalse(log[7]);
        });

        it("The doc can be returned", async function() {
            let doc = await maintenanceLog.getDoc(logNumber, docNumber);
            assert.equal(1, doc[0], "unexpected doc number from getDoc");
            assert.equal(docTitle, doc[1]);
            assert.equal(web3.toUtf8(ipfsAddress), web3.toUtf8(doc[2]));
        });              
    });    

    describe("manufacturer verifies log", function () { 
        before(async function () {
            await maintenanceLog.verify(logNumber, {from: manufacturerAccount});
        });

        it("the log is now verified", async function() {
            let log = await maintenanceLog.getLog(logNumber);
            assert.isTrue(log[7]);
        });
    });         
});  
