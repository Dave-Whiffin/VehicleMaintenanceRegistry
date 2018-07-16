//libs
var ByteUtilsLib = artifacts.require("ByteUtilsLib.sol");
var RegistryStorageLib = artifacts.require("RegistryStorageLib.sol");
var PGL1 = artifacts.require("PGL1");
var PGC1 = artifacts.require("PGC1");

//contracts
var EternalStorage = artifacts.require("EternalStorage.sol");
var Registry = artifacts.require("Registry.sol");
var ManufacturerRegistry = artifacts.require("ManufacturerRegistry.sol");
var VehicleRegistry = artifacts.require("VehicleRegistry.sol");
var FeeChecker = artifacts.require("FeeChecker.sol");

//mocks
var MockRegistryLookup = artifacts.require("MockRegistryLookup");
var MockFeeChecker = artifacts.require("MockFeeChecker.sol");

module.exports = function(deployer) {

  //playground/testing
  deployer.deploy(PGL1);
  deployer.link(PGL1, PGC1);

  deployer.deploy(ByteUtilsLib);
  deployer.link(ByteUtilsLib, ManufacturerRegistry);
  deployer.deploy(RegistryStorageLib);
  deployer.link(RegistryStorageLib, Registry);
  deployer.link(RegistryStorageLib, ManufacturerRegistry);
  deployer.link(RegistryStorageLib, VehicleRegistry);
  
};
