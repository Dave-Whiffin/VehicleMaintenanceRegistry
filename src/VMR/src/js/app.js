function AppViewModel() {
  var self = this;

  VMRUtils.addStatusHandlers(self);
  self.test = "dave";
  self.vehicleRegistry = null;
  self.vehicles = ko.observableArray([]);  

  ContractFactory.currentAddressChanged = function() {
    self.init();
  };    

  self.init = function() {
    ContractFactory.init(function() {
      self.showInfo("Initialising..");
      self.vehicleRegistry = ContractFactory.vehicleRegistryInstance;
      self.vehicles([]);
      self.loadVehicles(() => { self.clearStatus()});
    });
  };

  self.goToDetails = async function(vehicle) {
    window.location.href = "vehicle.html?vin=" + vehicle.vin;
  };

  self.loadVehicles = async function(callback) {
    let memberCount = await self.vehicleRegistry.getMemberTotalCount();
    for (i = 1; i <= memberCount; i++) {
      let vehicleValArray = await self.vehicleRegistry.getMember(i);
      let vehicle = new VehicleModel(vehicleValArray);
      self.vehicles.push(vehicle);
    }
    callback();
  };  

  try{
    self.init();
  }
  catch(err) {
    self.showError(err);
  }
}

$(function() {
  $(window).load(function() {

    let viewModel = new AppViewModel();

    ko.components.register('vmr-status-bar', {
      viewModel: { instance: viewModel },
      template: VMRUtils.statusBarMarkup
    });

    ko.applyBindings(viewModel);
  });
});
