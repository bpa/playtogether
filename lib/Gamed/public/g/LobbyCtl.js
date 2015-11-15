define([], function() {
  function LobbyCtl($scope, $window, $location, $document) {
    var game_name = undefined;
    $scope.config = {};
    $document.unbind('keydown');

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
      console.log($scope.config);
      $scope.ws.send($scope.config);
      game_name = $scope.config.name;
    };

    $scope.join = function() {
      $location.path('/game/' + this.i.game);
      $scope.ws.send({cmd: 'join', name: this.i.name});
    };

    $scope.ws.send({cmd: 'games'});
  }

  LobbyCtl.$inject = ['$scope', '$window', '$location', '$document'];
  return LobbyCtl;
});
