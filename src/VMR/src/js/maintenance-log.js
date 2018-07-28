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

    return true;
  };
}

function NewDocModel() {
  var self = this;
  self.logNumber  = ko.observable(0);
  self.title = ko.observable("");
  self.ipfsAddress = ko.observable("");

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

function MaintenanceLogViewModel() {
  var self = this;

  self.logEntries = ko.observableArray([]);
  self.maintainers = ko.observableArray([]);
  self.newLogEntry = new NewLogEntryModel();
  self.newDoc = new NewDocModel();
  self.errorText = ko.observable("");
  self.infoText = ko.observable("");
  self.successText = ko.observable("");
  self.vin = ko.observable("")
  self.contractOwner = ko.observable("");
  self.logAddress = ko.observable("");
  
  self.init = function() {

    self.clearStatus();
    self.showInfo("initialising");
    self.logAddress(getParameterByName("address"));
    console.log("maintenance log address: " + self.logAddress());

    ContractFactory.init(async function() {

      self.currentAccount = web3.eth.accounts[0];
      self.maintenanceLogContract = ContractFactory.getMaintenanceLogContract(self.logAddress());      
      self.maintainerRegistry = ContractFactory.getMaintainerRegistryContract();
      self.vin(web3.toUtf8(await self.maintenanceLogContract.vin.call()));
      self.contractOwner(await self.maintenanceLogContract.owner.call());
      self.isContractOwner = self.currentAccount == self.contractOwner();
      self.loadMaintainers();
      self.loadEntries();

      ContractFactory.currentAddressChanged = function() {
        self.showInfo("account changed - re-initialising");
        self.init();
      };
    });
  }  

  self.canVerify = function(logEntry) {
    return self.isContractOwner && !logEntry.verified();
  };

  self.loadEntries = async function() {
    self.showInfo("loading log entries");
    self.logEntries([]);

    var totalCount = await self.maintenanceLogContract.getLogCount();

    for(var i = 1; i <= totalCount; i++) {
      let logValues = await self.maintenanceLogContract.getLog(i);
      let logEntry = new MaintenanceLogEntryModel(logValues);
      self.logEntries.push(logEntry);
      self.loadDocs(logEntry);
    }
  };

  self.loadDocs = async function(logEntry) {
    self.showInfo("loading docs for log entry " + logEntry.logNumber);
    logEntry.docs([]);
    var docCount = await self.maintenanceLogContract.getDocCount(logEntry.logNumber);
    for(var i = 1; i <= docCount; i++) {
        var docValues = await self.maintenanceLogContract.getDoc(logEntry.logNumber, i);
        let doc = new MaintenanceLogDocModel(docValues);
        logEntry.docs.push(doc);
    }
  };

  self.loadMaintainers = async function() {
    self.showInfo("loading maintainers");
    self.maintainers([]);
    var totalCount = await self.maintenanceLogContract.getMaintainerCount();
    for(var i = 1; i <= totalCount; i++) {
      let maintainerValues = await self.maintenanceLogContract.getMaintainer(i);
      let maintainer = new MaintainerViewModel(maintainerValues);
      self.maintainers.push(maintainer);
    }
  };

  self.updateLogEntry = async function(logEntry) {
    self.showInfo("updating log entry with latest values");
    console.log("getting latest logEntry values");
    let updatedLogValues = await self.maintenanceLogContract.getLog(logEntry.logNumber);
    console.log("latest logEntry value array:" + updatedLogValues);
    console.log("merging latest values with existing log entry");
    logEntry.merge(updatedLogValues);
    console.log("merge complete");
    self.showInfo("update complete");
  };

  self.verify = async function(logEntry) {

    try{
      self.clearStatus();
      logEntry.allowChanges(false);
      self.showInfo("submitting verification");
      console.log("calling verify for log entry: " + logEntry.logNumber);
      let tx = await self.maintenanceLogContract.verify(logEntry.logNumber);
      self.showSuccess("verify tx received " + tx.txt);
      console.log("verify tx: " + tx.tx);
      
      await web3.eth.getTransactionReceipt(tx.tx, async function(err, result) {

        self.showSuccess("verify transaction receipt received");

        if(err != null) {
          self.showError(err);
          console.log(err);
          return;
        }

        console.log("setTimeout to get new values for logEntry");
        setTimeout(async function() {
          self.updateLogEntry(logEntry);
        }, 3000);

      });
    }
    catch(err) {
      self.showError(err);
    }
    finally {
      logEntry.allowChanges(true);
    }
  };

  self.showError = function(error) {
    console.log(error);
    self.errorText(error);
  };

  self.clearError = function() {
    self.errorText("");
  };

  self.showInfo = function(info) {
    console.log(info);
    self.infoText(info);

    setTimeout(function() {
      self.clearInfo();
    }, 3000);
  };

  self.clearInfo = function() {
    self.infoText("");
  };  

  self.showSuccess = function(msg) {
    self.successText(msg);
    setTimeout(() => self.successText(""), 3000);
  };

  self.clearSuccess = function() {
    self.successText("");
  };

  self.clearStatus = function() {
    self.clearSuccess();
    self.clearError();
    self.clearInfo();
  };

  self.addLogEntry = async function() {

    self.newLogEntry.enable(false);
    self.clearStatus();

    try {
      if(!self.newLogEntry.isValid(function(error) {
          self.showError(error);
        })) return;
      
      let id = web3.fromUtf8(self.newLogEntry.id());
      let maintainerId = web3.fromUtf8(self.newLogEntry.maintainerId());
      let title = self.newLogEntry.title();
      let description = self.newLogEntry.description();

      self.showInfo("Ensuring maintainer is authorised");
      let isAuthorisedMaintainer = await self.maintenanceLogContract.isAuthorised(maintainerId);

      if(!isAuthorisedMaintainer){
        self.showError(maintainerId +  " is not an authorised maintainer");
        return;
      }

      try{
          self.showInfo("Ensuring id is unique");
          await self.maintenanceLogContract.getLogNumber(id);
          self.showError("id already exists - it must be unique"); 
          return;
      }
      catch(Err) {
        //it's ok - this is normal
        //the contract throws when the id does not exist
      }

      self.showInfo("Ensuring maintainer is registered and enabled");
      let isRegisteredAndEnabled = await self.maintainerRegistry.isMemberRegisteredAndEnabled(maintainerId);
      if(!isRegisteredAndEnabled) {
        self.showError(maintainerId + " is not registered or not enabled in the maintainer regsistry");
        return;
      }

      self.showInfo("Ensuring current user is linked to the maintainer");
      let maintainerOwner = await self.maintainerRegistry.getMemberOwner(maintainerId);
      if(self.currentAccount != maintainerOwner) {
        self.showError("only the owner of the maintainer is allowed to log an entry");
        return;
      };

      let date = Math.round(new Date().getTime() / 1000);
      self.showInfo("Submitting Log Entry...");
      let tx = await self.maintenanceLogContract.add(id, maintainerId, date, title, description);
      self.showSuccess("Log entry submitted.  Waiting for receipt.");

      await web3.eth.getTransactionReceipt(tx.tx, async function(error, result) {

          if(error != null) {
            self.showError(error);
            return;
          }

          console.log("transaction finished. status: " + result.status);
          self.showSuccess("Transaction receipt received. Log entry added");
          self.loadEntryById(id);
          self.newLogEntry.reset();
      });
    }
    catch(err) {
      self.showError(err);
    }
    finally {
      self.newLogEntry.enable(true);
    }
  };

  self.loadEntryById = async function(id) {
    var logNumber = await self.maintenanceLogContract.getLogNumber(id);
    var logValues = await self.maintenanceLogContract.getLog(logNumber);
    var logEntry = new MaintenanceLogEntryModel(logValues);
    self.logEntries.push(logEntry);
  };

  self.getLogEntry = function(logNumber) {
    for(var i = 0; i < self.logEntries().length; i ++) {
      let entry = self.logEntries()[i];
      if(entry.logNumber == logNumber) {
        return entry;
      }
    }    
    return null;
  }

  self.validateAddDoc = async function(callBack) {
    
      let currentLogEntry = self.getLogEntry(self.newDoc.logNumber());

      if(currentLogEntry == null) {
        callBack("log number was not found");
        return false;        
      }

      if(currentLogEntry.verified()) {
        callBack("Denied - docs can not be added to verified log entries");
        return false;
      }
  
      let isMaintainerAuthorised = await self.maintenanceLogContract.isAuthorised(currentLogEntry.maintainerId);
      if(!isMaintainerAuthorised)
      {
        callBack("The maintainer is not (or no longer) authorised.");
        return false;
      }
  
      let maintainerOwner = await self.maintainerRegistry.getMemberOwner(currentLogEntry.maintainerId);
      
      if(self.currentAccount != maintainerOwner) {
        callBack("Denied - You are not the owner of the maintainer");
        return false;
      }
  
      return true;
  };

  self.addDoc = async function() {
    try {
      self.clearStatus();

      if(!self.newDoc.isValid(function(error){
        self.showError(error);
      })){
        return;
      }
        
      let validated = await self.validateAddDoc(function(error) {
          if(error != null) {
            console.log(error);
            self.showError(error);
          }
        });

      if(!validated) return;
        
      let txHash;
      try
      {
        self.showInfo("Submitting add document transaction...");
        txHash = await self.maintenanceLogContract.addDoc(self.newDoc.logNumber(), self.newDoc.title(), self.newDoc.ipfsAddress());  
        self.showSuccess("Add document submission success, waiting on receipt.");
      }
      catch(error) {
        console.log(error);
        self.showError(error);
        return;
      }
    
      let log = self.getLogEntry(self.newDoc.logNumber());

      self.newDoc.reset();

      await web3.eth.getTransactionReceipt(txHash.tx, async function(error, result) {
        self.showInfo("Transaction receipt received");
        if(error != null) {
          self.showError(error);
        }
        else {
          setTimeout(async function() {
            self.showInfo("reloading docs for log number: " + log.logNumber);
            self.loadDocs(log);
          }, 3000);
        }
      });
    }
    catch(err) {
      self.showError(err);
    }
    finally {
      
    }
  };    

  self.init();
};

$(function() {
  $(window).load(function() {
    ko.applyBindings(new MaintenanceLogViewModel());
  });
});


    //const ipfs = window.IpfsApi('ipfs.infura.io', '5001', {protocol: 'https'});

    //let a = ipfs.add("Qmcq1AVPSg2rP7JKV6SHKwTwWZAvhMZTYBAVX7sJJozdMV");
    
    /*
    ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin "[\"http://example.com\"]"
    ipfs config --json API.HTTPHeaders.Access-Control-Allow-Credentials "[\"true\"]"
    ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods "[\"PUT\", \"POST\", \"GET\"]"
    */