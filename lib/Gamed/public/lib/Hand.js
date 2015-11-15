define([], function() {
  function Hand(type, cards) {
    this.cards = [];
    this.type = type;
    this.suit = {};
    if (Array.isArray(cards)) {
      for (var i=0; i<cards.length; i++) {
        var card = new type(cards[i]);
        var suit = card.suit();
        this.cards.push(card);
        this.suit[suit] = this.suit[suit] ? this.suit[suit] + 1 : 1;
      }
    }
  }

  Hand.prototype.sort = function() {
    this.cards.sort(function (a, b) {
      return a.cmp(b);
    });

    this.suit = {}
    for (var i=0; i<this.cards.length; i++) {
      var suit = this.cards[i].suit();
      this.suit[suit] = this.suit[suit] ? this.suit[suit] + 1 : 1;
    }
    return this;
  }

  Hand.prototype.indexof = function(card) {
    for (var c=0; c<this.cards.length; c++) {
      if (this.cards[c].equals(card)) return c;
    }
    return -1;
  }

  Hand.prototype.add = function(cards) {
    if (!Array.isArray(cards)) cards = [cards];
    for (var i=0; i<cards.length; i++) {
      var card = new this.type(cards[i]);
      var suit = card.suit();
      this.cards.push(card);
      this.suit[suit] = this.suit[suit] ? this.suit[suit] + 1 : 1;
    }
  }

  Hand.prototype.remove = function(cards) {
    if (cards instanceof Card) cards = [cards];
    if (!Array.isArray(cards)) return;

    for (var i=0; i<cards.length; i++) {
      var idx = this.indexof(cards[i]);
      if (idx != -1) {
        var card = this.cards.splice(idx, 1);
        this.suit[card[0].suit()]--;
      }
    }
  }

  return Hand;
});
