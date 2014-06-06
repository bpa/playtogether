angular.module('playtogether').controller('RookCtl', ['$scope',
  function($scope) {
    $scope.ws.send({cmd: 'state'});

    $scope.$on('status', function(event, data) {
		$scope.state = data.state;
    });

	$scope.$on('dealing', function(event, data) {
		$scope.state = 'Dealing';
		$scope.dealer = data.dealer;
	});

	$scope.ws.send({ cmd: 'status' });
  }]);
