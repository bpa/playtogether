define([], function() {
  function Run($rootScope, $location, $window) {
    var ws = new WebSocket('ws:' + $location.host() + ':' + $location.port() + '/websocket/');
    var ignoring = true;
    var wrapper = {
      send: function(data) {} //LobbyCtl sends when it loads and that is before this is ready
    };
    ws.onmessage = function(event) {
      if (ignoring) {
        wrapper.send = function(data) { ws.send(JSON.stringify(data)); };
        ignoring = false;
      }
      var msg = JSON.parse(event.data);
      console.log(msg);
      $rootScope.$broadcast(msg.cmd, msg);
      $rootScope.$apply();
    };
    $rootScope.$on('login', function(data) {
      if ($window.sessionStorage.token !== undefined || $window.localStorage.username !== undefined) {
        $rootScope.ws.send({cmd: 'login', token: $window.sessionStorage.token, username: $window.localStorage.username });
      }
      else {
        $location.path('/login');
      }
    });
    $rootScope.$on('welcome', function(event, data) {
      $window.sessionStorage.token = data.token;
      $window.localStorage.username = data.username;
      $location.path('/lobby');
    });
    $rootScope.$on('join', function(event, data) {
      $location.path('/game/' + data.game);
    });
    $rootScope.$on('error', function(event, data) {
      if (data.reason === 'Login failed') {
        $location.path('/login');
      }
    });
    $rootScope.$on('delete', function(event, data) {
      if (data.game !== undefined && data.name !== undefined) {
        $location.path('/lobby');
      }
    });
    $rootScope.ws = wrapper;
  }
  Run.$inject = ['$rootScope', '$location', '$window'];
  return Run;
});
