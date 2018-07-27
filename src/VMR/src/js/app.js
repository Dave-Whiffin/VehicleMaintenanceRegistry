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
      self.vehicles([]);
      self.loadVehicles();
    });
  };

  self.goToDetails = async function(vehicle) {
    window.location.href = "vehicle.html?vin=" + vehicle.vin;
  };

  self.loadVehicles = async function() {
    let memberCount = await self.vehicleRegistry.getMemberTotalCount();
    for (i = 1; i <= memberCount; i++) {
      let vehicleValArray = await self.vehicleRegistry.getMember(i);
      let vehicle = new VehicleModel(vehicleValArray);
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


