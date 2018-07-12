var ByteUtilsLib = artifacts.require("ByteUtilsLib.sol");
var EternalStorage = artifacts.require("EternalStorage.sol");
var VehicleManufacturerRegistry = artifacts.require("VehicleManufacturerRegistry.sol");
var VehicleManufacturerStorage = artifacts.require("VehicleManufacturerStorage.sol");
var Registry = artifacts.require("Registry.sol");
var RegistryStorageLib = artifacts.require("RegistryStorageLib.sol");
var MockRegistryFeeChecker = artifacts.require("MockRegistryFeeChecker.sol");

module.exports = function(deployer) {

  deployer.deploy(ByteUtilsLib);
  deployer.link(ByteUtilsLib, VehicleManufacturerRegistry);
  deployer.deploy(EternalStorage);
  deployer.deploy(VehicleManufacturerStorage);
  deployer.link(VehicleManufacturerStorage, VehicleManufacturerRegistry);
  deployer.deploy(RegistryStorageLib);
  deployer.link(RegistryStorageLib, Registry);
  /*
  deployer.deploy(VehicleManufacturerStorage).then(() => {
    deployer.link(VehicleManufacturerStorage, VehicleManufacturerRegistry);
    deployer.deploy(VehicleManufacturerRegistry, VehicleManufacturerStorage);
  });
  */
  
};
