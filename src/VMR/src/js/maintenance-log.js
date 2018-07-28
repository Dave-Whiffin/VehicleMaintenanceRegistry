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
  self.title = ko.observable("");
  self.ipfsAddress = ko.observable("");

  self.isIpfsValid = function() {
      return lengthInUtf8Bytes(self.ipfsAddress()) === 46;
  };

  self.isValid = function(errorCallBack) {
    if(self.title() == "" || self.isIpfsValid()) {
        errorCallBack("either title or ipfs address is invalid");
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
  self.currentLogEntry = {logNumber: 0};
  self.vin = ko.observable("")
  self.contractOwner = ko.observable("");
  self.logAddress = ko.observable("");
  
  self.init = function() {

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

    self.showInfo("submitting verification");
    console.log("calling verify for log entry: " + logEntry.logNumber);
    let tx = await self.maintenanceLogContract.verify(logEntry.logNumber);
    self.showInfo("verify tx received " + tx.txt);
    console.log("verify tx: " + tx.tx);
    
    await web3.eth.getTransactionReceipt(tx.tx, async function(err, result) {

      self.showInfo("verify transaction receipt received");

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

  self.addLogEntry = async function() {

    if(!self.newLogEntry.isValid(function(error) {
        self.showError(error);
      })) return;
    
    let id = web3.fromUtf8(self.newLogEntry.id());
    let maintainerId = web3.fromUtf8(self.newLogEntry.maintainerId());
    let title = self.newLogEntry.title();
    let description = self.newLogEntry.description();

    let isAuthorisedMaintainer = await self.maintenanceLogContract.isAuthorised(maintainerId);

    if(!isAuthorisedMaintainer){
      self.showError(maintainerId +  " is not an authorised maintainer");
      return;
    }

    try{
        await self.maintenanceLogContract.getLogNumber(id);
        self.showError("id already exists - it must be unique"); 
        return;
    }
    catch(Err) {
      //it's ok - this is normal
      //the contract throws when the id does not exist
    }

    let isRegisteredAndEnabled = await self.maintainerRegistry.isMemberRegisteredAndEnabled(maintainerId);
    if(!isRegisteredAndEnabled) {
      self.showError(maintainerId + " is not registered or not enabled in the maintainer regsistry");
      return;
    }

    let maintainerOwner = await self.maintainerRegistry.getMemberOwner(maintainerId);
    if(self.currentAccount != maintainerOwner) {
      self.showError("only the owner of the maintainer is allowed to log an entry");
      return;
    };

    let date = Math.round(new Date().getTime() / 1000);
    let tx = await self.maintenanceLogContract.add(id, maintainerId, date, title, description);
    
    let receipt = await web3.eth.getTransactionReceipt(tx.tx, async function(error, result) {

        if(error != null) {
          self.showError(error);
          return;
        }

        console.log("transaction finished. status: " + result.status);
        self.loadEntryById(id);
    });

  };

  self.loadEntryById = async function(id) {
    var logNumber = await self.maintenanceLogContract.getLogNumber(id);
    var logValues = await self.maintenanceLogContract.getLog(logNumber);
    var logEntry = new MaintenanceLogEntryModel(logValues);
    self.logEntries.push(logEntry);
  };

  self.validateAddDoc = async function(callBack) {
      
      if(self.currentLogEntry.verified()) {
        callBack("Denied - docs can not be added to verified log entries");
        return false;
      }
  
      let isMaintainerAuthorised = await self.maintenanceLogContract.isAuthorised(self.currentLogEntry.maintainerId());
      if(!isMaintainerAuthorised)
      {
        callBack("The maintainer is not (or no longer) authorised.");
        return false;
      }
  
      let maintainerOwner = await self.maintainerRegistry.getMemberOwner(self.currentLogEntry.maintainerId());
      
      if(self.currentAccount != maintainerOwner) {
        callBack("Denied - You are not the owner of the maintainer");
        return false;
      }
  
      callBack(null, log);
      return true;
  };

  self.addDoc = async function() {
    
    self.clearError();

    if(self.newDoc.isValid(function(error){
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
      txHash = await self.maintenanceLogContract.addDoc(self.currentLogEntry.logNumber(), self.newDoc.title(), self.newDoc.ipfsAddress());  
    }
    catch(error) {
      console.log(error);
      self.showError(error);
      return;
    }
  
    let log = self.currentLogEntry();

    self.newLogEntry.reset();

    await web3.eth.getTransactionReceipt(txHash.tx, async function(error, result) {
      if(error != null) {
        console.log(error);
      }
      else {
        console.log(result);
        self.loadDocs(log);
      }
    });

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