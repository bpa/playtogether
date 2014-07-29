angular.module('playtogether').controller('SpitzerCtl', ['$scope', '$sce',
  function($scope, $sce) {
    var ord = {};
    for (var i=0; i<4; i++) {
      var s = ['C','H','S','D'][i];
      for (var j=0; j<6; j++) {
        var v = [7,8,9,'K',10,'A'][j];
        ord[v + s] = i * 10 + j;
      }
    }
    for (var i=0; i<4; i++) {
      var s = ['D','H','S','C'][i];
      ord['J'+s] = 50 + i;
      ord['Q'+s] = 55 + i;
    }
    ord['7D'] = 58;
    ord['QC'] = 59;
    $scope.ord = ord;

    var suit = { C: '&clubs;', S: '&spades;', H: '&hearts;', D: '&diams;' };
    $scope.seats = { n: 0, e: 1, s: 2, w: 3, 0: 'n', 1: 'e', 2: 's', 3: 'w' };
    $scope.ann = { type: 'none' };

    function SpitzerCard(str) {
      Card.call(this, str);
      this.d = $sce.trustAsHtml(this.value + suit[this.suit_str]);
      this.ord = $scope.ord[str];
    }

    SpitzerCard.prototype = Object.create(Card.prototype);

    SpitzerCard.prototype.suit = function() {
      return    this.value === 'J' ? 'D'
              : this.value === 'Q' ? 'D'
              :                      this.suit_str;
    };

    SpitzerCard.prototype.cmp = function(o) {
      return o.ord - this.ord;
    }

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
      $scope.private.cards = new Hand(SpitzerCard, data.private.cards).sort();
      $scope.players = data.players;
      var trick = {};
      var l = $scope.seats[data.public.leader];
      if (data.public.trick !== undefined) {
        for (var i=0; i<data.public.trick.length; i++) {
          trick[$scope.seats[(l + i) % 4]] = new SpitzerCard(data.public.trick[i]);
        }
      }
      $scope.public.trick = trick;
      setAnnouncmentOptions();
    });

    $scope.$on('dealing', function(event, data) {
      $scope.state = 'Dealing';
      if ($scope.public !== undefined) {
        $scope.public.dealer = data.dealer;
        delete $scope.public.trump;
        $scope.last = { hand: new Hand(SpitzerCard) };
      }
    });

    $scope.$on('announcing', function(event, data) {
      $scope.state = 'Announcing';
      if ($scope.public !== undefined) {
        $scope.public.player = data.player;
      }
    });

    $scope.$on('deal', function(event, data) {
      if ($scope.private !== undefined) {
        $scope.private.cards = new Hand(SpitzerCard, data.cards).sort();
        setAnnouncmentOptions();
      }
    });

    function setAnnouncmentOptions() {
      var hand = $scope.private.cards;
      if (hand.indexof('QC') !== -1 && hand.indexof('QS') !== -1) {
        $scope.ann.queens = true;
        $scope.ann.aces = 0;
        $scope.ann.fail = 0;
        for (var i=0; i<3; i++) {
          var s = ['C','H','S'][i];
          var n = ['clubs','hearts','spades'][i];
          if (hand.indexof('A'+s) !== -1) {
            $scope.ann.aces++;
          }
          else if (hand.suit[s] > 0) {
            $scope.ann.fail++;
            $scope.ann[n] = true;
          }
        }
        if ($scope.ann.aces < 3 && $scope.ann.fail === 0) {
          for (var i=0; i<3; i++) {
            var s = ['C','H','S'][i];
            var n = ['clubs','hearts','spades'][i];
            if (hand.suit[s] === undefined) {
              $scope.ann[n] = true;
            }
          }
        }
      }
    }

    $scope.announce = function() {
      var a = { cmd: 'announce' };
      switch ($scope.ann.type) {
        case 'sneaker':
          a.announcement = 'none';
          break;
        case 'clubs':
          a.announcement = 'call';
          a.call = 'AC';
          break;
        case 'hearts':
          a.announcement = 'call';
          a.call = 'AH';
          break;
        case 'spades':
          a.announcement = 'call';
          a.call = 'AS';
          break;
        case 'first':
          a.announcement = 'call';
          a.call = 'first';
          break;
        default:
          a.announcement = $scope.ann.type;
      }
      $scope.ws.send(a);
    };

    $scope.$on('announcement', function(event, data) {
      $scope.state = 'PlayTricks';
      $scope.ann = { type: 'none' };
    });

    $scope.$on('trick', function(event, data) {
      var hand = new Hand(SpitzerCard, data.trick);
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
      $scope.public.trick[data.player] = new SpitzerCard(data.card);
      $scope.public.player = data.next;
    });

    $scope.$on('error', function(event, data) {
      if (data.cards !== undefined) {
        $scope.private.cards = new Hand(SpitzerCard, data.cards);
        $scope.private.cards.sort();
      }
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
