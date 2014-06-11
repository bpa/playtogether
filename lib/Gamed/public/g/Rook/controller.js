angular.module('playtogether').controller('RookCtl', ['$scope',
  function($scope) {
    $scope.$on('join', function(event, data) {
      if ($scope.state === undefined) {
        $scope.ws.send({ cmd: 'status' });
      }
      else {
        //update players
      }
    });

    $scope.$on('status', function(event, data) {
      $scope.state = data.state;
      $scope.player_id = data.id;
      $scope.dealer = data.status.dealer;
      $scope.bidder = data.status.bidder;
      $scope.hand = data.private.cards;
    });

    $scope.$on('dealing', function(event, data) {
      $scope.state = 'Dealing';
      $scope.dealer = data.dealer;
    });

    $scope.$on('bidding', function(event, data) {
      $scope.state = 'Bidding';
    });

    $scope.$on('deal', function(event, data) {
      $scope.hand = data.hand;
    });

    $scope.deal = function() {
      $scope.ws.send({ cmd: 'deal' });
    };

    $scope.ws.send({ cmd: 'status' });
  }]);
