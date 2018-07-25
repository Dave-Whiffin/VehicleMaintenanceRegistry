ContractFactory = {
  web3Provider: null,
  contracts: {},
  vehicleRegistryInstance: null,
  initialised: null,
  currentAddress: null,
  currentAddressChanged : function() {},

  init: function(handler) {
    ContractFactory.initialised = handler;
    return ContractFactory.initWeb3();
  },

  web3ConfigStoreUpdatedHandler: function(error, data) {
    let newAddress = data.selectedAddress;
    if(newAddress != ContractFactory.currentAddress){
      ContractFactory.currentAddress = newAddress;
      ContractFactory.currentAddressChanged(newAddress);
    }
  },

  beginPollingForAccountChange: function () {
    ContractFactory.currentAddress = web3.eth.accounts[0];
    var accountInterval = setInterval(function() {
      if (web3.eth.accounts[0] !== ContractFactory.currentAddress) {
        ContractFactory.currentAddress = web3.eth.accounts[0];
        ContractFactory.currentAddressChanged();
      }
    }, 100);
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

    ContractFactory.beginPollingForAccountChange();

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

      ContractFactory.initMaintainerRegistryContract();
    });
  },  
  
  initMaintainerRegistryContract: function() {
    $.getJSON('MaintainerRegistry.json', function(data) {
      var artifact = data;
      ContractFactory.contracts.MaintainerRegistry = TruffleContract(artifact);
      ContractFactory.contracts.MaintainerRegistry.setProvider(ContractFactory.web3Provider);

      ContractFactory.initialised();
    });
  },    

  getMaintenanceLogContract: function(contractAddress) {
      return ContractFactory.contracts.MaintenanceLog.at(contractAddress);
  },

  getMaintainerRegistryContract: function(contractAddress) {
    return ContractFactory.contracts.MaintainerRegistry.at(contractAddress);
  }

};

