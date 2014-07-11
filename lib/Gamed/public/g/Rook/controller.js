angular.module('playtogether').controller('RookCtl', ['$scope',
  function($scope) {
    $scope.bid = { nest: [] };
    $scope.color = { R: 'Red', G: 'Green', B: 'Blue', Y: 'Yellow' };
    $scope.seats = { n: 0, e: 1, s: 2, w: 3, 0: 'n', 1: 'e', 2: 's', 3: 'w' };

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
      $scope.private.cards = new Hand(data.private.cards).sort();
      $scope.players = data.players;
      var trick = {};
      var l = $scope.seats[data.public.leader];
      if (data.public.trick !== undefined) {
        for (var i=0; i<data.public.trick.length; i++) {
          trick[$scope.seats[(l + i) % 4]] = new Card(data.public.trick[i]);
        }
      }
      $scope.public.trick = trick;
    });

    $scope.$on('dealing', function(event, data) {
      $scope.state = 'Dealing';
      if ($scope.public !== undefined) {
        $scope.public.dealer = data.dealer;
        delete $scope.public.trump;
        $scope.last = { hand: new Hand() };
      }
    });

    $scope.$on('bidding', function(event, data) {
      $scope.state = 'Bidding';
      if ($scope.public !== undefined)
        $scope.public.bidder = data.bidder;
    });

    $scope.$on('deal', function(event, data) {
      if ($scope.private !== undefined)
        $scope.private.cards = new Hand(data.cards).sort();
    });

    $scope.$on('bid', function(event, data) {
      if (data.player !== undefined) {
        $scope.public.bidder = data.bidder;
        $scope.players[data.player].bid = data.bid;
      }
    });

    $scope.$on('nest', function(event, data) {
      $scope.private.cards.add(data.nest);
      $scope.private.cards.sort();
      $scope.state = 'Declaring';
    });

    $scope.$on('trump', function(event, data) {
      $scope.state = 'PlayTricks';
      $scope.public.trump = data.trump;
      $scope.bid = { nest: [] };
      $scope.last = { hand: new Hand() };
      $scope.winner = undefined;
      for (var p in $scope.players) {
        delete $scope.players[p].bid;
        delete $scope.players[p].pass;
      }
    });

    $scope.$on('trick', function(event, data) {
      var hand = new Hand(data.trick);
      console.log(hand);
      var l = $scope.seats[data.leader];
      $scope.last = {
        winner: data.winner,
        leader: data.leader,
        n: hand.cards[(4 - l) % 4],
        e: hand.cards[(5 - l) % 4],
        s: hand.cards[(6 - l) % 4],
        w: hand.cards[(7 - l) % 4],
      };
      $scope.public.leader = data.winner;
      $scope.public.player = data.winner;
      $scope.public.trick = {};
    });

    $scope.$on('play', function(event, data) {
      $scope.public.trick[data.player] = new Card(data.card);
      $scope.public.player = data.next;
    });

    $scope.$on('invalid_card', function(event, data) {
      $scope.private.cards.cards.push(new Card(data.card));
      $scope.private.cards.sort();
    });

    $scope.$on('round', function(event, data) {
      $scope.public.points = data.points;
    });

    $scope.$on('final', function(event, data) {
      delete $scope.public.trump;
      $scope.state = 'GameOver';
    });

    $scope.deal = function() {
      $scope.ws.send({ cmd: 'deal' });
    };

    $scope.makeBid = function() {
      $scope.ws.send({ cmd: 'bid', bid: $scope.bid.bid });
    };

    $scope.pass = function() {
      $scope.ws.send({ cmd: 'bid', bid: 'pass' });
    };

    $scope.clicked = function() {
      if ($scope.state === 'Declaring') {
        $scope.bid.nest.push(this.c);
      }
      else {
        $scope.ws.send({ cmd: 'play', card: this.c.str });
      }
      $scope.private.cards.cards.splice(this.$index, 1);
    };

    $scope.range = function(n) {
      return new Array(n);
    };

    $scope.remove = function() {
      $scope.private.cards.cards.push($scope.bid.nest[this.$index]);
      $scope.bid.nest.splice(this.$index, 1);
      $scope.private.cards.sort();
    };

    $scope.declare = function() {
      if ($scope.bid.trump === undefined) {
        alert("You must choose a trump");
        return;
      }
      if ($scope.bid.nest.length !== 5) {
        alert("You must put 5 cards back in the nest");
        return;
      }
      $scope.ws.send({ cmd: 'declare', trump: $scope.bid.trump, nest: $scope.bid.nest.map(function(c) { return c.str; }) });
      $scope.private.cards.remove($scope.bid.nest);
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

Card.prototype.equals = function(o) {
  if (!(o instanceof Card)) return false;

  return this.str === o.str;
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

Hand.prototype.indexof = function(card) {
  for (var c=0; c<this.cards.length; c++) {
    if (card.equals(this.cards[c])) return c;
  }
  return -1;
}

Hand.prototype.add = function(cards) {
  if (Array.isArray(cards)) {
    for (var i=0; i<cards.length; i++) {
      this.cards.push(new Card(cards[i]));
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

