//libs
var ByteUtilsLib = artifacts.require("ByteUtilsLib.sol");
var RegistryStorageLib = artifacts.require("RegistryStorageLib.sol");

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

  deployer.deploy(ByteUtilsLib);
  deployer.link(ByteUtilsLib, ManufacturerRegistry);
  //deployer.deploy(EternalStorage);
  deployer.deploy(RegistryStorageLib);
  deployer.link(RegistryStorageLib, Registry);
  deployer.link(RegistryStorageLib, ManufacturerRegistry);
  deployer.link(RegistryStorageLib, VehicleRegistry);
  /*
  deployer.deploy(VehicleManufacturerStorage).then(() => {
    deployer.link(VehicleManufacturerStorage, VehicleManufacturerRegistry);
    deployer.deploy(VehicleManufacturerRegistry, VehicleManufacturerStorage);
  });
  */
  
};
