// This is an active module of the pierreliefauche Add-on

exports.main = function() {
    var data = require("self").data;
    var pageMod = require("page-mod");
    pageMod.PageMod({
      include: "*",
      contentScriptWhen: 'ready',
      contentScriptFile: [data.url('jquery-1.7.1.min.js'), data.url('script.js')],
      contentScript: 'var headID = document.getElementsByTagName("head")[0];var cssNode = document.createElement("link");cssNode.type = "text/css";cssNode.rel = "stylesheet";cssNode.href = "'+data.url('style.css')+'";headID.appendChild(cssNode);'
    });
};