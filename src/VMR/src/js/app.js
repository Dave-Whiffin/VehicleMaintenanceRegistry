function VehicleStub(vehicleValArray) {
  var self = this;
  self.vehicleNumber = parseInt(vehicleValArray[0]);
  self.vin = web3.toUtf8(vehicleValArray[1]);
  self.owner = vehicleValArray[2];
  self.enabled = vehicleValArray[3];
  self.created = vehicleValArray[4];
  self.createdDate = new Date(parseInt(self.created) * 1000);
}

function AppViewModel() {
  var self = this;

  self.test = "dave";
  self.vehicleRegistry = null;

  self.vehicles = ko.observableArray([]);  

  ContractFactory.currentAddressChanged = function() {
    self.init();
  };    

  self.init = function() {
    ContractFactory.init(function() {
      self.vehicleRegistry = ContractFactory.vehicleRegistryInstance;
      self.loadVehicles();
    });
  };

  self.goToMaintenanceLog = async function(vehicle) {
    let logAddress = await self.vehicleRegistry.getMaintenanceLogAddress(vehicle.vehicleNumber);
    window.location.href = "maintenance-log.html?address=" + logAddress;
  };

  self.goToDetails = async function(vehicle) {
    window.location.href = "vehicle.html?vin=" + vehicle.vin;
  };

  self.loadVehicles = async function() {
    let memberCount = await self.vehicleRegistry.getMemberTotalCount();
    for (i = 1; i <= memberCount; i++) {
      let vehicleValArray = await self.vehicleRegistry.getMember(i);
      let vehicle = new VehicleStub(vehicleValArray);
      self.vehicles.push(vehicle);
    }
  };  

  self.init();
}

$(function() {
  $(window).load(function() {
    ko.applyBindings(new AppViewModel());
  });
});


