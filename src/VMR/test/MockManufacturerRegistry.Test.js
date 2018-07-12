
import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var MockManufacturerRegistry = artifacts.require('MockManufacturerRegistry');

contract('MockManufacturerRegistry', function (accounts) {
    let mockRegistry;
    let validManufacturerId;
    let validManufacturerOwner;
    let invalidManufacturerId;

    beforeEach(async function () {

        validManufacturerId = web3.fromAscii("Valid");
        validManufacturerOwner = accounts[0];
        invalidManufacturerId = web3.fromAscii("InValid");

        mockRegistry = await MockManufacturerRegistry.new();
        mockRegistry.setMock(validManufacturerId, validManufacturerOwner, true);
        mockRegistry.setMock(invalidManufacturerId, 0, false);
      });

    it('getManufacturerOwner returns correct owner', async function () {
      assert.equal(validManufacturerOwner, await mockRegistry.getManufacturerOwner(validManufacturerId));
    });

    it('getManufacturerOwner throws for invalid manufacturer', async function () {
      await assertRevert(mockRegistry.getManufacturerOwner(invalidManufacturerId));
    });    

    it('isManufacturerRegisteredAndEnabled returns true for valid manufacturer', async function () {
      assert.isTrue(await mockRegistry.isManufacturerRegisteredAndEnabled(validManufacturerId));
    });
    
    it('isManufacturerRegisteredAndEnabled returns false for ivalid manufacturer', async function () {
      assert.isFalse(await mockRegistry.isManufacturerRegisteredAndEnabled(invalidManufacturerId));
    });  
  
});