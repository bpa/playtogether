angular.module('playtogether').controller('RookCtl', ['$scope',
  function($scope) {
    $scope.bid = {};
    $scope.ws.send({cmd: 'state'});

    $scope.$on('state', function(event, data) {
		
    });

    $scope.$on('game', function(event, data) {
    });
  }]);
