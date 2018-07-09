var EternalStorage = artifacts.require("./EternalStorage.sol");

module.exports = function(deployer) {
  deployer.deploy(EternalStorage);
};
