App = {

  vehicleRegistry: null,

  init: function() {
    ContractFactory.init(function() {
      vehicleRegistry = ContractFactory.vehicleRegistryInstance;
      App.bindEvents();
      return App.loadVehicles();
    });
  },

  bindEvents: function() {
    $(document).on('click', '.btn-view-maintenance-log', App.viewMaintenanceLog);
  },

  displayVehicle: function(vehicle) {

    let vehicleNumber = parseInt(vehicle[0]);
    let vin = web3.toUtf8(vehicle[1]);
    let owner = vehicle[2];

    vehicleRegistry.getMemberAttribute(vehicleNumber, 1)
    .then(function(attrib) {

      var vehicleRow = $('#vehicleRow');
      var vehicleTemplate = $('#vehicleTemplate');

      let manufacturer = web3.toUtf8(attrib[3]);
  
      vehicleTemplate.find('.panel-title').text(vehicleNumber);
      vehicleTemplate.find('.vehicle-vin').text(vin);
      vehicleTemplate.find('.vehicle-owner').text(owner);
      vehicleTemplate.find('.vehicle-manufacturer').text(manufacturer);
      vehicleTemplate.find('.btn-view-maintenance-log').attr('data-id', vehicleNumber);
  
      vehicleRow.append(vehicleTemplate.html());
      console.log("Member Number: " + vehicleNumber + " id: " + vin + " owner: " + owner);
    });
  },

  loadVehicles: function() {
    vehicleRegistry.getMemberTotalCount()
    .then(function(memberCount) {
      for (i = 1; i <= memberCount; i++) {
        vehicleRegistry.getMember(i).then(function(m){
          App.displayVehicle(m);
        });
      }
    })
    .catch(function(err) {
      console.log(err.message);
    });
  },

  viewMaintenanceLog: function(event) {
    event.preventDefault();

    var vehicleNumber = parseInt($(event.target).data('id'));

    vehicleRegistry.getMaintenanceLogAddress(vehicleNumber)
    .then(function(logAddress){

      var maintenanceLogRow = $('#maintenanceLogRow');
      var maintenanceLogTemplate = $('#maintenanceLogTemplate');
      maintenanceLogTemplate.find('.panel-title').text(logAddress);
      maintenanceLogRow.html(maintenanceLogTemplate.html());

    })
    .catch(function(err){

    });

          /*
      if (adopters[i] !== '0x0000000000000000000000000000000000000000') {
        $('.panel-pet').eq(i).find('button').text('Success').attr('disabled', true);
        */

        /*
    var adoptionInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];

      App.contracts.Adoption.deployed().then(function(instance) {
        adoptionInstance = instance;

    // Execute adopt as a transaction by sending account
    return adoptionInstance.adopt(petId, {from: account});
    })
    .then(function(result) {
      return App.markAdopted();
    })
    .catch(function(err) {
      console.log(err.message);
    });
    */    
  }
};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
