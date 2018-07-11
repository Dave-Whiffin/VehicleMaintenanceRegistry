var ByteUtils = artifacts.require("ByteUtils.sol");
var EternalStorage = artifacts.require("EternalStorage.sol");
var VehicleManufacturerRegistry = artifacts.require("VehicleManufacturerRegistry.sol");
var VehicleManufacturerStorage = artifacts.require("VehicleManufacturerStorage.sol");
var Registry = artifacts.require("Registry.sol");
var RegistryStorageLib = artifacts.require("RegistryStorageLib.sol");

module.exports = function(deployer) {

  deployer.deploy(ByteUtils);
  deployer.link(ByteUtils, VehicleManufacturerRegistry);
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
