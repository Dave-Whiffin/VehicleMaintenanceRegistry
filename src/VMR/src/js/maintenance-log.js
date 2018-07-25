
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
  maintenanceLog: null,
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


    $("#maintenanceLogRow").empty();

    MaintenanceLog.logAddress = getParameterByName("address");

    console.log("maintenance log address: " + MaintenanceLog.logAddress);

    ContractFactory.init(async function() {
      MaintenanceLog.currentAccount = web3.eth.accounts[0];
      MaintenanceLog.maintenanceLog = ContractFactory.getMaintenanceLogContract(MaintenanceLog.logAddress);      
      MaintenanceLog.vin = web3.toUtf8(await MaintenanceLog.maintenanceLog.vin.call());
      MaintenanceLog.contractOwner = await MaintenanceLog.maintenanceLog.owner.call();
      MaintenanceLog.currentUserIsContractOwner = MaintenanceLog.currentAccount == MaintenanceLog.contractOwner;
      MaintenanceLog.bindEvents();
      return MaintenanceLog.viewMaintenanceLog();
    });
  },

  getMaintainerRegistry: async function() {
    let maintainerRegistryAddress = await MaintenanceLog.maintenanceLog.maintainerRegistryAddress.call();
    return ContractFactory.getMaintainerRegistryContract(maintainerRegistryAddress);
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

    let isAuthorisedMaintainer = await MaintenanceLog.maintenanceLog.isAuthorised(maintainerId);
    if(!isAuthorisedMaintainer){
      alert(maintainerId +  " is not an authorised maintainer");
      return;
    }

    try{
       await MaintenanceLog.maintenanceLog.getLogNumber(id);
       alert("id already exists - it must be unique"); 
       return;
    }
    catch(Err) {
      //it's ok - this is normal
      //the contract throws when the id does not exist
    }

    let maintainerRegistry = await MaintenanceLog.getMaintainerRegistry();

    let isRegisteredAndEnabled = await maintainerRegistry.isMemberRegisteredAndEnabled(maintainerId);
    if(!isRegisteredAndEnabled) {
      alert(maintainerId + " is not registered or not enabled in the maintainer regsistry");
      return;
    }

    let maintainerOwner = await maintainerRegistry.getMemberOwner(maintainerId);
    if(MaintenanceLog.currentAccount != maintainerOwner) {
      alert("only the owner of the maintainer is allowed to log an entry");
      return;
    };

    let date = Math.round(new Date().getTime() / 1000);

    let tx = await MaintenanceLog.maintenanceLog.add(id, maintainerId, date, title, description);
    
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

        var logNumber = await MaintenanceLog.maintenanceLog.getLogNumber(id);
        var log = await MaintenanceLog.getWrappedLog(logNumber);
        MaintenanceLog.viewLogEntry(log);
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
      $(document).on('click', '.add-doc-button', MaintenanceLog.navigateToAddDoc);
      $(document).on('click', '#btn-add-log-doc', MaintenanceLog.addDoc);
      MaintenanceLog.eventsBound = true;
    }
  },

  addDoc: async function(event) {
    event.preventDefault();

    let logNumber = $("#new-log-doc-log-number").val();
    let title = $("#new-log-doc-title").val();
    let ipfsAddress = $("#new-log-doc-ipfs-address").val();

    if(isNaN(logNumber)) {
      return;
    }

    logNumber = parseInt(logNumber);

    let log = await MaintenanceLog.getWrappedLog(logNumber);

    if(log.verified) {
      alert("Denied - docs can not be added to verified log entries");
      return;
    }

    let isMaintainerAuthorised = await MaintenanceLog.maintenanceLog.isAuthorised(log.maintainerId);
    if(!isMaintainerAuthorised)
    {
      alert("The maintainer is not (or no longer) authorised.");
      return;
    }

    let maintainerRegistry = await MaintenanceLog.getMaintainerRegistry();
    let maintainerOwner = await maintainerRegistry.getMemberOwner(log.maintainerId);
    
    if(MaintenanceLog.currentAccount != maintainerOwner) {
      alert("Denied - You are not the owner of the maintainer");
      return;
    }

    alert("success - so far");

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

    let receipt = await MaintenanceLog.maintenanceLog.verify(logNumber);
    
    let maintenanceLogRow = $('#maintenanceLogRow');
    let panel = maintenanceLogRow.find(".maintenance-log-entry-panel[data-id=" + logNumber + "]");

    let verifyButton = panel.find('.btn-verify-maintenance-log');

    verifyButton.attr('disabled', 'disabled');
    verifyButton.html('Verification submitted');

    web3.eth.getTransactionReceipt(receipt.tx, async function(err, result) {
      if(err != null) {
        console.log(err);
      }
      else{
        console.log("verify response. status: " + result.status);
        var log = await MaintenanceLog.getWrappedLog(logNumber);

        panel.find('.maintenance-log-verified').text(log.verified);
        panel.find('.maintenance-log-verifier').text(log.verifier);
        panel.find('.maintenance-log-verification-date').text(log.verificationDate); 

        if(log.verified) {
          verifyButton.html('Verified');
        }
      }
    });
  },

  getWrappedLog: async function(logNumber) {
    return MaintenanceLog.wrapLog(await MaintenanceLog.maintenanceLog.getLog(logNumber));
  },

  viewDocs: async function(logNumber) {

    var maintenanceLogRow = $('#maintenanceLogRow');
    var logDocTemplate  = $('#maintenanceLogDocTemplate');
    var docContainer = maintenanceLogRow.find('.log-doc-panel[data-id=' + logNumber + ']');

    console.log("retrieving doc count for log #" + logNumber);

    var docCount = await MaintenanceLog.maintenanceLog.getDocCount(logNumber);

    console.log("Log#:" + logNumber + " DocCount:" + docCount);

    for(var i = 1; i <= docCount; i++) {
        var doc = await MaintenanceLog.maintenanceLog.getDoc(logNumber, i);

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
      verificationDate : log[9]
    }
  },

  viewLogEntry: function(log) {
    var maintenanceLogRow = $('#maintenanceLogRow');
    var maintenanceLogTemplate = $('#maintenanceLogEntryTemplate');

    maintenanceLogTemplate.find(".maintenance-log-entry-panel").attr("data-id", log.logNumber);
    maintenanceLogTemplate.find('.panel-title').text(log.logNumber);
    maintenanceLogTemplate.find('.maintenance-log-id').text(log.logId);
    maintenanceLogTemplate.find('.maintenance-log-maintainer-id').text(log.maintainerId);
    maintenanceLogTemplate.find('.maintenance-log-maintainer-address').text(log.maintainerAddress);
    maintenanceLogTemplate.find('.maintenance-log-date').text(log.properDate);
    maintenanceLogTemplate.find('.maintenance-log-title').text(log.title);
    maintenanceLogTemplate.find('.maintenance-log-description').text(log.description);
    maintenanceLogTemplate.find('.maintenance-log-verified').text(log.verified);
    maintenanceLogTemplate.find('.maintenance-log-verifier').text(log.verifier);
    maintenanceLogTemplate.find('.maintenance-log-verification-date').text(log.verificationDate);
    maintenanceLogTemplate.find('.log-doc-panel').attr('data-id', log.logNumber);
    maintenanceLogTemplate.find('.add-doc-button').attr('data-id', log.logNumber);
    maintenanceLogTemplate.find('.btn-verify-maintenance-log').attr('data-id', log.logNumber);

    if(log.verified || !MaintenanceLog.currentUserIsContractOwner) {
      maintenanceLogTemplate.find('.btn-verify-maintenance-log').attr('disabled', 'disabled');
    }
    else{
      maintenanceLogTemplate.find('.btn-verify-maintenance-log').removeAttr('disabled');
    }

    maintenanceLogRow.append(maintenanceLogTemplate.html());

    MaintenanceLog.viewDocs(log.logNumber);
  },

  viewMaintenanceLog: async function() {

    $(".maintenance-log-vin").text(MaintenanceLog.vin);
    $(".maintenance-log-address").text(MaintenanceLog.logAddress);
    $(".maintenance-log-owner").text(MaintenanceLog.contractOwner);

    var totalCount = await MaintenanceLog.maintenanceLog.getLogCount();

    for(var i = 1; i <= totalCount; i++) {
      let log = await MaintenanceLog.getWrappedLog(i);
      MaintenanceLog.viewLogEntry(log);
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
