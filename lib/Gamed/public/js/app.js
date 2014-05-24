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
    send: function(data) { ws.send(JSON.stringify(data)); }
  };
  ws.onopen = function() {
    console.log("connection established ...");
  };
  ws.onmessage = function(event) {
    var msg = JSON.parse(event.data);
    console.log(msg);
    $rootScope.$broadcast(msg.cmd, msg);
    $rootScope.$apply();
  };
  $rootScope.$on('login', function(data) {
    if ($window.sessionStorage.token !== undefined) {
      $rootScope.ws.send({cmd: 'reconnect', token: $window.sessionStorage.token });
    }
    else {
      $location.path('/login');
    }
  });
  $rootScope.$on('welcome', function(event, data) {
    $window.sessionStorage.token = data.token;
    $location.path('/lobby');
  });
  $rootScope.$on('create', function(event, data) {
    $location.path('/game/' + data.game);
    $rootScope.ws.send({cmd: 'join', name: data.name});
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

    $scope.getCreateUrl = function() {
      return 'g/' + $scope.config.game + '/create.html';
    };
    
    $scope.create = function() {
      $scope.config.cmd = 'create';
      $scope.ws.send($scope.config);
    };

    if ($window.sessionStorage.token === undefined) {
      $location.path('/login');
    }

    $scope.$on('games', function(event, data) {
      $scope.games = data.games;
      $scope.instances = data.instances;
    });

    $scope.$on('join', function(event, data) {
      console.log("do something here");
    });
  }]);
