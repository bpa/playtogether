var app = angular.module('playtogether', ['ngRoute']);

app.config(['$routeProvider', function($routeProvider) {
  $routeProvider.
    when('/', {templateUrl:'login.html',controller:'LoginCtl'}).
    when('/lobby', {templateUrl:'lobby.html',controller:'LobbyCtl'}).
    otherwise({redirectTo:'/login'});
  }]);

app.run(['$rootScope', '$location', function($rootScope, $location) {
		$rootScope.$on('login', function(data) {
				$location.path('/login');
		});
		$rootScope.$on('games', function(data) {
				$rootScope.games = data.games;
				$rootScope.instances = data.instances;
				$location.path('/lobby');
		});
  }]);

app.service('WebSocket', ['$rootScope', '$location',
  function($rootScope, $location) {
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
      $rootScope.$emit(msg.cmd, msg);
    };
		return wrapper;
  }]);

app.controller('LoginCtl', ['$scope', 'WebSocket',
  function($scope, ws) {
  }]);

app.controller('LobbyCtl', ['$scope', '$rootScope', 'WebSocket', '$location',
  function($scope, $rootScope, ws, $location) {
		if ($rootScope.token === undefined) {
			$location.path('/');
		}
  }]);
