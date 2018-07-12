import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var RegistryFeeChecker = artifacts.require('RegistryFeeChecker');

contract('RegistryFeeChecker', function (accounts) {
    let feeChecker;
    let initialFee;
    let refreshSeconds;
    let newOraclizeQueryEvent;
    let autoRefresh;
    
    beforeEach(async function () {
        autoRefresh = false;
        initialFee = 1;
        refreshSeconds = 10;
        feeChecker = await RegistryFeeChecker.new(refreshSeconds, initialFee, autoRefresh);
        newOraclizeQueryEvent = feeChecker.NewOraclizeQuery();
        //console.log("oraclizeUrlQueryPrice: " + await feeChecker.oraclizeUrlQueryPrice.call());
    });

    it("initial fee should be what was passed in the constructor", async function() {
        let fee = await feeChecker.getRegistrationFeeWei();
        assert.equal(initialFee, fee);
    });

    describe("updatePrices", function () {

        beforeEach(async function() {
            await feeChecker.updatePrices();
        });

        it("should log event", async function() {
            let events = await newOraclizeQueryEvent.get();

            var eventPresent = false;
    
            for(var i = 0 ; i < events.length; i++) {
                //console.log(events[i].args.description);
                if(events[i].args.description == "Oraclize query was sent - waiting for the answer"){
                    eventPresent = true;
                }
            } 

            assert.isTrue(eventPresent, "Expected to find event with description: 'Oraclize query was sent - waiting for the answer'");
        });

        it("should update the price", async function() {
    
            return new Promise(resolve => {
                setTimeout(async function() {

                    let regFee = await feeChecker.getRegistrationFeeWei();
                    assert.equal(10, regFee);
                    //console.log("fee: " + regFee);

                    resolve();
                }, 30000);
              })
        });          
    });  
});