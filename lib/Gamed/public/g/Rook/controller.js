function RookCard(str) {
  Card.call(this, str);
  this.number = parseInt(str.substr(0, str.length-1));
  this.ord = this.number === 1 ? 15 : this.number;
}

RookCard.prototype = Object.create(Card.prototype);

angular.module('playtogether').controller('RookCtl', ['$scope',
  function($scope) {
    $scope.bid = { nest: [] };
    $scope.color = { R: 'Red', G: 'Green', B: 'Blue', Y: 'Yellow' };
    $scope.seats = { n: 0, e: 1, s: 2, w: 3, 0: 'n', 1: 'e', 2: 's', 3: 'w' };

    RookCard.prototype.suit = function() {
      return this.suit_str === '_' && $scope.public.trump !== undefined ? $scope.public.trump : this.suit_str;
    };

    RookCard.prototype.playable = function() {
      var lead = $scope.public.trick[$scope.public.leader];
      if (lead === undefined)
        return true;

      var lead_suit = lead.suit();
      if ($scope.private.cards.suit[lead_suit]>0 && this.suit() !== lead_suit)
        return false;
      return true;
    };

    $scope.$on('error', function(event, data) {
      if (data.cards) {
        $scope.private.cards = new Hand(RookCard, data.cards).sort();
      }
      else {
        $scope.ws.send({ cmd: 'status' });
      }
    });

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
      $scope.private.cards = new Hand(RookCard, data.private.cards).sort();
      $scope.players = data.players;
      var trick = {};
      var l = $scope.seats[data.public.leader];
      if (data.public.trick !== undefined) {
        for (var i=0; i<data.public.trick.length; i++) {
          trick[$scope.seats[(l + i) % 4]] = new RookCard(data.public.trick[i]);
        }
      }
      $scope.public.trick = trick;
    });

    $scope.$on('dealing', function(event, data) {
      $scope.state = 'Dealing';
      if ($scope.public !== undefined) {
        $scope.public.dealer = data.dealer;
        delete $scope.public.trump;
        $scope.last = { hand: new Hand(RookCard) };
      }
    });

    $scope.$on('bidding', function(event, data) {
      $scope.state = 'Bidding';
      if ($scope.public !== undefined) {
        $scope.public.bidder = data.bidder;
        for (var p in $scope.players) {
          delete $scope.players[p].bid;
          delete $scope.players[p].pass;
        }
        delete $scope.public.player;
      }
    });

    $scope.$on('declaring', function(event, data) {
      $scope.state = 'Declaring';
      if ($scope.public !== undefined) {
        $scope.public.player = data.player;
      }
    });

    $scope.$on('deal', function(event, data) {
      if ($scope.private !== undefined)
        $scope.private.cards = new Hand(RookCard, data.cards).sort();
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
      $scope.public.player = $scope.id;
    });

    $scope.$on('trump', function(event, data) {
      $scope.state = 'PlayTricks';
      $scope.public.trump = data.trump;
      $scope.private.cards.sort();
      $scope.bid = { nest: [] };
      $scope.last = { hand: new Hand(RookCard) };
      $scope.winner = undefined;
    });

    $scope.$on('trick', function(event, data) {
      var hand = new Hand(RookCard, data.trick);
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
      $scope.public.trick[data.player] = new RookCard(data.card);
      $scope.public.player = data.next;
    });

    $scope.$on('invalid_card', function(event, data) {
      $scope.private.cards.cards.push(new RookCard(data.card));
      $scope.private.cards.sort();
    });

    $scope.$on('round', function(event, data) {
      $scope.public.points = data.points;
      delete $scope.public.leader;
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

    $scope.quit = function() {
      if (confirm('Are you sure you want to quit?')) {
        $scope.ws.send({cmd: 'quit'});
      }
    };

    $scope.clicked = function() {
      if ($scope.state === 'Declaring') {
        if ($scope.public.bidder !== $scope.id)
		      return;
        else
          $scope.bid.nest.push(this.c);
      }
      else if ($scope.state === 'PlayTricks') {
        if ($scope.public.player !== $scope.id)
		      return;
        $scope.ws.send({ cmd: 'play', card: this.c.str });
      }
      else {
        return;
      }
      var card = $scope.private.cards.cards.splice(this.$index, 1);
      $scope.private.cards.suit[card[0].suit()]--;
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
      if ($scope.public.trump === undefined) {
        alert("You must choose a trump");
        return;
      }
      if ($scope.bid.nest.length !== 5) {
        alert("You must put 5 cards back in the nest");
        return;
      }
      $scope.ws.send({ cmd: 'declare', trump: $scope.public.trump, nest: $scope.bid.nest.map(function(c) { return c.str; }) });
      $scope.private.cards.remove($scope.bid.nest);
    };

    $scope.ws.send({ cmd: 'status' });
  }]);

