function VehicleModel(vehicleValArray) {
    var self = this;
    self.vehicleNumber = parseInt(vehicleValArray[0]);
    self.vin = web3.toUtf8(vehicleValArray[1]);
    self.owner = vehicleValArray[2];
    self.enabled = vehicleValArray[3];
    self.created = vehicleValArray[4];
    self.createdDate = new Date(parseInt(self.created) * 1000);
  }

function MaintainerViewModel(values) {
    var self = this;
    self.number = parseInt(values[0]);
    self.id =  web3.toUtf8(values[1]);
    self.authorised = values[2];
  }

function NewMaintainerModel() {
    var self = this;
    self.id = ko.observable("");
    self.enable = ko.observable(false);

    self.id.subscribe(function(newVal) {
      self.enable( newVal != "");
    });
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

function MaintenanceLogEntryModel(values) {
    var self = this;

    self.logNumber = parseInt(values[0]);
    self.id = web3.toUtf8(values[1]);
    self.maintainerId = web3.toUtf8(values[2]);
    self.maintainerAddress = values[3];
    self.date = parseInt(values[4]);
    self.properDate = new Date(parseInt(values[4]) * 1000);
    self.title = values[5];
    self.description = values[6];

    self.verified = ko.observable(values[7]);
    self.verifier = ko.observable(values[8]);
    self.verificationDate = ko.observable(values[9]);

    self.formattedVerificationDate = ko.computed(function() {
        return self.verificationDate() > 0 ? 
            new Date(parseInt(this.verificationDate()) * 1000).toString() : "";
    }, self);

    self.formattedVerifier = ko.computed(function() {
        return self.verifier() == 0 ? "" : self.verifier();
    }, self);

    self.docs = ko.observableArray([]);

    self.allowChanges = ko.observable(true);

    self.displayStatus = ko.observable("");

    self.merge = function(updatedLogValues) {
        let updatedLogEntry = new MaintenanceLogEntryModel(updatedLogValues);
        self.mergeFrom(updatedLogEntry);
    };

    self.mergeFrom = function(logEntry) {
        self.logNumber = logEntry.logNumber;
        self.id = logEntry.id;
        self.maintainerId = logEntry.maintainerId;
        self.maintainerAddress = logEntry.maintainerAddress;
        self.date = logEntry.date;
        self.properDate = logEntry.properDate;
        self.title = logEntry.title;
        self.verified(logEntry.verified());
        self.verifier(logEntry.verifier());
        self.verificationDate(logEntry.verificationDate());
    };
}

function MaintenanceLogDocModel(values) {
    var self = this;
    self.documentNumber = parseInt(values[0]);
    self.title = values[1];
    self.ipfsAddress = values[2];
}

function lengthInUtf8Bytes(str) {
    // Matches only the 10.. bytes that are non-initial characters in a multi-byte sequence.
    var m = encodeURIComponent(str).match(/%[89ABab]/g);
    return str.length + (m ? m.length : 0);
  }
  
  function NewLogEntryModel() {
    var self = this;
    self.id = ko.observable("");
    self.maintainerId = ko.observable("");
    self.title = ko.observable("");
    self.description = ko.observable("");
    self.enable = ko.observable(true);
  
    self.reset  = function() {
      self.id("");
      self.title("");
      self.description("");
    };
  
    self.isValid = function(errorCallback) {
      if(self.id() == "" || self.maintainerId() == "" || self.title() == "" || self.description() == "") {
        errorCallback("All fields must be completed");
        return false;
      }
  
      if(lengthInUtf8Bytes(self.id()) > 32){
        errorCallback("The id field is too long for a 32 byte value");
        return false;
      }

      if(self.title().length > 100) {
        errorCallback("Title must not exceeed 100 characters");
        return false;
      }

      if(self.description().length > 500) {
        errorCallback("Description must not exceeed 500 characters");
        return false;
      }      
  
      return true;
    };


  }
  
  function NewDocModel() {
    var self = this;
    self.logNumber  = ko.observable(0);
    self.title = ko.observable("");
    self.ipfsAddress = ko.observable("");
    self.enable = ko.observable(true);
    self.files = ko.observable("");
  
    self.reset = function() {
      self.title("");
      self.ipfsAddress("");
    };
  
    self.isIpfsValid = function() {
        return lengthInUtf8Bytes(self.ipfsAddress()) === 46;
    };
  
    self.isValid = function(errorCallBack) {
  
      if(self.logNumber() < 1) {
        errorCallBack("invalid log number");
        return false;
      }
  
      if(self.title() == "") {
          errorCallBack("document title can not be empty");
          return false;
      }
      if(!self.isIpfsValid()) {
        errorCallBack("not a valid ipfs address");
        return false;
    }    
      return true;
    }
  }