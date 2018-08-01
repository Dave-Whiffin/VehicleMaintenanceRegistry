//const ipfs = window.IpfsApi('127.0.0.1', '5001');
const ipfs = window.IpfsApi({host: 'ipfs.infura.io', port: '5001', protocol: 'https'});

function MaintenanceLogViewModel() {
  var self = this;

  VMRUtils.addStatusHandlers(self);

  self.logEntries = ko.observableArray([]);
  self.logEntriesAllowingNewDocs = ko.observableArray([]);
  self.maintainers = ko.observableArray([]);
  self.authorisedMaintainers = ko.observableArray([]);
  self.newLogEntry = new NewLogEntryModel();
  self.newDoc = new NewDocModel();
  self.newMaintainer = new NewMaintainerModel();
  self.vin = ko.observable("");
  self.contractOwner = ko.observable("");
  self.logAddress = ko.observable("");
  self.canAddLogEntries = ko.observable(false);
  self.isContractOwner = ko.observable(false);
  self.eventWatchers = [];
  self.initialised = false;
  self.eventTxHashes = [];

  self.eventHasBeenHandled = function(result) {
    let id = result.transactionHash + result.event;
    let existing = self.eventTxHashes.find((t) => {return t == id;});
    return existing != null;
  };

  self.saveHandledEvent = function(result) {
    let id = result.transactionHash + result.event;
    self.eventTxHashes.push(id);
  };

  self.respondToEvent = function(result) {
    if(self.eventHasBeenHandled(result)){
      return false;
    }
    self.saveHandledEvent(result);
    return true;
  }

  self.setEntriesAllowingDocs = function() {
    self.logEntriesAllowingNewDocs([]);

    self.logEntries().forEach((e) => {
      if(!e.verified()) {
        let maintainer = self.authorisedMaintainers().find((m) => {return m.id == e.maintainerId;});
        if(maintainer != null) {
          self.logEntriesAllowingNewDocs.push(e);
        }
    }
    });
  };

  self.logEntries.subscribe(function(changes) {
    self.setEntriesAllowingDocs();
  });

  self.authorisedMaintainers.subscribe(function(changes) {
    self.setEntriesAllowingDocs();
  });

  self.getVinHref = function() {
    return "vehicle.html?vin=" + self.vin();
  };

  self.init = function() {

    self.initialised = false;
    self.clearStatus();
    self.showInfo("initialising");
    self.logAddress(VMRUtils.getParameterByName("address"));
    console.log("maintenance log address: " + self.logAddress());

    ContractFactory.init(async function() {
      self.currentAccount = web3.eth.accounts[0];
      self.maintenanceLogContract = ContractFactory.getMaintenanceLogContract(self.logAddress());      
      self.subscribeToEvents(self.maintenanceLogContract);

      self.maintainerRegistry = ContractFactory.getMaintainerRegistryContract();
      self.vin(web3.toUtf8(await self.maintenanceLogContract.vin.call()));
      self.contractOwner(await self.maintenanceLogContract.owner.call());
      self.isContractOwner(self.currentAccount == self.contractOwner());
      await self.loadMaintainers();
      await self.loadEntries();

      ContractFactory.currentAddressChanged = function() {
        self.showInfo("account changed - re-initialising");
        self.init();
      };

      self.initialised = true;
    });
  };

  self.subscribeToEvents = function(maintenanceLogContract) {

    var eventWatchers = self.eventWatchers;

    eventWatchers.forEach(e => e.stopWatching());
    eventWatchers = [];

    let workAuthorisationAdded = maintenanceLogContract.WorkAuthorisationAdded();
    let workAuthorisationRemoved = maintenanceLogContract.WorkAuthorisationRemoved();
    let logAdded = maintenanceLogContract.LogAdded();
    let docAdded = maintenanceLogContract.DocAdded();
    let logVerified = maintenanceLogContract.LogVerified();

    eventWatchers.push(workAuthorisationAdded);
    eventWatchers.push(workAuthorisationRemoved);
    eventWatchers.push(logAdded);
    eventWatchers.push(docAdded);
    eventWatchers.push(logVerified);

    workAuthorisationAdded.watch(async (error, result) => {
        if(error != null) {
          self.showError(error);
          return;
        }

        if(!self.respondToEvent(result)){
          return;
        }

        let maintainerId = web3.toUtf8(result.args.maintainerId);
        self.showInfo("Event: Work Auth Added.  maintainer Id: " + maintainerId);

        if(self.initialised){
          await self.loadMaintainers();
        }

    });

    workAuthorisationRemoved.watch(async (error, result) => {
      //maintainerId
      if(error != null) {
        self.showError(error);
        return;
      }
      
      if(!self.respondToEvent(result)){
        return;
      }
      
      self.showInfo("Event: Work Auth Removed.  maintainer Id: " + web3.toUtf8(result.args.maintainerId));
      if(self.initialised) {
        await self.loadMaintainers();
      }
    });

    logAdded.watch((error, result) => {
      if(error != null) {
        self.showError(error);
        return;
      }

      if(!self.respondToEvent(result)){
        return;
      }

      let logNumber = parseInt(result.args.logNumber);
      self.showInfo("Event: Log Entry Added. Log Number: " + logNumber + "  maintainer Id: " + web3.toUtf8(result.args.maintainerId));
      if(self.initialised) {
        self.loadEntryByLogNumber(logNumber);
      }
    });

    docAdded.watch((error, result) => {
      if(error != null) {
        self.showError(error);
        return;
      }

      if(!self.respondToEvent(result)){
        return;
      }

      let logNumber = parseInt(result.args.logNumber);
      self.showInfo("Event: Log Entry Added. Log Number: " + logNumber + "  doc Number: " + parseInt(result.args.docNumber));
      let log = self.getLogEntry(logNumber);
      if(log != null && self.initialised) {
        self.loadDocs(log);
      }
    });

    logVerified.watch((error, result) => {
      if(error != null) {
        self.showError(error);
        return;
      }

      if(!self.respondToEvent(result)){
        return;
      }

      let logNumber = parseInt(result.args.logNumber);

      self.showInfo("Event: Log Verified. Log Number: " + parseInt(logNumber));

      let logEntry = self.logEntries().find((e) => { return e.logNumber == logNumber;});
      if(logEntry != null) {
        self.updateLogEntry(logEntry);
      }
    });

  };

  self.getExistingMaintainer = function(maintainerId) {
    return self.maintainers().find((m) => {return m.id == maintainerId;});
  };

  self.canVerify = function(logEntry) {
    return self.isContractOwner() && !logEntry.verified();
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

  self.loadMaintainer = async function(maintainerNumber) {

    let maintainerValues = await self.maintenanceLogContract.getMaintainer(maintainerNumber);
    let maintainer = new MaintainerViewModel(maintainerValues);
    self.maintainers.push(maintainer);

    if(maintainer.authorised) {
      var owner = await self.maintainerRegistry.getMemberOwner(maintainer.id);
      if(owner == self.currentAccount) {
        self.authorisedMaintainers.push(maintainer);
        self.canAddLogEntries(true);
      } 
    }
  };

  self.loadMaintainers = async function() {
    self.showInfo("loading maintainers");
    self.maintainers([]);
    self.authorisedMaintainers([]);
    self.canAddLogEntries(false);

    var totalCount = await self.maintenanceLogContract.getMaintainerCount();
    for(var i = 1; i <= totalCount; i++) {
      await self.loadMaintainer(i);
    }
  };

  self.authoriseMaintainer = async function(maintainer) {
    try {
      self.clearStatus();
      self.showInfo("Sending authorisation request...");
      let tx = await self.maintenanceLogContract.addWorkAuthorisation(maintainer.id);
      self.showSuccess("Authorisation request accepted");

      await web3.eth.getTransactionReceipt(tx.tx, async function(error, result){
        if(error != null) {
          self.showError(error);
          return;
        }

        if(result.status != "0x01") {
          self.showError("error occurred - unexpected status - " + result.status);
          return;
        }        
      });
    }
    catch(err) {
      self.showError(err);
    }
    finally {

    }
  };

  self.unAuthoriseMaintainer = async function(maintainer) {
    try {
      self.clearStatus();
      self.showInfo("Sending remove authorisation request...");
      let tx = await self.maintenanceLogContract.removeWorkAuthorisation(maintainer.id);
      self.showSuccess("Remove authorisation request accepted");
      await web3.eth.getTransactionReceipt(tx.tx, async function(error, result){
        if(error != null) {
          self.showError(error);
          return;
        }

        if(result.status != "0x01") {
          self.showError("error occurred - unexpected status - " + result.status);
          return;
        }
      });
    }
    catch(err) {
      self.showError(err);
    }
    finally {

    }
  };

  self.addMaintainer = async function() {
    try{
      self.clearStatus();
      self.showInfo("Adding maintainer authorisation");

      let isRegisteredAndEnabled = await self.maintainerRegistry.isMemberRegisteredAndEnabled(self.newMaintainer.id());
      if(!isRegisteredAndEnabled) {
        self.showError("Not a registered maintainer id");
        return;
      }

      let existing = self.maintainers().find((m) => {return m.id == self.newMaintainer.id()});
      if(existing != null) {
        self.showError(self.newMaintainer.id() + " is already a maintainer");
        return;
      }

      let tx = await self.maintenanceLogContract.addWorkAuthorisation(self.newMaintainer.id());
      self.showSuccess("Authorisation submitted");

      await web3.eth.getTransactionReceipt(tx.tx, async function(error, result) {
        if(error != null) {
          self.showError(error);
          return;
        }
      });
    }
    catch(err) {
      self.showError(err);
    }
    finally {

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
      let tx = await self.maintenanceLogContract.verify(logEntry.logNumber);
      logEntry.displayStatus("verifying");
      self.showSuccess("verify tx received " + tx.txt);
      
      await web3.eth.getTransactionReceipt(tx.tx, async function(err, result) {

        self.showSuccess("verify transaction receipt received");

        if(err != null) {
          self.showError(err);
          return;
        }
      });
    }
    catch(err) {
      self.showError(err);
    }
    finally {
      logEntry.allowChanges(true);
    }
  };

  self.addLogEntry = async function() {

    self.newLogEntry.lock(true);
    self.clearStatus();

    try {
      if(!self.newLogEntry.isValid(function(error) {
          self.showError(error);
        })) return;
      
      let id = web3.fromUtf8(self.newLogEntry.id());
      let maintainerId = self.newLogEntry.maintainerId();
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
      self.newLogEntry.reset();

      await web3.eth.getTransactionReceipt(tx.tx, async function(error, result) {

          if(error != null) {
            self.showError(error);
            return;
          }

          console.log("transaction finished. status: " + result.status);
      });
    }
    catch(err) {
      self.showError(err);
    }
    finally {
      self.newLogEntry.lock(false);
    }
  };

  self.loadEntryByLogNumber = async function(logNumber) {
    let existingLogEntry = self.getLogEntry(logNumber);
    if(existingLogEntry == null) {
      var logValues = await self.maintenanceLogContract.getLog(logNumber);
      var logEntry = new MaintenanceLogEntryModel(logValues);
      self.logEntries.push(logEntry);
    }
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

  self.uploadToIpfs = async function(reader, attemptNumber) {

    attemptNumber = attemptNumber || 1;

    self.showInfo("adding file to ipfs...");
    let buffer = ipfs.Buffer.from(reader.result);
    ipfs.files.add(buffer, function(error, response)  {

      self.newDoc.displayStatus("");

      if(error != null) {
        self.showError(error);
        if(attemptNumber < 3) {
          attemptNumber++;
          self.clearStatus();
          self.showInfo("retrying ipfs upload");
          self.newDoc.displayStatus("uploading file, please be patient, it may take up to a minute, sorry!");
          self.uploadToIpfs(reader, attemptNumber);
        }
        return;
      }

      let ipfsId = response[0].hash;
      self.showInfo("file added to ipfs:" + ipfsId);
      self.newDoc.ipfsAddress(ipfsId);
      self.newDoc.displayStatus("");

    });
  };

  self.handleIpfsUpload = async function() {
    try {
      self.clearStatus();
      self.showInfo("reading file");
      let file = document.getElementById("uploadIpfsFilePicker").files[0];
      let reader = new window.FileReader();

      self.newDoc.title(file.name);

      reader.onloadend = function () {
        self.newDoc.displayStatus("uploading file, please be patient, it may take up to a minute, sorry!");
        self.uploadToIpfs(reader, 1);
      };
      reader.readAsArrayBuffer(file);
    }
    catch(err) {
      self.showError(err);
    }
  };

  self.addDoc = async function() {
    try {
      self.newDoc.lock(true);
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
    
      self.newDoc.reset();

      await web3.eth.getTransactionReceipt(txHash.tx, async function(error, result) {
        self.showInfo("Transaction receipt received");
        if(error != null) {
          self.showError(error);
        }
      });
    }
    catch(err) {
      self.showError(err);
    }
    finally {
      self.newDoc.lock(false);
    }
  };    

  self.init();
};

$(function() {
  $(window).load(function() {

    let viewModel = new MaintenanceLogViewModel();

    ko.components.register('vmr-status-bar', {
      viewModel: { instance: viewModel },
      template: VMRUtils.statusBarMarkup
    });

    ko.applyBindings(viewModel);
  });
});