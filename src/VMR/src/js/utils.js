VMRUtils =  
{
    getParameterByName : function(name, url) {
        if (!url) url = window.location.href;
        name = name.replace(/[\[\]]/g, '\\$&');
        var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
            results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, ' '));
    },

    statusBarMarkup : "<div class='status-panel' style='height: 80px'><div data-bind='if: errorText'><div data-bind='html: errorText' class='alert alert-danger'></div></div><div data-bind='if: infoText'><div data-bind='html: infoText' class='alert alert-info'></div></div><div data-bind='if: successText'><div data-bind='html: successText' class='alert alert-success'></div></div></div>",

    addStatusHandlers : function(self) {

        self.errorText = ko.observable("");
        self.infoText = ko.observable("");
        self.successText = ko.observable("");

        self.showError = function(error) {
            self.clearStatus();
            console.log(error);
            self.errorText(error);
          };
        
          self.clearError = function() {
            self.errorText("");
          };
        
          self.showInfo = function(info, timeout) {
        
            timeout = !timeout || isNan(timeout) || timeout == 0 ? 5000 : timeout;
        
            console.log(info);
            self.infoText(info);
        
            setTimeout(function() {
              self.clearInfo();
            }, timeout);
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
    }
}