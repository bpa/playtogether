define(['g/config', 'g/run', 'g/LobbyCtl', 'g/LocCtl', 'g/LoginCtl'],
  function(config, run, LobbyCtl, LocCtl, LoginCtl) {
    var app = angular.module('playtogether', ['ngRoute', 'ui.bootstrap']);
    app.config(config);
    app.run(run);
    app.controller('LobbyCtl', LobbyCtl);
    app.controller('LocCtl', LocCtl);
    app.controller('LoginCtl', LoginCtl);
    return app
});
