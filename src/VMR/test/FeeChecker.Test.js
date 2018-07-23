import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var FeeChecker = artifacts.require('FeeChecker');

contract('FeeChecker', function (accounts) {
    let feeChecker;
    let initialFee;
    let refreshSeconds;
    let newOraclizeQueryEvent;
    let feeChangedEvent;
    let autoRefresh;
    let oraclizeQueryUrl;
    let addressResolver;

    before(async function(){
        //the resolver address below is dependant on ganache being started with the mnemonic below
        //ganache-cli --mnemonic "baby marble measure police ball portion piece town topple guitar inspire enroll" --accounts 50
        addressResolver = 0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475;
        oraclizeQueryUrl = "json(https://www.dropbox.com/s/8hjew52p5b5p1tt/sample-fees.json?dl=1).prices.registration.wei";
        autoRefresh = false;
        initialFee = 1;
        refreshSeconds = 5;
        feeChecker = await FeeChecker.new(oraclizeQueryUrl, refreshSeconds, initialFee, autoRefresh, addressResolver);
        newOraclizeQueryEvent = feeChecker.NewOraclizeQuery();
        feeChangedEvent = feeChecker.FeeChanged();
    });
    
    it("initial fee should be what was passed in the constructor", async function() {
        let fee = await feeChecker.getFeeInWei();
        assert.equal(initialFee, fee);
    });

    it("only the owner or oraclize callback address can call updateFee", async function() {
        await assertRevert(feeChecker.updateFee({from: accounts[2]}));
    });    

    it("only the owner or oraclize callback address can call the __callback function", async function() {
        await assertRevert(feeChecker.__callback(web3.fromAscii("fake id"), "fake result", {from: accounts[1]}));
    });    
    
    describe("when paused", function() {

        before(async function() {
            await feeChecker.pause();
        });

        after(async function() {
            await feeChecker.unpause();
        })

        it("updateFees can not be called", async function() {
            await assertRevert(feeChecker.updateFee());
        }); 
        
        it("getFeeInWei can not be called", async function() {
            await assertRevert(feeChecker.getFeeInWei());
        });     

    });

    describe("updateFee", function () {

        //updating fees takes a while
        //ensure the ethereum bridge is running
        //ethereum-bridge --dev -H localhost:8545 -a 1

        before(async function() {
            await feeChecker.updateFee();
        });

        it("should emit OraclizeQueryEvent", async function() {
            let events = await newOraclizeQueryEvent.get();

            var eventPresent = false;
    
            for(var i = 0 ; i < events.length; i++) {
                if(events[i].args.description == "Oraclize query was sent - waiting for the answer"){
                    eventPresent = true;
                }
            } 

            assert.isTrue(eventPresent, "Expected OraclizeQueryEvent with description: 'Oraclize query was sent - waiting for the answer'");            
        })

        describe("within 30 seconds", function () {
            before(async function() {
                return new Promise(resolve => {
                    setTimeout(resolve, 30000);
                });
            })

            it("emits the NewFee event", async function() {
                let events = await feeChangedEvent.get();

                let eventPresent = false;

                for(var i = 0 ; i < events.length; i++) {
                    if(events[i].args.fee == 10){
                        eventPresent = true;
                    }
                } 
    
                assert.isTrue(eventPresent, "Expected to find fee changed event'");
            }); 
            
            it("update the fee", async function() {
                let regFee = await feeChecker.getFeeInWei();
                assert.equal(10, regFee, "Expected new fee to be 10");
            });             
        })
        
    });  
    
});