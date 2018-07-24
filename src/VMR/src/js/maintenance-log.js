
function getParameterByName(name, url) {
  if (!url) url = window.location.href;
  name = name.replace(/[\[\]]/g, '\\$&');
  var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
      results = regex.exec(url);
  if (!results) return null;
  if (!results[2]) return '';
  return decodeURIComponent(results[2].replace(/\+/g, ' '));
}

MaintenanceLog = {

  logAddress: null,
  maintenanceLog: null,
  vin: null,
  contractOwner: 0,
  currentAccount: 0,

  init: function() {
    MaintenanceLog.logAddress = getParameterByName("address");

    console.log("maintenance log address: " + MaintenanceLog.logAddress);

    ContractFactory.init(async function() {
      MaintenanceLog.currentAccount = await web3.eth.accounts[0];
      MaintenanceLog.maintenanceLog = ContractFactory.getMaintenanceLogContract(MaintenanceLog.logAddress);      
      MaintenanceLog.vin = web3.toUtf8(await MaintenanceLog.maintenanceLog.vin.call());
      MaintenanceLog.contractOwner = await MaintenanceLog.maintenanceLog.owner.call();
      MaintenanceLog.bindEvents();
      return MaintenanceLog.viewMaintenanceLog();
    });
  },

  bindEvents: function() {
    //$(document).on('click', '.btn-view-maintenance-log', App.viewMaintenanceLog);
  },

  viewDocs: async function(log) {

    let logNumber = parseInt(log[0]);
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

  viewLogEntry: function(log) {
    var maintenanceLogRow = $('#maintenanceLogRow');
    var maintenanceLogTemplate = $('#maintenanceLogEntryTemplate');

    var logNumber = parseInt(log[0]);
    var logId = web3.toUtf8(log[1]);
    var maintainerId = web3.toUtf8(log[2]);
    var maintainerAddress = log[3];
    var date = parseInt(log[4]);
    var properDate = new Date(date * 1000);
    var title = log[5];
    var description = log[6];
    var verified = log[7];
    var verifier = log[8];
    var verificationDate = log[9];

    maintenanceLogTemplate.find('.panel-title').text(logNumber);
    maintenanceLogTemplate.find('.maintenance-log-id').text(logId);
    maintenanceLogTemplate.find('.maintenance-log-maintainer-id').text(maintainerId);
    maintenanceLogTemplate.find('.maintenance-log-maintainer-address').text(maintainerAddress);
    maintenanceLogTemplate.find('.maintenance-log-date').text(properDate);
    maintenanceLogTemplate.find('.maintenance-log-title').text(title);
    maintenanceLogTemplate.find('.maintenance-log-description').text(description);
    maintenanceLogTemplate.find('.maintenance-log-verified').text(verified);
    maintenanceLogTemplate.find('.maintenance-log-verifier').text(verifier);
    maintenanceLogTemplate.find('.maintenance-log-verification-date').text(verificationDate);
    maintenanceLogTemplate.find('.log-doc-panel').attr('data-id', logNumber);
    maintenanceLogTemplate.find('.btn-verify-maintenance-log').attr('data-id', logNumber);

    if(verified || MaintenanceLog.currentAccount != MaintenanceLog.contractOwner) {
      maintenanceLogTemplate.find('.btn-verify-maintenance-log').attr('disabled', true);
    }

    maintenanceLogRow.append(maintenanceLogTemplate.html());

    MaintenanceLog.viewDocs(log);
  },

  viewMaintenanceLog: async function() {

    $(".maintenance-log-vin").text(MaintenanceLog.vin);
    $(".maintenance-log-address").text(MaintenanceLog.logAddress);
    $(".maintenance-log-owner").text(MaintenanceLog.contractOwner);

    var totalCount = await MaintenanceLog.maintenanceLog.getLogCount();

    for(var i = 1; i <= totalCount; i++) {
      let log = await MaintenanceLog.maintenanceLog.getLog(i)
      MaintenanceLog.viewLogEntry(log);
    }
  }
};

$(function() {
  $(window).load(function() {
    MaintenanceLog.init();
  });
});
