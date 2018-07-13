var MockFeeChecker = artifacts.require('MockFeeChecker');

contract('MockFeeChecker', function (accounts) {
    let feeChecker;
    let fee;

    before(async function () {
        fee = 10;
        feeChecker = await MockFeeChecker.new(fee);
      });

    describe("initially", function() {

      it('getFeeinWei should return what was passed to constructor', async function () {
        assert.equal(fee, await feeChecker.getFeeInWei());
      });

      describe("when fee is changed (setFeeInWei)", function() {

        before(async function() {
          await feeChecker.setFeeInWei(15);        
        });
  
        it('getFeeInWei returns new fee', async function () {
          assert.equal(15, await feeChecker.getFeeInWei());
        });   
  
      });   

    });
    
});