App = {

  eventsBound : false,
  vehicleRegistry: null,

  init: function() {
    ContractFactory.init(function() {
      App.vehicleRegistry = ContractFactory.vehicleRegistryInstance;
      App.bindEvents();
      return App.loadVehicles();
    });
  },

  bindEvents: function() {
    if(!App.eventsBound) {
      $(document).on('click', '.btn-view-maintenance-log', App.viewMaintenanceLog);
      $(document).on('click', '.btn-view-vehicle-details', App.viewVehicleDetails);
      App.eventsBound = true;
    }
  },

  displayVehicle: function(vehicle) {

    let vehicleNumber = parseInt(vehicle[0]);
    let vin = web3.toUtf8(vehicle[1]);
    let owner = vehicle[2];

    App.vehicleRegistry.getMemberAttribute(vehicleNumber, 1)
    .then(function(attrib) {

      var vehicleRow = $('#vehicleRow');
      var vehicleTemplate = $('#vehicleTemplate');

      let manufacturer = web3.toUtf8(attrib[3]);
  
      vehicleTemplate.find('.panel-title').text(vehicleNumber);
      vehicleTemplate.find('.vehicle-vin').text(vin);
      vehicleTemplate.find('.vehicle-owner').text(owner);
      vehicleTemplate.find('.vehicle-manufacturer').text(manufacturer);
      vehicleTemplate.find('.btn-view-maintenance-log').attr('data-id', vehicleNumber);
      vehicleTemplate.find('.btn-view-maintenance-log').attr('data-vin', vin);
      vehicleTemplate.find('.btn-view-vehicle-details').attr('data-id', vehicleNumber);
      vehicleTemplate.find('.btn-view-vehicle-details').attr('data-vin', vin);      
  
      vehicleRow.append(vehicleTemplate.html());
      console.log("Member Number: " + vehicleNumber + " id: " + vin + " owner: " + owner);
    });
  },

  loadVehicles: async function() {
    let memberCount = await App.vehicleRegistry.getMemberTotalCount();
    for (i = 1; i <= memberCount; i++) {
      let vehicle = await App.vehicleRegistry.getMember(i);
      App.displayVehicle(vehicle);
    }
  },

  viewMaintenanceLog: async function(event) {
    event.preventDefault();
    var vehicleNumber = parseInt($(event.target).data('id'));
    let logAddress = await App.vehicleRegistry.getMaintenanceLogAddress(vehicleNumber);
    window.location.href = "maintenance-log.html?address=" + logAddress;
  },

  viewVehicleDetails: async function(event) {
    event.preventDefault();
    let vin = $(event.target).data('vin');
    window.location.href = "vehicle.html?vin=" + vin;
  }  
};

$(function() {
  $(window).load(function() {
    App.init();
    ContractFactory.currentAddressChanged = function() {
      App.init();
    };
  });
});
