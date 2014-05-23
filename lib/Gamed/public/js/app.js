var app = angular.module('playtogether', ['ngRoute']);

app.config(['$routeProvider', function($routeProvider) {
	$routeProvider.
		when('/login', {templateUrl:'login.html',controller:'LoginCtl'}).
		when('/lobby', {templateUrl:'lobby.html',controller:'LobbyCtl'}).
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
		$rootScope.$apply();
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
		if ($window.sessionStorage.token === undefined) {
			$location.path('/login');
		}
		$scope.$on('games', function(event, data) {
			$scope.games = data.games;
			$scope.instances = data.instances;
			$scope.$apply();
		});
	}]);
