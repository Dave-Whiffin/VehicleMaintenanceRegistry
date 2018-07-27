
function getParameterByName(name, url) {
  if (!url) url = window.location.href;
  name = name.replace(/[\[\]]/g, '\\$&');
  var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
      results = regex.exec(url);
  if (!results) return null;
  if (!results[2]) return '';
  return decodeURIComponent(results[2].replace(/\+/g, ' '));
}

function lengthInUtf8Bytes(str) {
  // Matches only the 10.. bytes that are non-initial characters in a multi-byte sequence.
  var m = encodeURIComponent(str).match(/%[89ABab]/g);
  return str.length + (m ? m.length : 0);
}

function VehicleViewModel() {
  var self = this;
  self.vehicleNumber = 0,
  self.vin = "",
  self.owner = "",
  self.maintainers = [],
  self.attributes = []
}

function MaintainerViewModel() {
  var self = this;
  self.number =  0,
  self.id =  "",
  self.authorised = false
}

function AttributeViewModel() {
  var self = this;
  self.number = 0,
  self.id = "",
  self.type = "",
  self.value = ""
}

VehicleController = {

  eventsBound: false,
  logAddress: null,
  contract: null,
  maintainerRegistry: null,
  manufacturerRegistry: null,
  vehicleNumber: 0,
  vin: null,
  vehicleOwner: null,
  currentAccount: 0,
  currentUserIsVehicleOwner: false,

  init: function() {

    VehicleController.vin = getParameterByName("vin");

    console.log("vin: " + VehicleController.vin);

    ContractFactory.init(async function() {

      VehicleController.currentAccount = web3.eth.accounts[0];
      VehicleController.contract = ContractFactory.vehicleRegistryInstance;      
      VehicleController.maintainerRegistry = ContractFactory.getMaintainerRegistryContract();
      VehicleController.manufacturerRegistry = ContractFactory.getManufacturerRegistryContract();

      VehicleController.vehicleNumber = parseInt(await VehicleController.contract.getMemberNumber(web3.fromUtf8(VehicleController.vin)));

      let vehicleValues = await VehicleController.contract.getMember(VehicleController.vehicleNumber);

      VehicleController.vehicleOwner = vehicleValues[2];
      VehicleController.currentUserIsVehicleOwner = VehicleController.currentAccount == VehicleController.vehicleOwner;
      VehicleController.bindEvents();
      await VehicleController.bindToVehicle();
    });
  },
  
  bindEvents: function() {
    if(!VehicleController.eventsBound){
      $(document).on('click', '#btn-view-maintenance-log', VehicleController.viewMaintenanceLog);
      VehicleController.eventsBound = true;
    }
  },

  viewMaintenanceLog: async function(event) {
    event.preventDefault();
    var vehicleNumber = $(event.target).attr('data-id');
    let logAddress = await VehicleController.contract.getMaintenanceLogAddress(vehicleNumber);
    window.location.href = "maintenance-log.html?address=" + logAddress;
  },  

  wrapAttribute: function(attr) {
    return {
        number: attr[0],
        name: web3.toUtf8(attr[1]),
        type: web3.toUtf8(attr[2]),
        value: attr[3],
        getValue : function() {
          return this.type === "address" ? this.value : web3.toUtf8(this.value);
        }
    };
  },

  getWrappedAttribute: async function(attributeNumber) {
    var raw = await VehicleController.contract.getMemberAttribute(VehicleController.vehicleNumber, attributeNumber);
    return VehicleController.wrapAttribute(raw);
  },

  bindAttributeToPanel: function(attr, panel) {
    panel.attr("data-id", attr.number);
    panel.find(".vehicle-attribute-panel").attr("data-id", attr.number);
    panel.find('.panel-title').text(attr.number);
    panel.find('.attribute-number').text(attr.number);
    panel.find('.attribute-name').text(attr.name);
    panel.find('.attribute-type').text(attr.type);
    panel.find('.attribute-value').text(attr.getValue());
  },

  bindAttribute: function(attr) {
    var vehicleAttributeRow = $('#vehicleAttributeRow');
    var vehicleAttributeTemplate = $('#vehicleAttributeTemplate');

    VehicleController.bindAttributeToPanel(attr, vehicleAttributeTemplate);
    vehicleAttributeRow.append(vehicleAttributeTemplate.html());
  },

  bindToVehicle: async function() {

    $("#vehicleAttributeRow").empty();

    $("#btn-view-maintenance-log").attr("data-id", VehicleController.vehicleNumber);
    $(".vehicle-number").text(VehicleController.vehicleNumber);
    $(".vehicle-vin").text(VehicleController.vin);
    $(".vehicle-owner").text(VehicleController.vehicleOwner);

    var attributeCount = parseInt(await VehicleController.contract.getMemberAttributeTotalCount(VehicleController.vehicleNumber));

    for(var i = 1; i <= attributeCount; i++) {
      let attr = await VehicleController.getWrappedAttribute(i);
      VehicleController.bindAttribute(attr);
    }
  }
};

$(function() {
  $(window).load(function() {
    VehicleController.init();
    ContractFactory.currentAddressChanged = function() {
      VehicleController.init();
    };
  });
});
