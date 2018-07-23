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

    let transferKey;
    let transferKeyHash;

    before(async function () {

        vin = web3.fromAscii("01234567890123456");
        manufacturerId = web3.fromAscii("Ford Motor Company");
        maintainerId1 = web3.fromAscii("Service Centre 1");
        maintainerId2 = web3.fromAscii("Service Centre 2");

        transferKey = "Shhhhhhh";
        transferKeyHash = web3.sha3(web3.toHex(transferKey), {encoding:"hex"});

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
        await manufacturerStorage.bindToContract(manufacturerRegistry.address, {from: manufacturerRegistryOwner});

        vehicleRegistryStorage = await EternalStorage.new({from: vehicleRegistryOwner});
        vehicleRegistry = await VehicleRegistry.new(vehicleRegistryStorage.address, vehicleRegistryFeeChecker.address, manufacturerRegistry.address, {from: vehicleRegistryOwner});
        await vehicleRegistryStorage.bindToContract(vehicleRegistry.address, {from: vehicleRegistryOwner});

        maintainerStorage = await EternalStorage.new({from: maintainerRegistryOwner});
        maintainerRegistry = await MaintainerRegistry.new(maintainerStorage.address, maintainerRegistryFeeChecker.address, {from: maintainerRegistryOwner});
        await maintainerStorage.bindToContract(maintainerRegistry.address, {from: maintainerRegistryOwner});
      });

      it("the vehicle registry is referencing the expected manufacturer registry", async function () {
        assert.equal(manufacturerRegistry.address, await vehicleRegistry.manufacturerRegistryAddress.call());
      });

    describe("maintainer 1 registers with maintainer registry", function() {
        before(async function () {
            await maintainerRegistry.registerMember(maintainerId1, {from: maintainerRegistryOwner, value: maintainerRegistryFee});
            maintainerNumber1 = await maintainerRegistry.getMemberNumber(maintainerId1);

            await maintainerRegistry.transferMemberOwnership(maintainerNumber1, maintainerAddress1, transferKeyHash, {from: maintainerRegistryOwner, value: maintainerRegistryFee});
            await maintainerRegistry.acceptMemberOwnership(maintainerNumber1, transferKey, {from: maintainerAddress1});
        });

        it("The maintainer is owned my the correct account", async function() {
            assert.equal(maintainerAddress1, await maintainerRegistry.getMemberOwner(maintainerId1), "Unexpected maintainer owner");
        });

        it("The maintainer is registered and enabled", async function() {
            assert.isTrue(await maintainerRegistry.isMemberRegisteredAndEnabled(maintainerId1), "Expected maintainer to be registered and enabled");
        });    
    });

    describe("maintainer 2 registers with maintainer registry", function() {
        before(async function () {
            await maintainerRegistry.registerMember(maintainerId2, {from: maintainerRegistryOwner, value: maintainerRegistryFee});
            maintainerNumber2 = await maintainerRegistry.getMemberNumber(maintainerId2);

            await maintainerRegistry.transferMemberOwnership(maintainerNumber2, maintainerAddress2, transferKeyHash, {from: maintainerRegistryOwner, value: maintainerRegistryFee});
            await maintainerRegistry.acceptMemberOwnership(maintainerNumber2, transferKey, {from: maintainerAddress2});
        });

        it("The maintainer is owned my the correct account", async function() {
            assert.equal(maintainerAddress2, await maintainerRegistry.getMemberOwner(maintainerId2), "Unexpected maintainer owner");
        });

        it("The maintainer is registered and enabled", async function() {
            assert.isTrue(await maintainerRegistry.isMemberRegisteredAndEnabled(maintainerId2), "Expected maintainer to be registered and enabled");
        });    
    });    

    describe("manufacturer registers with manufacturer registry", function () {

        before(async function () {
            await manufacturerRegistry.registerMember(manufacturerId, {from: manufacturerRegistryOwner, value: manufacturerRegistryFee});
            manufacturerNumber = await manufacturerRegistry.getMemberNumber(manufacturerId);

            await manufacturerRegistry.transferMemberOwnership(manufacturerNumber, manufacturerAccount, transferKeyHash, {from: manufacturerRegistryOwner, value: manufacturerRegistryFee});
            await manufacturerRegistry.acceptMemberOwnership(manufacturerNumber, transferKey, {from: manufacturerAccount});
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
            await maintenanceLogStorage.bindToContract(maintenanceLog.address, {from: manufacturerAccount});
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

    describe("manufacturer transfers vin ownership to first customer", function () {
        before(async function () {
            await vehicleRegistry.transferMemberOwnership(vehicleNumber, firstOwnerAccount, transferKeyHash, {from: manufacturerAccount, value: manufacturerRegistryFee});
            await vehicleRegistry.acceptMemberOwnership(vehicleNumber, transferKey, {from: firstOwnerAccount});
        });

        it("vehicle is registered to first customer", async function() {
            assert.equal(firstOwnerAccount, await vehicleRegistry.getMemberOwner(vin));
        });

        it("maintenance log owner is still the manufacturer", async function() {
            assert.equal(manufacturerAccount, await maintenanceLog.owner.call());
        });        
    }); 
    
    describe("manfucturer transfers ownership of maintenance log", function () {
        before(async function () {
            await maintenanceLog.transferOwnership(firstOwnerAccount, {from: manufacturerAccount});
            await maintenanceLog.claimOwnership({from: firstOwnerAccount});
        });

        it("maintenance log owner is first customer", async function() {
            assert.equal(firstOwnerAccount, await maintenanceLog.owner.call());
        });        
    });     

    describe("first customer owner adds work authorisation to maintainer 2", function () { 
        before(async function () {
            await maintenanceLog.addWorkAuthorisation(maintainerId2, {from: firstOwnerAccount});
        }); 

        it("isAuthorised returns true", async function() {
            assert.isTrue(await maintenanceLog.isAuthorised(maintainerId2));
        });
    });        

    describe("maintainer2 adds log", function () { 

        before(async function () {
            jobId = web3.fromAscii("Service1");
            date = Math.round(new Date().getTime() / 1000);
            title = "First Service";
            description = "Oil change and vehicle inspection";
            docTitle = "Service 1 Report";
            ipfsAddress = web3.fromAscii("SomeAddres");

            await maintenanceLog.add(jobId, maintainerId2, date, title, description, {from: maintainerAddress2});
            logNumber = await maintenanceLog.getLogNumber(jobId);
            await maintenanceLog.addDoc(logNumber, docTitle, ipfsAddress, {from: maintainerAddress2});
            docNumber = 1;
        });

        it("The log can be returned", async function() {
            let log = await maintenanceLog.getLog(logNumber);
            assert.equal(parseInt(logNumber), parseInt(log[0]));
            assert.equal(web3.toUtf8(jobId), web3.toUtf8(log[1]));
            assert.equal(web3.toUtf8(maintainerId2), web3.toUtf8(log[2]));
            assert.equal(maintainerAddress2, log[3]);
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

    describe("first Owner verifies log", function () { 
        before(async function () {
            await maintenanceLog.verify(logNumber, {from: firstOwnerAccount});
        });

        it("the log is now verified", async function() {
            let log = await maintenanceLog.getLog(logNumber);
            assert.isTrue(log[7]);
        });
    });    
    
    describe("firstOwner transfers vin ownership to second", function () {
        before(async function () {

            await vehicleRegistry.transferMemberOwnership(vehicleNumber, secondOwnerAccount, transferKeyHash, {from: firstOwnerAccount, value: manufacturerRegistryFee});
            await vehicleRegistry.acceptMemberOwnership(vehicleNumber, transferKey, {from: secondOwnerAccount});
        });

        it("vehicle is registered to second customer", async function() {
            assert.equal(secondOwnerAccount, await vehicleRegistry.getMemberOwner(vin));
        });

        it("maintenance log owner is still the first owner", async function() {
            assert.equal(firstOwnerAccount, await maintenanceLog.owner.call());
        });        
    }); 
    
    describe("firstOwner transfers ownership of maintenance log", function () {
        before(async function () {
            await maintenanceLog.transferOwnership(secondOwnerAccount, {from: firstOwnerAccount});
            await maintenanceLog.claimOwnership({from: secondOwnerAccount});
        });

        it("maintenance log owner is second customer", async function() {
            assert.equal(secondOwnerAccount, await maintenanceLog.owner.call());
        });        
    });     
    
    describe("second customer owner adds work authorisation to maintainer 1", function () { 
        before(async function () {
            await maintenanceLog.addWorkAuthorisation(maintainerId1, {from: secondOwnerAccount});
        }); 

        it("isAuthorised returns true", async function() {
            assert.isTrue(await maintenanceLog.isAuthorised(maintainerId1));
        });
    });      

    describe("maintainer1 adds log", function () { 

        before(async function () {
            jobId = web3.fromAscii("Service2");
            date = Math.round(new Date().getTime() / 1000);
            title = "Second Service";
            description = "Major service and checkup";
            docTitle = "Service 2 Report";
            ipfsAddress = web3.fromAscii("SomeAddres");

            await maintenanceLog.add(jobId, maintainerId1, date, title, description, {from: maintainerAddress1});
            logNumber = await maintenanceLog.getLogNumber(jobId);
            await maintenanceLog.addDoc(logNumber, docTitle, ipfsAddress, {from: maintainerAddress1});
            docNumber = 1;
        });

        it("The log can be returned", async function() {
            let log = await maintenanceLog.getLog(logNumber);
            assert.equal(parseInt(logNumber), parseInt(log[0]));
        });

        it("The doc can be returned", async function() {
            let doc = await maintenanceLog.getDoc(logNumber, docNumber);
            assert.equal(1, doc[0], "unexpected doc number from getDoc");
        });              
    });

    describe("Querying the log history", async function() {
        let logs;
        before(async function () {
            let logCount = await maintenanceLog.getLogCount();
            logs = [];
            for(var i = 1; i <= (logCount); i ++) {
                logs.push(await maintenanceLog.getLog(i));
            }
        });

        it("there should be 3 logs", async function () {
            assert.equal(3, logs.length);
        });

        it("the last log shows as unverified because the second customer did not verify the log", async function() {
            assert.isFalse(logs[2][7]);
        });
    });    
     
});  
