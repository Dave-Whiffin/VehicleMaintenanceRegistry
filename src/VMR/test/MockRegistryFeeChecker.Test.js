var MockRegistryFeeChecker = artifacts.require('MockRegistryFeeChecker');

contract('MockRegistryFeeChecker', function (accounts) {
    let feeChecker;
    let regFee;
    let transferFee;

    beforeEach(async function () {
        regFee = 10;
        transferFee = 5;
        feeChecker = await MockRegistryFeeChecker.new(regFee, transferFee);
      });

    it('registration fee should be 10', async function () {
      assert.equal(regFee, await feeChecker.getRegistrationFeeWei());
    });

    it('transfer fee should be 5', async function () {
      assert.equal(transferFee, await feeChecker.getTransferFeeWei());
    });

    it('registration fee should be changed', async function () {
      await feeChecker.setRegistrationFeeWei(15);
      assert.equal(15, await feeChecker.getRegistrationFeeWei());
    });       

    it('transfer fee should be changed', async function () {
      await feeChecker.setTransferFeeWei(20);
      assert.equal(20, await feeChecker.getTransferFeeWei());
    });    
});