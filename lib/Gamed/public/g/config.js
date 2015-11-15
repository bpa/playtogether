define([], function() {
  function config($routeProvider) {
    $routeProvider.
      when('/login', {templateUrl:'login.html',controller:'LoginCtl'}).
      when('/lobby', {templateUrl:'lobby.html',controller:'LobbyCtl'}).
      when('/game/:game', {
        templateUrl: function(p) { return 'g/' + p.game + '/play.html'; },
      }).
      otherwise({redirectTo:'/login'});
  }
  config.$inject = ['$routeProvider'];
  return config;
});
