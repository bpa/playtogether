angular.module('playtogether').controller('HiLoCtl', ['$scope', '$rootScope',
  function($scope, $rootScope) {
    $scope.guesses = [];

    $scope.pick = function() {
      $scope.ws.send({guess: $scope.guess});
    };

    $scope.clear = function() {
      $scope.guesses = [];
      angular.element('#number').trigger('focus');
    };

    $scope.$on('game', function(event, data) {
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
  }]);
