
import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var MockRegistryLookup = artifacts.require('MockRegistryLookup');

contract('MockRegistryLookup', function (accounts) {
    let mockRegistry;
    let validManufacturerId;
    let validManufacturerOwner;
    let invalidManufacturerId;

    beforeEach(async function () {

        validManufacturerId = web3.fromAscii("Valid");
        validManufacturerOwner = accounts[0];
        invalidManufacturerId = web3.fromAscii("InValid");

        mockRegistry = await MockRegistryLookup.new();
        mockRegistry.setMock(validManufacturerId, validManufacturerOwner, true);
        mockRegistry.setMock(invalidManufacturerId, 0, false);
      });

    it('getMemberOwner returns correct owner', async function () {
      assert.equal(validManufacturerOwner, await mockRegistry.getMemberOwner(validManufacturerId));
    });

    it('getMemberOwner throws for invalid manufacturer', async function () {
      await assertRevert(mockRegistry.getMemberOwner(invalidManufacturerId));
    });    

    it('isMemberRegisteredAndEnabled returns true for valid manufacturer', async function () {
      assert.isTrue(await mockRegistry.isMemberRegisteredAndEnabled(validManufacturerId));
    });
    
    it('isMemberRegisteredAndEnabled returns false for ivalid manufacturer', async function () {
      assert.isFalse(await mockRegistry.isMemberRegisteredAndEnabled(invalidManufacturerId));
    });  
  
});