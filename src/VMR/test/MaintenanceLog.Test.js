import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var MaintenanceLog = artifacts.require('MaintenanceLog');
var EternalStorage = artifacts.require('EternalStorage');
var MockRegistryLookup = artifacts.require("MockRegistryLookup");

contract('MaintenanceLog', function (accounts) {

    let vin;
    let manufacturerAccount;
    let maintenanceLog;
    let eternalStorage;
    let mockVehicleRegistry;
    let mockMaintainerRegistry;
    let maintainerId1;
    let maintainerAddress1;
    let maintainerId2;
    let maintainerAddress2;    

    before(async function () {

        manufacturerAccount = accounts[0];
        maintainerId1 = web3.fromAscii("Quality Servicing LTD");
        maintainerAddress1 = accounts[3];
        maintainerId2 = web3.fromAscii("Barnes Vehicle Servicing");
        maintainerAddress2 = accounts[4];        
        vin = web3.fromAscii("01234567890123456");
        eternalStorage = await EternalStorage.new({from: manufacturerAccount});
        //ensure our vehicle appears to be registered to the manufacturer
        mockVehicleRegistry = await MockRegistryLookup.new();
        await mockVehicleRegistry.setMock(vin, manufacturerAccount, true);        

        mockMaintainerRegistry = await MockRegistryLookup.new();
        await mockMaintainerRegistry.setMock(maintainerId1, maintainerAddress1, true);
      });

    it("only the owner of the vehicle can create a log", async function() {
        await assertRevert(MaintenanceLog.new(eternalStorage.address, mockVehicleRegistry.address, mockMaintainerRegistry.address, vin, {from: accounts[1]}))
    });

    it("the vehicle registry address must be a contract", async function() {
        await assertRevert(MaintenanceLog.new(eternalStorage.address, accounts[1], mockMaintainerRegistry.address, vin, {from: manufacturerAccount}))
    });   
    
    it("the maintainer registry address must be a contract", async function() {
        await assertRevert(MaintenanceLog.new(eternalStorage.address, mockVehicleRegistry.address, accounts[1], vin, {from: manufacturerAccount}))
    });       

    it("the storage address must be a contract", async function() {
        await assertRevert(MaintenanceLog.new(accounts[1], mockVehicleRegistry.addres, mockMaintainerRegistry.address, vin, {from: manufacturerAccount}))
    });        

    it("the mockVehicleRegistry shows vin as registered to the manufacturer", async function() {
        assert.equal(manufacturerAccount, await mockVehicleRegistry.getMemberOwner(vin));
    });

    it("the mockVehicleRegistry shows vin as registered and enabled", async function() {
        assert.isTrue(await mockVehicleRegistry.isMemberRegisteredAndEnabled(vin));
    });

    it("the mockMaintainerRegistry shows maintainer1 as registered and enabled", async function() {
        assert.isTrue(await mockMaintainerRegistry.isMemberRegisteredAndEnabled(maintainerId1));
    });    

    describe("after deployment", function () {

        before(async function () {
            maintenanceLog = await MaintenanceLog.new(eternalStorage.address, mockVehicleRegistry.address, mockMaintainerRegistry.address, vin, {from: manufacturerAccount});
            await eternalStorage.bindToContract(maintenanceLog.address, {from: manufacturerAccount});
          });
    
        it("the initial owner of the log is the owner of the vehicle", async function() {
            assert.equal(manufacturerAccount, await maintenanceLog.owner.call());
        });

        it("the vin is stored correctly", async function() {
            assert.equal(web3.toUtf8(vin), web3.toUtf8(await maintenanceLog.vin.call()));
        });

        it("the vehicle registry address is correct", async function() {
            assert.equal(mockVehicleRegistry.address, await maintenanceLog.vehicleRegistryAddress.call());
        });

        it("the maintainer registry address is correct", async function() {
            assert.equal(mockMaintainerRegistry.address, await maintenanceLog.maintainerRegistryAddress.call());
        });        
        
        it("the vin is stored correctly", async function() {
            assert.equal(web3.toUtf8(vin), web3.toUtf8(await maintenanceLog.vin.call()));
        });

        describe("the ownership of the maintenance log can be transferred", function () {
            let firstCustomer;

            before(async function(){
                firstCustomer = accounts[4];
                //pretend there was a prior authorisation from the manufacturer
                //so we can test that it gets removed after ownership is claimed
                await maintenanceLog.addWorkAuthorisation(maintainerId1, {from: manufacturerAccount});
                //pretend the customer has got ownership of the vin in the registry
                await mockVehicleRegistry.setMock(vin, firstCustomer, true);
                await maintenanceLog.transferOwnership(firstCustomer, {from: manufacturerAccount});
                
            });

            after(async function(){
                //put ownership back to manufacturer
                await maintenanceLog.transferOwnership(manufacturerAccount, {from: firstCustomer});
                await mockVehicleRegistry.setMock(vin, manufacturerAccount, true);   
                await maintenanceLog.claimOwnership({from: manufacturerAccount}); 
            });

            it("the pending owner is set correctly", async function () {
                assert.equal(firstCustomer, await maintenanceLog.pendingOwner.call());
            });

            it("the pending owner can claim ownership and work authorisations are cleared", async function () {
                assert.isTrue(await maintenanceLog.isAuthorised(maintainerId1), "Expected work authorisation to be present until it ownership is claimed");
                assert.equal(firstCustomer, await maintenanceLog.pendingOwner.call());
                await maintenanceLog.claimOwnership({from: firstCustomer});                
                assert.equal(firstCustomer, await maintenanceLog.owner.call());
                assert.isFalse(await maintenanceLog.isAuthorised(maintainerId1), "All work authorisations should be cleared on claiming ownership");
            });
        });

        describe("when ownership is transferred to a non vin owner", function () {
            let firstCustomer;

            before(async function(){
                firstCustomer = accounts[4];
                //pretend the customer has got ownership of the vin in the registry
                await maintenanceLog.transferOwnership(firstCustomer, {from: manufacturerAccount});
            });

            after(async function(){
                //put ownership back to manufacturer
                await maintenanceLog.transferOwnership(manufacturerAccount, {from: manufacturerAccount});  
            });

            it("the pending owner can not claim ownership", async function () {
                await assertRevert(maintenanceLog.claimOwnership({from: firstCustomer}));                
            });
        });    

        describe("a maintainer can be authorised to log work on the vehicle", function() {

            before(async function() {
                await maintenanceLog.addWorkAuthorisation(maintainerId1);
            });

            it("the count of maintainers rises", async function() {
                assert.equal(1, await maintenanceLog.getMaintainerCount());
            });

            it("the maintainer can be returned by maintainer number", async function() {
                let maintainer = await maintenanceLog.getMaintainer(1);
                assert.equal(1, maintainer[0]);
                assert.equal(web3.toUtf8(maintainerId1), web3.toUtf8(maintainer[1]));
                assert.isTrue(maintainer[2]);
            });            

            it("shows authorised maintainer as authorised", async function() {
                assert.isTrue(await maintenanceLog.isAuthorised(maintainerId1));
            });

            it("shows not authorised maintainer as unauthorised", async function() {
                let rogue = web3.fromAscii("rogue");
                assert.isFalse(await maintenanceLog.isAuthorised(rogue));
            });

            describe("the maintainer can be unauthorised", function() {
                before(async function() {
                    await maintenanceLog.removeWorkAuthorisation(maintainerId1);
                });

                after(async function() {
                    await maintenanceLog.addWorkAuthorisation(maintainerId1);
                });                

                it("shows as unauthorised", async function() {
                    assert.isFalse(await maintenanceLog.isAuthorised(maintainerId1));
                });
                
                it("the count of maintainers stays the same", async function() {
                    assert.equal(1, await maintenanceLog.getMaintainerCount());
                });
    
                it("getMaintainer shows they are unauthorised", async function() {
                    let maintainer = await maintenanceLog.getMaintainer(1);
                    assert.isFalse(maintainer[2]);
                });                  
            });            

            describe("When work is logged against vehicle by maintainer", async function() {
                let logNumber;
                let jobId;
                let date;
                let title;
                let description;
                let logAddedEventWatcher;
                let logAddedEvents;
                let rogueMaintainerAddress;

                before(async function() {
                    rogueMaintainerAddress = accounts[5];
                    jobId = web3.fromAscii("job1");
                    date  = Math.round(new Date().getTime() / 1000);
                    title = "Post factory check";
                    description = "QA Verification following manufacture";
                    logAddedEventWatcher = maintenanceLog.LogAdded();
                    await maintenanceLog.add(jobId, maintainerId1, date, title, description, {from: maintainerAddress1});
                    logAddedEvents = await logAddedEventWatcher.get();
                    logNumber = await maintenanceLog.getLogNumber(jobId);
                });

                it("returns sequential log number starting at 1", async function() {
                    assert.equal(1, parseInt(logNumber), "unexpected log number - expected 1 as it is the first log to be added");
                });

                it("totalLogCount returns 1", async function() {
                    assert.equal(1, parseInt(await maintenanceLog.getLogCount()));
                });   
                
                it("getLog returns correct details", async function() {
                    let log = await maintenanceLog.getLog(logNumber);
                    assert.equal(parseInt(logNumber), parseInt(log[0]));
                    assert.equal(web3.toUtf8(jobId), web3.toUtf8(log[1]));
                    assert.equal(web3.toUtf8(maintainerId1), web3.toUtf8(log[2]));
                    assert.equal(maintainerAddress1, log[3]);
                    assert.equal(parseInt(date), parseInt(log[4]));
                    assert.equal(title, log[5]);
                    assert.equal(description, log[6]);
                    assert.isFalse(log[7], "log should not be verified"); 
                    assert.equal(0, log[8], "verifier should be 0"); 
                    assert.equal(0, log[9], "verificationDate should be 0"); 
                });                   

                it("emits LogAdded event with logNumber and maintainer", async function() {
                    assert.equal(1, logAddedEvents.length);
                    assert.equal(1, logAddedEvents[0].args.logNumber);
                    assert.equal(web3.toUtf8(maintainerId1), web3.toUtf8(logAddedEvents[0].args.maintainerId));
                });

                it("unauthorised mechanics can not log work", async function() {
                    await assertRevert(maintenanceLog.add(jobId, maintainerId1, date, title, description, {from: rogueMaintainerAddress}));
                });                

                describe("Docs can be added to the log", function() {
                    let ipfsAddress;
                    let docTitle;

                    before(async function() {
                        docTitle = "Post Factory Check Certificate (PDF)";
                        ipfsAddress = web3.fromAscii("SomeAddress");
                        await maintenanceLog.addDoc(logNumber, docTitle, ipfsAddress, {from: maintainerAddress1});
                    });

                    it("unauthorised mechanics can not add docs", async function() {
                        await assertRevert(maintenanceLog.addDoc(logNumber, docTitle, ipfsAddress, {from: rogueMaintainerAddress}));
                    });

                    it("increments the doc count", async function () {
                        assert.equal(1, parseInt(await maintenanceLog.getDocCount(logNumber)));
                    });

                    it("returns the correct doc details", async function() {
                        let doc = await maintenanceLog.getDoc(logNumber, 1);
                        assert.equal(1, doc[0], "unexpected docNumber");
                        assert.equal(docTitle, doc[1], "unexpected doc title");
                        assert.equal(web3.toUtf8(ipfsAddress), web3.toUtf8(doc[2]), "unexpected ipfs address");
                    });

                    describe("the work can be verified by the owner of the vin", function() {
                        before(async function() {
                            await maintenanceLog.verify(logNumber, {from: manufacturerAccount});
                        });
    
                        it("the log shows as verified", async function() {
                            let log = await maintenanceLog.getLog(logNumber);
                            assert.isTrue(log[7], "log should be verified"); 
                            assert.equal(manufacturerAccount, log[8], "verifier should be manufacturer"); 
                            assert.isTrue(log[9] > 0, "verificationDate should be greater than 0");                             
                        });
    
                        it("can not add doc to verified log", async function() {
                            await assertRevert(maintenanceLog.addDoc(logNumber, docTitle, ipfsAddress, {from: maintainerAddress1}));
                        });
                    });        

                    describe("When maintainer is disabled in maintainer registry", function() {
                        before(async function() {
                            await mockMaintainerRegistry.setMock(maintainerId1, maintainerAddress1, false);
                        });
                        after(async function() {
                            await mockMaintainerRegistry.setMock(maintainerId1, maintainerAddress1, true);
                        });                     
                        it("they can not add to log", async function() {
                            let failingJobId = web3.fromAscii("ThisShouldFail1");
                            await assertRevert(maintenanceLog.add(failingJobId, maintainerId1, date, title, description, {from: maintainerAddress1}));
                        });
                    });

                    describe("When maintainer owner in the maintainer registry is not the message sender", function() {
                        before(async function() {
                            //deliberately mix up the owner of the maintainer
                            await mockMaintainerRegistry.setMock(maintainerId1, maintainerAddress2, true);
                        });
                        after(async function() {
                            await mockMaintainerRegistry.setMock(maintainerId1, maintainerAddress1, true);
                        });                     
                        it("they can not add to maintenance log", async function() {
                            let failingJobId = web3.fromAscii("ThisShouldFail1");
                            await assertRevert(maintenanceLog.add(failingJobId, maintainerId1, date, title, description, {from: maintainerAddress1}));
                        });
                    });                    
                    
                    describe("Another maintainer can be authorised to log work", function() {
                                                
                        before(async function() {
                            mockMaintainerRegistry.setMock(maintainerId2, maintainerAddress2, true);
                            jobId = web3.fromAscii("job2");
                            await maintenanceLog.addWorkAuthorisation(maintainerId2, {from: manufacturerAccount});
                        })

                        describe("who can also add work to the log", function () {
                            before(async function(){

                                jobId = web3.fromAscii("job2");
                                date  = Math.round(new Date().getTime() / 1000);
                                title = "Pre Customer Delivery Check";
                                description = "Full customer pre delivery check - level 1";
                                await maintenanceLog.add(jobId, maintainerId2, date, title, description, {from: maintainerAddress2});
                            });

                            it("increments log count", async function() {
                                assert.equal(2, parseInt(await maintenanceLog.getLogCount()));
                            });

                            it("getLog returns the job correctly", async function() {
                                let log = await maintenanceLog.getLog(2);
                                assert.equal(web3.toUtf8(jobId), web3.toUtf8(log[1]));
                            });                            
                        });
                    });

                    describe("When contract is paused", function() {
    
                        before(async function() {
                            await maintenanceLog.pause();
                        });
                
                        after(async function() {
                            await maintenanceLog.unpause();
                        });
            
                        it("can not add to log", async function() {
                            await assertRevert(maintenanceLog.add(jobId, maintainerId1, date, title, description, {from: maintainerAddress1}));
                        });            
            
                        it("can not authorise maintainer", async function() {
                            await assertRevert(maintenanceLog.addWorkAuthorisation(maintainerId1));
                        });                        
            
                        it("can not remove maintainer", async function() {
                            await assertRevert(maintenanceLog.addWorkAuthorisation(maintainerId1));
                        });    
                        
                        it("can not verify log", async function() {
                            await assertRevert(maintenanceLog.verify(logNumber));
                        });                
                    });                     
                });
            });
        });
    

    });

    
});