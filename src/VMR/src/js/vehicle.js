
function getParameterByName(name, url) {
  if (!url) url = window.location.href;
  name = name.replace(/[\[\]]/g, '\\$&');
  var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
      results = regex.exec(url);
  if (!results) return null;
  if (!results[2]) return '';
  return decodeURIComponent(results[2].replace(/\+/g, ' '));
}

function VehicleViewModel() {
  var self = this;
  self.vehicle = ko.observable();
  self.vehicleRegistry = null;
  self.vehicleAttributes = ko.observableArray([]);

  self.init = async function() {
    ContractFactory.init(async function() {
      self.vehicleRegistry = ContractFactory.vehicleRegistryInstance;      
      let vin = getParameterByName("vin");
      let number = await self.vehicleRegistry.getMemberNumber(web3.fromUtf8(vin));
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
    ko.applyBindings(new VehicleViewModel());
  });
});