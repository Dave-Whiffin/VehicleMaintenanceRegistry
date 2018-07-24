
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

  init: function() {
    MaintenanceLog.logAddress = getParameterByName("address");

    console.log("maintenance log address: " + MaintenanceLog.logAddress);

    ContractFactory.init(function() {
      MaintenanceLog.maintenanceLog = ContractFactory.getMaintenanceLogContract(MaintenanceLog.logAddress);      
      MaintenanceLog.bindEvents();
      return MaintenanceLog.viewMaintenanceLog();
    });
  },

  bindEvents: function() {
    //$(document).on('click', '.btn-view-maintenance-log', App.viewMaintenanceLog);
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

    maintenanceLogRow.append(maintenanceLogTemplate.html());

    MaintenanceLog.maintenanceLog.getDocCount(logNumber)
    .then(function(docCount){

      for(var i = 1; i <= docCount; i++) {
          MaintenanceLog.maintenanceLog.getDoc(logNumber, i)
          .then(function (doc){

            var logDocTemplate  = $('maintenanceLogDocTemplate');
            var docContainer = maintenanceLogRow.find('.log-doc-panel[data-id=' + logNumber + ']');

            console.log(doc);
            logDocTemplate.find(".log-doc-number").text(doc[0]);
            logDocTemplate.find(".log-doc-title").text(doc[1]);
            logDocTemplate.find(".log-doc-ipfs-address").text(doc[2]);

            docContainer.append(logDocTemplate.html());
          });
      }

    });
  },

  viewMaintenanceLog: function() {

    MaintenanceLog.maintenanceLog.vin.call().then(function(val){
      MaintenanceLog.vin = web3.toUtf8(val);

      $(".maintenance-log-vin").text(MaintenanceLog.vin);
      $(".maintenance-log-address").text(MaintenanceLog.logAddress);

      MaintenanceLog.maintenanceLog.getLogCount().then(function(val){
        let totalCount = val;

        for(var i = 1; i <= totalCount; i++) {
          MaintenanceLog.maintenanceLog.getLog(i).then(function(logEntry){
              MaintenanceLog.viewLogEntry(logEntry);
          });
        }
      });
    });
  }
};

$(function() {
  $(window).load(function() {
    MaintenanceLog.init();
  });
});
