define([], function () {
  function Card(str) {
    this.str = str;
    this.suit_str = str.substr(str.length-1, str.length);
    this.value = str.substr(0, str.length-1);
  }

  Card.prototype.suit = function() {
    return this.suit_str;
  }

  Card.prototype.equals = function(o) {
    if (o instanceof Card)
      return this.str === o.str;
    if (typeof o === "string")
      return this.str === o;
    else
      return false;
  }

  Card.prototype.cmp = function(o) {
      return this.suit().charCodeAt(0) - o.suit().charCodeAt(0)
      || o.ord - this.ord;
  }

  return Card;
});
