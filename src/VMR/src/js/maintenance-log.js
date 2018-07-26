
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

MaintenanceLog = {

  eventsBound: false,
  logAddress: null,
  contract: null,
  maintainerRegistry: null,
  vin: null,
  contractOwner: 0,
  currentAccount: 0,
  currentUserIsContractOwner: false,

  init: function() {

    //const ipfs = window.IpfsApi('ipfs.infura.io', '5001', {protocol: 'https'});

    //let a = ipfs.add("Qmcq1AVPSg2rP7JKV6SHKwTwWZAvhMZTYBAVX7sJJozdMV");
    
    /*
    ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin "[\"http://example.com\"]"
    ipfs config --json API.HTTPHeaders.Access-Control-Allow-Credentials "[\"true\"]"
    ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods "[\"PUT\", \"POST\", \"GET\"]"
    */

    MaintenanceLog.logAddress = getParameterByName("address");

    console.log("maintenance log address: " + MaintenanceLog.logAddress);

    ContractFactory.init(async function() {

      console.log("length ipfs:" + lengthInUtf8Bytes("Qmcq1AVPSg2rP7JKV6SHKwTwWZAvhMZTYBAVX7sJJozdMV"));

      MaintenanceLog.currentAccount = web3.eth.accounts[0];
      MaintenanceLog.contract = ContractFactory.getMaintenanceLogContract(MaintenanceLog.logAddress);      
      let maintainerRegistryAddress = await MaintenanceLog.contract.maintainerRegistryAddress.call();
      MaintenanceLog.maintainerRegistry = ContractFactory.getMaintainerRegistryContract(maintainerRegistryAddress);
      MaintenanceLog.vin = web3.toUtf8(await MaintenanceLog.contract.vin.call());
      MaintenanceLog.contractOwner = await MaintenanceLog.contract.owner.call();
      MaintenanceLog.currentUserIsContractOwner = MaintenanceLog.currentAccount == MaintenanceLog.contractOwner;
      MaintenanceLog.bindEvents();
      return MaintenanceLog.getAndBindEntries();
    });
  },

  getMaintainerRegistry: function() {
    return MaintenanceLog.maintainerRegistry;
  },

  addLogEntry: async function(event) {
    event.preventDefault();

    let button = $(this);
    let originalButtonText = button.html();

    let id = $("#new-log-entry-id").val();
    let maintainerId = $("#new-log-entry-maintainer-id").val();
    let title = $("#new-log-entry-title").val();
    let description = $("#new-log-entry-description").val();

    if(id == "" || maintainerId == "" || title == "" || description == ""){
      alert("Please complete all fields");
      return;
    }

    if(lengthInUtf8Bytes(id) > 32) {
      alert("id is too long (allowed 32 bytes UTF)");
      return;
    }

    id = web3.fromUtf8(id);
    maintainerId = web3.fromUtf8(maintainerId);

    let isAuthorisedMaintainer = await MaintenanceLog.contract.isAuthorised(maintainerId);
    if(!isAuthorisedMaintainer){
      alert(maintainerId +  " is not an authorised maintainer");
      return;
    }

    try{
       await MaintenanceLog.contract.getLogNumber(id);
       alert("id already exists - it must be unique"); 
       return;
    }
    catch(Err) {
      //it's ok - this is normal
      //the contract throws when the id does not exist
    }

    let isRegisteredAndEnabled = await MaintenanceLog.maintainerRegistry.isMemberRegisteredAndEnabled(maintainerId);
    if(!isRegisteredAndEnabled) {
      alert(maintainerId + " is not registered or not enabled in the maintainer regsistry");
      return;
    }

    let maintainerOwner = await MaintenanceLog.maintainerRegistry.getMemberOwner(maintainerId);
    if(MaintenanceLog.currentAccount != maintainerOwner) {
      alert("only the owner of the maintainer is allowed to log an entry");
      return;
    };

    let date = Math.round(new Date().getTime() / 1000);

    let tx = await MaintenanceLog.contract.add(id, maintainerId, date, title, description);
    
    button.html("log entry submitted");

    setTimeout(function() {
      $(button).html(originalButtonText);
    }, 1000);

    await web3.eth.getTransactionReceipt(tx.tx, async function(error, result) {
      if(error != null){
        console.log(error);
      }
      else{
        console.log("transaction finished. status: " + result.status);

        var logNumber = await MaintenanceLog.contract.getLogNumber(id);
        var log = await MaintenanceLog.getWrappedLog(logNumber);
        MaintenanceLog.bindEntry(log);
      }
    });

    $("#new-log-entry-id").val("");
    $("#new-log-entry-title").val("");
    $("#new-log-entry-description").val("");
  },
  
  bindEvents: function() {
    if(!MaintenanceLog.eventsBound){
      $(document).on('click', '.btn-verify-maintenance-log', MaintenanceLog.verify);
      $(document).on('click', '#btn-add-log-entry', MaintenanceLog.addLogEntry);
      $(document).on('click', '#btn-add-log-doc', MaintenanceLog.addDoc);      
      $(document).on('click', '.add-doc-button', MaintenanceLog.navigateToAddDoc);
      MaintenanceLog.eventsBound = true;
    }
  },

  isValidIpfsAddress: function(ipfsAddress) {
    return lengthInUtf8Bytes(ipfsAddress) === 46;
  },

  validateAddDoc: async function(logNumber, title, ipfsAddress, callBack) {
    if(isNaN(logNumber)) {
      callBack("invalid log number");
      return false;
    }

    logNumber = parseInt(logNumber);

    if(logNumber == 0) {
      callBack("invalid log number");
      return false;
    }

    if(title === "") {
      callBack("invalid title");
      return false;
    }

    if(!MaintenanceLog.isValidIpfsAddress(ipfsAddress)) {
      callBack("invalid ipfs address");
      return false;
    }

    let log;

    try{
      log = await MaintenanceLog.getWrappedLog(logNumber);
    }
    catch(err){
      console.log(err);
      callBack("not a valid log number");
      return false;
    }

    if(log.verified) {
      callBack("Denied - docs can not be added to verified log entries");
      return false;
    }

    let isMaintainerAuthorised = await MaintenanceLog.contract.isAuthorised(log.maintainerId);
    if(!isMaintainerAuthorised)
    {
      callBack("The maintainer is not (or no longer) authorised.");
      return false;
    }

    let maintainerOwner = await MaintenanceLog.maintainerRegistry.getMemberOwner(log.maintainerId);
    
    if(MaintenanceLog.currentAccount != maintainerOwner) {
      callBack("Denied - You are not the owner of the maintainer");
      return false;
    }

    callBack(null, log);
    return true;
  },

  addDoc: async function(event) {
    event.preventDefault();

    let button = $(event.target);
    let buttonText = button.html();
    button.attr("disabled", "disabled");
    button.html("validating");

    let logNumber = $("#new-log-doc-log-number").val();
    let title = $("#new-log-doc-title").val();
    let ipfsAddress = $("#new-log-doc-ipfs-address").val();

    let log;

    if(!await MaintenanceLog.validateAddDoc(logNumber, title, ipfsAddress, function(error, validatedLog) {
        if(error != null) {
          console.log(error);
          alert(error);
        } else {
          log = validatedLog;
        }
      })
    ) 
    {
      button.html(buttonText);
      button.removeAttr("disabled");      
      return;
    } 

    button.html("submitting");
    let txHash;
    try
    {
      txHash = await MaintenanceLog.contract.addDoc(log.logNumber, title, ipfsAddress);
      button.html("submitted");
      button.removeAttr("disabled");

      setTimeout(function() {
        button.html(buttonText);
      }, 1000);

    }
    catch(error) {
      console.log(error);
      button.html(buttonText);
      button.removeAttr("disabled");
      return;
    }

    await web3.eth.getTransactionReceipt(txHash.tx, async function(error, result) {
      if(error != null) {
        console.log(error);
      }
      else {
        console.log(result);
        await MaintenanceLog.getAndBindDocs(logNumber);
      }
    });

  },

  navigateToAddDoc: function(event) {
    event.preventDefault();
    let logNumber = parseInt($(event.target).data('id'));
    $("#new-log-doc-log-number").val(logNumber);
    document.location.href = "#add-log-doc-panel";
  },

  verify: async function(event) {
    event.preventDefault();
    let logNumber = parseInt($(event.target).data('id'));

    let receipt = await MaintenanceLog.contract.verify(logNumber);
    
    let maintenanceLogRow = $('#maintenanceLogRow');
    let panel = maintenanceLogRow.find(".maintenance-log-entry-panel[data-id=" + logNumber + "]");

    let verifyButton = panel.find('.btn-verify-maintenance-log');

    verifyButton.attr('disabled', 'disabled');
    verifyButton.html('Verification submitted');

    await web3.eth.getTransactionReceipt(receipt.tx, async function(err, result) {
      if(err != null) {
        console.log(err);
      }
      else {
        console.log("verify response. status: " + result.status);
        console.log("log number: " + logNumber);

        var log = await MaintenanceLog.getWrappedLog(logNumber);  
        console.log(log);
        console.log("verified: " + log.verified);
        console.log("rebinding log entry to panel");
        MaintenanceLog.bindEntryToPanel(log, panel);
      }
    });
  },

  getWrappedLog: async function(logNumber) {
    return MaintenanceLog.wrapLog(await MaintenanceLog.contract.getLog(logNumber));
  },

  getAndBindDocs: async function(logNumber) {

    var maintenanceLogRow = $('#maintenanceLogRow');
    var logDocTemplate  = $('#maintenanceLogDocTemplate');
    var docContainer = maintenanceLogRow.find('.log-doc-panel[data-id=' + logNumber + ']');

    docContainer.empty();

    console.log("retrieving doc count for log #" + logNumber);

    var docCount = await MaintenanceLog.contract.getDocCount(logNumber);

    console.log("Log#:" + logNumber + " DocCount:" + docCount);

    for(var i = 1; i <= docCount; i++) {
        var doc = await MaintenanceLog.contract.getDoc(logNumber, i);

        logDocTemplate.find(".log-doc-number").text(doc[0]);
        logDocTemplate.find(".log-doc-title").text(doc[1]);
        logDocTemplate.find(".log-doc-ipfs-address").text(doc[2]);

        docContainer.append(logDocTemplate.html());
    }

  },

  wrapLog: function(log) {
    return {
      logNumber : parseInt(log[0]),
      logId : web3.toUtf8(log[1]),
      maintainerId : web3.toUtf8(log[2]),
      maintainerAddress : log[3],
      date : parseInt(log[4]),
      properDate : new Date(parseInt(log[4]) * 1000),
      title : log[5],
      description : log[6],
      verified : log[7],
      verifier : log[8],
      verificationDate : log[9],

      formattedVerificationDate: function() {
        if(this.verificationDate > 0) {
          return new Date(parseInt(this.verificationDate) * 1000) .toString();
        }
        return "";
      },

      formattedVerifier: function() {
        if(this.verifier == 0) {
          return "";
        }
        return this.verifier;
      }
    }
  },

  bindEntryToPanel: function(log, panel) {
    panel.attr("data-id", log.logNumber);
    panel.find(".maintenance-log-entry-panel").attr("data-id", log.logNumber);
    panel.find('.panel-title').text(log.logNumber);
    panel.find('.maintenance-log-id').text(log.logId);
    panel.find('.maintenance-log-maintainer-id').text(log.maintainerId);
    panel.find('.maintenance-log-maintainer-address').text(log.maintainerAddress);
    panel.find('.maintenance-log-date').text(log.properDate);
    panel.find('.maintenance-log-title').text(log.title);
    panel.find('.maintenance-log-description').text(log.description);
    panel.find('.maintenance-log-verified').text(log.verified);
    panel.find('.maintenance-log-verifier').text(log.formattedVerifier());
    panel.find('.maintenance-log-verification-date').text(log.formattedVerificationDate());
    panel.find('.log-doc-panel').attr('data-id', log.logNumber);
    panel.find('.add-doc-button').attr('data-id', log.logNumber);
    panel.find('.btn-verify-maintenance-log').attr('data-id', log.logNumber);

    if(log.verified || !MaintenanceLog.currentUserIsContractOwner) {
      panel.find('.btn-verify-maintenance-log').hide();
    }
    else{
      panel.find('.btn-verify-maintenance-log').show();
    }

    if(log.verified) {
      panel.find('.add-doc-button').hide();
    } else{
      panel.find('.add-doc-button').show();
    }

  },

  bindEntry: function(log) {
    var maintenanceLogRow = $('#maintenanceLogRow');
    var maintenanceLogTemplate = $('#maintenanceLogEntryTemplate');

    MaintenanceLog.bindEntryToPanel(log, maintenanceLogTemplate);
    maintenanceLogRow.append(maintenanceLogTemplate.html());
    MaintenanceLog.getAndBindDocs(log.logNumber);

  },

  getAndBindEntries: async function() {

    $("#maintenanceLogRow").empty();
    $(".maintenance-log-vin").text(MaintenanceLog.vin);
    $(".maintenance-log-address").text(MaintenanceLog.logAddress);
    $(".maintenance-log-owner").text(MaintenanceLog.contractOwner);

    var totalCount = await MaintenanceLog.contract.getLogCount();
    $(".maintenance-log-entry-count").text(totalCount);

    for(var i = 1; i <= totalCount; i++) {
      let log = await MaintenanceLog.getWrappedLog(i);
      MaintenanceLog.bindEntry(log);
    }
  }
};

$(function() {
  $(window).load(function() {
    MaintenanceLog.init();
    ContractFactory.currentAddressChanged = function() {
      MaintenanceLog.init();
    };
  });
});
