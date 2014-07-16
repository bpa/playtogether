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

app.controller('LocCtl', ['$scope', '$location',
  function($scope, $location) {
    $scope.gameStyle = function() {
      var g = $location.path().match(/game\/([^/]*)/);
      return g === null ? undefined : "g/" + g[1] + "/style.css";
    }
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

    $scope.$on('welcome', function(event, data) {
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

    $scope.$on('delete', function(event, data) {
      for (var i=0; i<$scope.instances.length; i++) {
        if ($scope.instances[i].name === data.name) {
          $scope.instances.splice(i, 1);
          break;
        }
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

function Card(str) {
  this.str = str;
  this.suit_str = str.substr(str.length-1, str.length);
}

Card.prototype.suit = function() {
  return this.suit_str;
}

Card.prototype.equals = function(o) {
  if (!(o instanceof Card)) return false;

  return this.str === o.str;
}

function Hand(type, cards) {
  this.cards = [];
  this.type = type;
  if (Array.isArray(cards)) {
    for (var i=0; i<cards.length; i++) {
      this.cards.push(new type(cards[i]));
    }
  }
}

Hand.prototype.sort = function() {
  this.cards.sort(function(a, b) {
    return a.suit().charCodeAt(0) - b.suit().charCodeAt(0)
        || b.ord - a.ord;
  });
  return this;
}

Hand.prototype.indexof = function(card) {
  for (var c=0; c<this.cards.length; c++) {
    if (card.equals(this.cards[c])) return c;
  }
  return -1;
}

Hand.prototype.add = function(cards) {
  if (Array.isArray(cards)) {
    for (var i=0; i<cards.length; i++) {
      this.cards.push(new this.type(cards[i]));
    }
  }
}

Hand.prototype.remove = function(cards) {
  if (cards instanceof Card) cards = [cards];
  if (!Array.isArray(cards)) return;

  for (var i=0; i<cards.length; i++) {
    var idx = this.indexof(cards[i]);
    if (idx != -1) {
      this.cards.splice(idx, 1);
    }
  }
}

