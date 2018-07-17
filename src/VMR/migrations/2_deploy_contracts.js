//libs
var ByteUtilsLib = artifacts.require("ByteUtilsLib.sol");
var RegistryStorageLib = artifacts.require("RegistryStorageLib.sol");
var VehicleMaintenanceLogStorage = artifacts.require("VehicleMaintenanceLogStorage.sol");

//contracts
var EternalStorage = artifacts.require("EternalStorage.sol");
var Registry = artifacts.require("Registry.sol");
var ManufacturerRegistry = artifacts.require("ManufacturerRegistry.sol");
var VehicleRegistry = artifacts.require("VehicleRegistry.sol");
var VehicleRegistry = artifacts.require("VehicleRegistry.sol");
var VehicleMaintenanceLog = artifacts.require("VehicleMaintenanceLog.sol");
var FeeChecker = artifacts.require("FeeChecker.sol");

//mocks
var MockRegistryLookup = artifacts.require("MockRegistryLookup");
var MockFeeChecker = artifacts.require("MockFeeChecker.sol");

module.exports = function(deployer) {
  deployer.deploy(ByteUtilsLib);
  deployer.link(ByteUtilsLib, ManufacturerRegistry);
  deployer.link(ByteUtilsLib, VehicleRegistry);
  deployer.link(ByteUtilsLib, VehicleMaintenanceLog);

  deployer.deploy(RegistryStorageLib);
  deployer.link(RegistryStorageLib, Registry);
  deployer.link(RegistryStorageLib, ManufacturerRegistry);
  deployer.link(RegistryStorageLib, VehicleRegistry);

  deployer.deploy(VehicleMaintenanceLogStorage);
  deployer.link(VehicleMaintenanceLogStorage, VehicleMaintenanceLog);
};
