angular.module('playtogether').controller('SpeedRiskCtl', ['$scope',
  function($scope) {
    $scope.$on('join', function(event, data) {
      if ($scope.public === undefined) {
        $scope.ws.send({ cmd: 'status' });
      }
      else {
        $scope.players[data.player.id] = data.player;
      }
    });

    $scope.$on('status', function(event, data) {
      $scope.state = data.state;
      $scope.id = data.id;
      $scope.public = data.public;
      $scope.private = data.private;
      $scope.players = data.players;
    });

    $scope.$on('ready', function(event, data) {
      $scope.players[data.player].ready = true;
    };

    $scope.$on('not ready', function(event, data) {
      $scope.players[data.player].ready = false;
    };
  }]);
