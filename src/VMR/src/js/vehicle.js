function VehicleViewModel() {
  var self = this;
  VMRUtils.addStatusHandlers(self);
  self.vehicle = ko.observable();
  self.vehicleRegistry = null;
  self.vehicleAttributes = ko.observableArray([]);

  self.init = async function() {
    ContractFactory.init(async function() {
      self.vehicleRegistry = ContractFactory.vehicleRegistryInstance;      
      let vin = VMRUtils.getParameterByName("vin");
      let number = parseInt(await self.vehicleRegistry.getMemberNumber(web3.fromUtf8(vin)));
      let vehicleValues = await self.vehicleRegistry.getMember(number);
      self.vehicle(new VehicleModel(vehicleValues));
      self.vehicleAttributes([]);
      self.loadAttributes(self.vehicle().vehicleNumber);
    });
  };

  self.loadAttributes = async function(vehicleNumber) {
    var attributeCount = parseInt(await self.vehicleRegistry.getMemberAttributeTotalCount(vehicleNumber));

    for(var i = 1; i <= attributeCount; i++) {
      let attributeValues = await self.vehicleRegistry.getMemberAttribute(vehicleNumber, i);
      let attribute = new VehicleAttributeModel(attributeValues);
      self.vehicleAttributes.push(attribute);
    }
  };

  self.goToMaintenanceLog = async function(vehicle) {
    let logAddress = await self.vehicleRegistry.getMaintenanceLogAddress(self.vehicle().vehicleNumber);
    window.location.href = "maintenance-log.html?address=" + logAddress;
  };  

  self.init();
}

$(function() {
  $(window).load(function() {

    let viewModel = new VehicleViewModel();

    ko.components.register('vmr-status-bar', {
      viewModel: { instance: viewModel },
      template: VMRUtils.statusBarMarkup
    });

    ko.applyBindings(viewModel);
  });
});