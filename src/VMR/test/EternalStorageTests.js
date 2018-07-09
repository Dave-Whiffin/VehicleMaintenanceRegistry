
import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';
//const assertRevert = require("../node_modules/openzeppelin-solidity/test/helpers/assertRevert");

var EternalStorage = artifacts.require('EternalStorage');

contract('EternalStorage', function (accounts) {
  let eternalStorage;

  beforeEach(async function () {
    eternalStorage = await EternalStorage.new();
  });

  it('should have an owner', async function () {
    let owner = await claimable.owner();
    assert.isTrue(owner !== 0);
  });

  it('changes pendingOwner after transfer', async function () {
    let newOwner = accounts[1];
    await claimable.transferOwnership(newOwner);
    let pendingOwner = await claimable.pendingOwner();

    assert.isTrue(pendingOwner === newOwner);
  });

  it('should prevent to claimOwnership from no pendingOwner', async function () {
    await assertRevert(claimable.claimOwnership({ from: accounts[2] }));
  });

  it('should prevent non-owners from transfering', async function () {
    const other = accounts[2];
    const owner = await claimable.owner.call();

    assert.isTrue(owner !== other);
    await assertRevert(claimable.transferOwnership(other, { from: other }));
  });

  describe('after initiating a transfer', function () {
    let newOwner;

    beforeEach(async function () {
      newOwner = accounts[1];
      await claimable.transferOwnership(newOwner);
    });

    it('changes allow pending owner to claim ownership', async function () {
      await claimable.claimOwnership({ from: newOwner });
      let owner = await claimable.owner();

      assert.isTrue(owner === newOwner);
    });
  });
});