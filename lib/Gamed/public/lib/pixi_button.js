define(['js/pixi'], function(PIXI) {
  function pixi_button(type, x, y, anchor_x, anchor_y) {
    var textureBase = PIXI.Texture.fromFrame(type);
    var textureHover = PIXI.Texture.fromFrame(type + '_hover');
    var texturePressed = PIXI.Texture.fromFrame(type + '_pressed');
    var button = new PIXI.Sprite(textureBase);
    button.buttonMode = true;
    if (anchor_x !== undefined) button.anchor.x = anchor_x;
    if (anchor_y !== undefined) button.anchor.y = anchor_y;
    button.position.x = x;
    button.position.y = y;
    button.interactive = true;

    button.mouseover = function(data) {
      this.isOver = true;
      if (this.isdown)
        return;
      this.setTexture(textureHover);
    };

    button.mouseout = function(data) {
      this.isOver = false;
      if (this.isdown)
        return;
      this.setTexture(textureBase);
    };

    button.mousedown = button.touchstart = function(data) {
      this.isdown = true;
      this.setTexture(texturePressed);
    };

    button.mouseup = button.touchend = button.mouseupoutside = button.touchendoutside = function(data) {
      this.isdown = false;
      if (this.isOver)
        this.setTexture(textureHover);
      else
        this.setTexture(textureBase);
    };
  }
  return button;
});
