var ByteUtilsLib = artifacts.require("ByteUtilsLib.sol");
var EternalStorage = artifacts.require("EternalStorage.sol");
var ManufacturerRegistry = artifacts.require("ManufacturerRegistry.sol");
var Registry = artifacts.require("Registry.sol");
var RegistryStorageLib = artifacts.require("RegistryStorageLib.sol");
var MockRegistryFeeChecker = artifacts.require("MockRegistryFeeChecker.sol");
var MockManufacturerRegistry = artifacts.require("MockManufacturerRegistry");

module.exports = function(deployer) {

  deployer.deploy(ByteUtilsLib);
  deployer.link(ByteUtilsLib, ManufacturerRegistry);
  //deployer.deploy(EternalStorage);
  deployer.deploy(RegistryStorageLib);
  deployer.link(RegistryStorageLib, Registry);
  deployer.link(RegistryStorageLib, ManufacturerRegistry);
  /*
  deployer.deploy(VehicleManufacturerStorage).then(() => {
    deployer.link(VehicleManufacturerStorage, VehicleManufacturerRegistry);
    deployer.deploy(VehicleManufacturerRegistry, VehicleManufacturerStorage);
  });
  */
  
};
