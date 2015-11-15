define([], function() {
  function HiLoCtl($scope, $location) {
    $scope.guesses = [];

    $scope.pick = function() {
      $scope.ws.send({cmd: 'guess', guess: $scope.guess});
    };

    $scope.clear = function() {
      $scope.guesses = [];
      angular.element('#number').trigger('focus');
    };

    $scope.quit = function() {
        $scope.ws.send({cmd: 'quit'});
        $location.path('/lobby');
    };

    $scope.$on('guess', function(event, data) {
      if (data.answer === 'Too low') {
        $scope.guesses.push({number: $scope.guess, type: 'info'});
      }
      else if (data.answer === 'Too high') {
        $scope.guesses.push({number: $scope.guess, type: 'danger'});
      }
      else {
        $scope.guesses.push({number: $scope.guess, type: 'success'});
      }
      angular.element('#number').trigger('focus');
      $scope.guess = '';
    });
  }

  HiLoCtl.$inject = ['$scope', '$location'];
  return HiLoCtl;
});
