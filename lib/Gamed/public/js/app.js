var app = angular.module('playtogether', ['ngRoute', 'ui.bootstrap']);

app.config(['$routeProvider', function($routeProvider) {
  $routeProvider.
    when('/login', {templateUrl:'login.html',controller:'LoginCtl'}).
    when('/lobby', {templateUrl:'lobby.html',controller:'LobbyCtl'}).
    when('/game/:game', {
      templateUrl: function(p) { return 'g/' + p.game + '/play.html'; },
    }).
    otherwise({redirectTo:'/login'});
  }]);

app.run(['$rootScope', '$location', '$window', function($rootScope, $location, $window) {
  var ws = new WebSocket('ws:' + $location.host() + ':3000/websocket');
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
  $rootScope.ws = wrapper;
}]);

app.controller('LoginCtl', ['$scope',
  function($scope) {
    $scope.login = function() {
      $scope.ws.send({cmd: 'login', username: $scope.username, passphrase: $scope.passphrase });
    };
    $scope.createAccount = function() {
      $scope.ws.send({cmd: 'create_user', username: $scope.newUser, passphrase: $scope.newPass, name: $scope.name });
    };
  }]);

app.controller('LobbyCtl', ['$scope', '$window', '$location',
  function($scope, $window, $location) {
    var game_name = undefined;
    $scope.config = {};

    $scope.$on('join', function(event, data) {
      $scope.ws.send({cmd: 'games'});
    });

    $scope.$on('games', function(event, data) {
      $scope.games = data.games;
      $scope.instances = data.instances;
    });

    $scope.$on('create', function(event, data) {
      if (game_name === data.name) {
        $location.path('/game/' + data.game);
        $scope.ws.send({cmd: 'join', name: data.name});
      }
      else {
        $scope.instances.push(data);
      }
    });

    $scope.getCreateUrl = function() {
      return 'g/' + $scope.config.game + '/create.html';
    };
    
    $scope.create = function() {
      $scope.config.cmd = 'create';
      $scope.ws.send($scope.config);
      game_name = $scope.config.name;
    };

    $scope.join = function() {
      $location.path('/game/' + this.i.game);
      $scope.ws.send({cmd: 'join', name: this.i.name});
    };

    $scope.ws.send({cmd: 'games'});
  }]);
