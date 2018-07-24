ContractFactory = {
  web3Provider: null,
  contracts: {},
  vehicleRegistryInstance: null,
  initialised: null,

  init: function(handler) {
    ContractFactory.initialised = handler;
    return ContractFactory.initWeb3();
  },

  initWeb3: function() {

      // Is there an injected web3 instance?
    if (typeof web3 !== 'undefined') {
      ContractFactory.web3Provider = web3.currentProvider;
    } else {
      // If no injected web3 instance is detected, fall back to Ganache
      ContractFactory.web3Provider = new Web3.providers.HttpProvider('http://localhost:8545');
    }
    web3 = new Web3(ContractFactory.web3Provider);
    return ContractFactory.initVehicleRegistryContract();
  },

  initVehicleRegistryContract: function() {
    $.getJSON('VehicleRegistry.json', function(data) {
      var vehicleRegistryArtifact = data;
      ContractFactory.contracts.VehicleRegistry = TruffleContract(vehicleRegistryArtifact);
      ContractFactory.contracts.VehicleRegistry.setProvider(ContractFactory.web3Provider);

      ContractFactory.contracts.VehicleRegistry.deployed().then(function(instance)
      {
        ContractFactory.vehicleRegistryInstance = instance;  
        ContractFactory.initMaintenanceLogContract();
      });
    });
  }, 

  initMaintenanceLogContract: function() {
    $.getJSON('MaintenanceLog.json', function(data) {
      var maintenanceLogArtifact = data;
      ContractFactory.contracts.MaintenanceLog = TruffleContract(maintenanceLogArtifact);
      ContractFactory.contracts.MaintenanceLog.setProvider(ContractFactory.web3Provider);

      ContractFactory.initialised();
    });
  },   

  getMaintenanceLogContract: function(contractAddress) {
      return ContractFactory.contracts.MaintenanceLog.at(contractAddress);
  }
};

