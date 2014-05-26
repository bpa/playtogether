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
  var wrapper = {
    send: function(data) {} //LobbyCtl sends when it loads and that is before this is ready
  };
  ws.onopen = function() {
    console.log("connection established ...");
  };
  ws.onmessage = function(event) {
    var msg = JSON.parse(event.data);
    wrapper.send = function(data) { ws.send(JSON.stringify(data)); };
    console.log(msg);
    $rootScope.$broadcast(msg.cmd, msg);
    $rootScope.$apply();
  };
  $rootScope.$on('login', function(data) {
    if ($window.sessionStorage.token !== undefined) {
      $rootScope.ws.send({cmd: 'login', token: $window.sessionStorage.token });
    }
    else {
      $location.path('/login');
    }
  });
  $rootScope.$on('welcome', function(event, data) {
    $window.sessionStorage.token = data.token;
    $location.path('/lobby');
	$rootScope.ws.send({cmd: 'games'});
  });
  $rootScope.$on('error', function(event, data) {
    if (data.reason === 'Login failed' || data.reason === "Can't reconnect") {
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
    $scope.config = {};
    $scope.ws.send({cmd: 'games'});

    $scope.getCreateUrl = function() {
      return 'g/' + $scope.config.game + '/create.html';
    };
    
    $scope.create = function() {
      $scope.config.cmd = 'create';
      $scope.ws.send($scope.config);
    };

    $scope.$on('create', function(event, data) {
      $location.path('/game/' + data.game);
      $scope.ws.send({cmd: 'join', name: data.name});
    });

    $scope.join = function() {
      console.log(this);
      $location.path('/game/' + this.i.game);
      $scope.ws.send({cmd: 'join', name: this.i.name});
    };

    if ($window.sessionStorage.token === undefined) {
      $location.path('/login');
    }

    $scope.$on('games', function(event, data) {
      $scope.games = data.games;
      $scope.instances = data.instances;
    });
  }]);
