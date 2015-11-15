define(['lib/Card'], function(Card) {
  function RookCard(str) {
    Card.call(this, str);
    this.number = parseInt(str.substr(0, str.length-1));
    this.ord = this.number === 1 ? 15 : this.number;
  }

  RookCard.prototype = Object.create(Card.prototype);
  return RookCard;
});
