ContractFactory = {
  web3Provider: null,
  contracts: {},
  vehicleRegistryInstance: null,
  manufacturerRegistryInstance: null,
  maintainerRegistryInstance: null,
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

    let completionCount = 0;

    var completionCallback = function() {
      completionCount ++;
      if(completionCount == 4)   {
        ContractFactory.initialised();
      }
    };

    ContractFactory.initManufacturerRegistryContract(completionCallback);
    ContractFactory.initMaintainerRegistryContract(completionCallback);
    ContractFactory.initVehicleRegistryContract(completionCallback);
    ContractFactory.initMaintenanceLogContract(completionCallback);
  },

  initManufacturerRegistryContract: function(completionCallBack) {
    $.getJSON('ManufacturerRegistry.json', function(artifact) {
      ContractFactory.contracts.ManufacturerRegistry = TruffleContract(artifact);
      ContractFactory.contracts.ManufacturerRegistry.setProvider(ContractFactory.web3Provider);
      ContractFactory.contracts.ManufacturerRegistry.deployed().then(function(instance)
      {
        ContractFactory.manufacturerRegistryInstance = instance;  
        completionCallBack();
      });
    });
  }, 

  initMaintainerRegistryContract: function(completionCallBack) {
    $.getJSON('MaintainerRegistry.json', function(artifact) {
      ContractFactory.contracts.MaintainerRegistry = TruffleContract(artifact);
      ContractFactory.contracts.MaintainerRegistry.setProvider(ContractFactory.web3Provider);
      ContractFactory.contracts.MaintainerRegistry.deployed().then(function(instance)
      {
        ContractFactory.maintainerRegistryInstance = instance;  
        completionCallBack();
      });
    });
  }, 

  initVehicleRegistryContract: function(completionCallBack) {
    $.getJSON('VehicleRegistry.json', function(artifact) {
      ContractFactory.contracts.VehicleRegistry = TruffleContract(artifact);
      ContractFactory.contracts.VehicleRegistry.setProvider(ContractFactory.web3Provider);
      ContractFactory.contracts.VehicleRegistry.deployed().then(function(instance)
      {
        ContractFactory.vehicleRegistryInstance = instance;  
        completionCallBack();
      });
    });
  }, 

  initMaintenanceLogContract: function(completionCallBack) {
    $.getJSON('MaintenanceLog.json', function(artifact) {
      ContractFactory.contracts.MaintenanceLog = TruffleContract(artifact);
      ContractFactory.contracts.MaintenanceLog.setProvider(ContractFactory.web3Provider);
      completionCallBack();
    });
  },  
  
  
  getMaintenanceLogContract: function(contractAddress) {
      return ContractFactory.contracts.MaintenanceLog.at(contractAddress);
  },

  getMaintainerRegistryContract: function() {
    return ContractFactory.maintainerRegistryInstance;
  },

  getManufacturerRegistryContract: function() {
    return ContractFactory.manufacturerRegistryInstance;
  }  
};

