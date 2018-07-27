function VehicleModel(vehicleValArray) {
    var self = this;
    self.vehicleNumber = parseInt(vehicleValArray[0]);
    self.vin = web3.toUtf8(vehicleValArray[1]);
    self.owner = vehicleValArray[2];
    self.enabled = vehicleValArray[3];
    self.created = vehicleValArray[4];
    self.createdDate = new Date(parseInt(self.created) * 1000);
  }

function MaintainerViewModel() {
    var self = this;
    self.number =  0,
    self.id =  "",
    self.authorised = false
  }
  
function VehicleAttributeModel(values) {
    var self = this;

    function getDisplayValue(type, val) {
        return type === "address" ? val : web3.toUtf8(val);
    };

    self.number = parseInt(values[0]);
    self.name = web3.toUtf8(values[1]);
    self.type = web3.toUtf8(values[2]);
    self.value = values[3];
    self.displayValue = getDisplayValue(self.type, self.value);
  }  