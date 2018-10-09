var exec = require('cordova/exec');

module.exports = {
  isInstalled: function (successCallback, errorCallback) {
    exec(successCallback, errorCallback, 'weibo', 'isInstalled', []);
  },
  shareWebpage: function (webpage, successCallback, errorCallback) {
    exec(successCallback, errorCallback, 'weibo', 'shareWebpage', [webpage]);
  }
}
