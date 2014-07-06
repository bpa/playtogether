angular.module('playtogether').controller('RookCtl', ['$scope',
  function($scope) {
    $scope.bid = {};

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
      $scope.dealer = data.public.dealer;
      $scope.bidder = data.public.bidder;
      $scope.hand = new Hand(data.private.cards).sort();
    });

    $scope.$on('dealing', function(event, data) {
      $scope.state = 'Dealing';
      $scope.dealer = data.dealer;
    });

    $scope.$on('bidding', function(event, data) {
      $scope.state = 'Bidding';
      $scope.bidder = data.bidder;
    });

    $scope.$on('deal', function(event, data) {
      $scope.state.public.cards = data.cards;
      $scope.hand = new Hand(data.cards).sort();
    });

    $scope.deal = function() {
      $scope.ws.send({ cmd: 'deal' });
    };

    $scope.makeBid = function() {
      $scope.ws.send({ cmd: 'bid', bid: $scope.bid.bid });
    };

    $scope.ws.send({ cmd: 'status' });
  }]);

function Card(str) {
  this.str = str;
  this.suit_str = str.substr(str.length-1, str.length);
  this.number = parseInt(str.substr(0, str.length-1));
  this.ord = this.number === 1 ? 15 : this.number;
}

Card.prototype.suit = function() {
  return this.suit_str;
}

function Hand(cards) {
  this.cards = [];
  if (Array.isArray(cards)) {
    for (var i=0; i<cards.length; i++) {
      this.cards.push(new Card(cards[i]));
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
