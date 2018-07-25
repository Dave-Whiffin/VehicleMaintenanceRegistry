//libs
var ByteUtilsLib = artifacts.require("ByteUtilsLib");
var RegistryStorageLib = artifacts.require("RegistryStorageLib");
var MaintenanceLogStorageLib = artifacts.require("MaintenanceLogStorageLib");

//contracts
var VehicleRegistryStorage = artifacts.require("EternalStorage");
var ManufacturerRegistryStorage = artifacts.require("EternalStorage");
var MaintainerRegistryStorage = artifacts.require("EternalStorage");
var MaintenanceLogStorage = artifacts.require("EternalStorage");

var Registry = artifacts.require("Registry");
var ManufacturerRegistry = artifacts.require("ManufacturerRegistry");
var MaintainerRegistry = artifacts.require("MaintainerRegistry");
var VehicleRegistry = artifacts.require("VehicleRegistry");
var MaintenanceLog = artifacts.require("MaintenanceLog");
var FeeChecker = artifacts.require("FeeChecker.sol");

//mocks
var MockRegistryLookup = artifacts.require("MockRegistryLookup");
var MockFeeChecker = artifacts.require("MockFeeChecker");

module.exports = function(deployer, network, accounts) {


  deployer.deploy(ByteUtilsLib);
  deployer.link(ByteUtilsLib, ManufacturerRegistry);
  deployer.link(ByteUtilsLib, VehicleRegistry);
  deployer.link(ByteUtilsLib, MaintainerRegistry);
  deployer.link(ByteUtilsLib, MaintenanceLog);

  deployer.deploy(RegistryStorageLib);
  deployer.link(RegistryStorageLib, Registry);
  deployer.link(RegistryStorageLib, ManufacturerRegistry);
  deployer.link(RegistryStorageLib, VehicleRegistry);
  deployer.link(RegistryStorageLib, MaintainerRegistry);

  deployer.deploy(MaintenanceLogStorageLib);
  deployer.link(MaintenanceLogStorageLib, MaintenanceLog);

  if(network == "development")
  {
    let manufacturerRegistryOwner = accounts[5];
    let maintainerRegistryOwner = accounts[6];
    let vehicleRegistryOwner = accounts[7];
    let ford = accounts[8];
    let fordServiceCentre = accounts[9];
    let mockFee = 0;

    deployer.deploy(MockFeeChecker, mockFee);

    let vin = web3.fromAscii("11234567891234567");
    let transferKey = "Shhhhhhh";
    let transferKeyHash = web3.sha3(web3.toHex(transferKey), {encoding:"hex"});    

    var manufacturerStorage;
    var maintainerStorage;
    var vehicleStorage;
    var maintenanceLogStorage;

    var feeLookup;
    var maintainerRegistry;
    var manufacturerRegistry;
    var vehicleRegistry;
    var maintenanceLog;

    deployer.then(function(){
      return MockFeeChecker.new(mockFee);
    })
    .then(function(instance){
      feeLookup = instance;
      return ManufacturerRegistryStorage.new({from: manufacturerRegistryOwner});
    })
    .then(function(instance){
      manufacturerStorage = instance;
      return MaintainerRegistryStorage.new({from: maintainerRegistryOwner});
    })
    .then(function(instance){
      maintainerStorage = instance;
      return VehicleRegistryStorage.new({from: vehicleRegistryOwner});
    })
    .then(function(instance) {
      vehicleStorage = instance;
      return MaintainerRegistry.new(maintainerStorage.address, feeLookup.address, {from: maintainerRegistryOwner});
    })
    .then(function(instance){
      maintainerRegistry = instance;
      return ManufacturerRegistry.new(manufacturerStorage.address, feeLookup.address, {from: manufacturerRegistryOwner});
    })
    .then(function(instance){
      manufacturerRegistry = instance;
      //use deployer - we want our app to use the deployed address for the vehicle registry.
      //this is a workaround until ENS is implemented which will abstract the implementation of the contract from the name
      return deployer.deploy(VehicleRegistry, 
        vehicleStorage.address, feeLookup.address, manufacturerRegistry.address, {from: vehicleRegistryOwner});
    })
    .then(function(){
      return VehicleRegistry.deployed();
    })
    .then(function(instance){
      vehicleRegistry = instance;
      console.log("Vehicle Registry Address: " + vehicleRegistry.address);
      return manufacturerStorage.bindToContract(manufacturerRegistry.address, {from: manufacturerRegistryOwner});
    })
    .then(function(result) {
      return maintainerStorage.bindToContract(maintainerRegistry.address, {from: maintainerRegistryOwner});
    })
    .then(function(result) {
      return vehicleStorage.bindToContract(vehicleRegistry.address, {from: vehicleRegistryOwner});
    })
    .then(function(result){
      return manufacturerRegistry.registerMember("Ford", {from: manufacturerRegistryOwner});
    })
    .then(function(result){
      return maintainerRegistry.registerMember("Ford Service Centre", {from: maintainerRegistryOwner});
    })
    .then(function(result){
      return manufacturerRegistry.transferMemberOwnership(1, ford, transferKeyHash, {from: manufacturerRegistryOwner});
    })
    .then(function(result){
      return manufacturerRegistry.acceptMemberOwnership(1, transferKey, {from: ford});
    })
    .then(function(result){
      return maintainerRegistry.transferMemberOwnership(1, fordServiceCentre, transferKeyHash, {from: maintainerRegistryOwner});
    })
    .then(function(result){
      return maintainerRegistry.acceptMemberOwnership(1, transferKey, {from: fordServiceCentre});
    }) 
    .then(function(result){
      console.log("registering vin: " + vin + " length: " + vin.length);
      return vehicleRegistry.registerVehicle(vin, "Ford", {from: ford});
    })
    .then(function(result){
      console.log("deploying maintenance log storage");
      return MaintenanceLogStorage.new({from: ford});
    })
    .then(function(instance){
      maintenanceLogStorage = instance;
      console.log("deploying maintenance log for vin");
      return MaintenanceLog.new(maintenanceLogStorage.address, vehicleRegistry.address, maintainerRegistry.address, vin, {from: ford});
    })
    .then(function(instance){
      maintenanceLog = instance;
      return maintenanceLogStorage.bindToContract(maintenanceLog.address, {from: ford});
    })
    .then(function(result){
      return vehicleRegistry.setMaintenanceLogAddress(1, maintenanceLog.address, {from: ford});
    })
    .then(function(){
      console.log("Adding work authorisation to Ford Service Centre");
      return maintenanceLog.addWorkAuthorisation(web3.fromAscii("Ford Service Centre"), {from : ford});
    })
    .then(function() {
      console.log("Adding maintenance log entry");
      let date = Math.round(new Date().getTime() / 1000);
      return maintenanceLog.add(
       web3.fromAscii("FSC.Service1"), 
       web3.fromAscii("Ford Service Centre"), 
       date, 
       "Factory Exit Check", 
       "Checks to ensure vehicle is fit for sale", {from: fordServiceCentre});
    })
    .then(function() {
      console.log("Adding maintenance log doc");      
      return maintenanceLog.addDoc(1, "Service 1 Certificate PDF", "Qmeh4xZ3wT1HiPp5pWtby2CWVescFmzwFk9KCqJeT3F1yM", {from: fordServiceCentre});
    })
    .then(function() {
      console.log("Verifying log entry");
      return maintenanceLog.verify(1, {from: ford});
    })
    .then(function() {
      console.log("Adding maintenance log entry");
      let date = Math.round(new Date().getTime() / 1000);
      return maintenanceLog.add(
       web3.fromAscii("FSC.Service2"), 
       web3.fromAscii("Ford Service Centre"), 
       date, 
       "Delivery Check", 
       "Post Delivery Check List", {from: fordServiceCentre});
    })
    .then(function() {
      console.log("Adding maintenance log doc");
      return maintenanceLog.addDoc(2, "Service 2 Certificate PDF", "Qmcq1AVPSg2rP7JKV6SHKwTwWZAvhMZTYBAVX7sJJozdMV", {from: fordServiceCentre});
    });   
  }
};
