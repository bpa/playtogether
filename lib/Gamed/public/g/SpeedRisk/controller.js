var SpeedRisk = SpeedRisk || {};

SpeedRisk.UI = function(socket) {
  this.stage = new PIXI.Stage(0xFFFFFF, true);
  this.renderer = PIXI.autoDetectRenderer(1200, 800, angular.element("canvas")[0]);
  this.renderer.view.style.width = '1200px';
  this.renderer.view.style.height = '800px';
  this.country = [];
  this.socket = socket;
};

SpeedRisk.UI.prototype.animate = function() {
    var c = this.public.countries[i];
    if (this.players[c.owner].dirty) {
      t = country[i];
      t.sprite.setTexture(PIXI.Texture.fromFrame(data.theme + '_' + c.name));
      t.token.setTexture(PIXI.Texture.fromFrame(data.theme + '_icon'));
    }
    requestAnimFrame( this.animate );
    this.renderer.render(this.stage);
};

SpeedRisk.UI.prototype.onAssetsLoaded = function() {
  console.log("hello", this);
    var background = PIXI.Sprite.fromFrame(this.backgroundImg);
    background.position.x = 0;
    background.position.y = 0;
    this.stage.addChild(background);

    for (var i in this.public.countries) {
      var c = this.public.countries[i];
      var t = {};
      t.owner = c.owner === undefined ? this.id : c.owner;
      var theme = this.players[t.owner].theme;
      console.log(theme);
      t.sprite = this.overlay(i, theme + '_' + c.name, c.sprite);
      t.token = this.overlay(i, theme + '_icon', c.token);
      t.token.anchor.x = t.token.anchor.y = 0.5;
      t.armies = new PIXI.Text(c.armies === undefined ? '' : c.armies, {font: '12px Arial', fill: this.themes[theme]['text-color']});
      t.armies.position.x = c.token.x
      t.armies.position.y = c.token.y
      t.armies.anchor.x = t.token.anchor.y = 0.5;
      this.stage.addChild(t.armies);
      country[i] = t;
    }

    var quit = button('quit', background.width, background.height, 1, 1);
    quit.click = quit.tap = function() {
      if (confirm('Are you sure you want to quit?')) {
        $scope.ws.send({cmd: 'quit'});
      }
    };

    this.stage.addChild(quit);
    requestAnimFrame(animate);
};

SpeedRisk.UI.prototype.overlay = function(id, image, loc) {
    var sprite = PIXI.Sprite.fromFrame(image);
    sprite.position.x = loc.x
    sprite.position.y = loc.y
    this.stage.addChild(sprite);
    sprite.interactive = true;
    sprite.hitArea = new SpeedRisk.Country(loc, image);
    sprite.click = sprite.tap = function(e) {
      console.log(id);
      if (e.originalEvent.altKey === true && this.public.countries[id].owner === this.id) {
        console.log({cmd: 'place', country: id, armies: this.private.armies});
        this.ws.send({cmd: 'place', country: id, armies: this.private.armies});
      }
      else {
        console.log({cmd: 'select', country: id, armies: this.private.armies});
      }
    };
    return sprite;
}

SpeedRisk.UI.prototype.updateCountries = function() {
  for (i in this.public.countries) {
    var c = this.public.countries[i];
    if (c.armies !== undefined) {
      country[i].armies.setText(c.armies);
    }
    var t = country[i];
    if (t.owner !== c.owner && c.owner !== undefined) {
      t.owner = c.owner;
      var theme = this.players[t.owner].theme;
      t.sprite.setTexture(PIXI.Texture.fromFrame(theme + '_' + c.name));
      t.token.setTexture(PIXI.Texture.fromFrame(theme + '_icon'));
    }
  }
}

SpeedRisk.UI.prototype.on_join = function(player) {
  if (this.players === undefined) {
    this.socket.send({cmd: 'status'});
  }
  else {
    this.players[player.player] = new SpeedRisk.Player(player);
  }
}

Object.defineProperty(SpeedRisk.UI.prototype, "status", {
  set: function(data) {
    if (data === undefined)
      return;

    this.state = data.state;
    this.id = data.id;
    this.public = data.public;
    this.private = data.private;
    this.players = {};
    for (var p in data.players) {
      this.players[p] = new SpeedRisk.Player(data.players[p]);
    }
    if (this.backgroundImg === undefined) {
      this.backgroundImg = "g/SpeedRisk/" + data.public.rules.board + "/board.png";
      var assets = [this.backgroundImg, "g/SpeedRisk/images/img.json"];
      for (var theme in data.public.themes) {
        assets.push('g/SpeedRisk/' + data.public.rules.board + '/' + theme + '.json');
      }
      var loader = new PIXI.AssetLoader(assets);
      var ui = this;
      loader.onComplete = function() { ui.onAssetsLoaded() };
      loader.load();
    }
    else {
      updateCountries();
    }
}})

SpeedRisk.Player = function(data) {
  for (var k in data) {
    this[k] = data[k];
  }
  this.dirty = true;
}

Object.defineProperty(SpeedRisk.Player.prototype, "theme", {
  set: function(theme) {
    this.theme = theme;
    this.dirty = true;
  }
})

SpeedRisk.Country = function(loc, image) {
    this.image = image;
    this.texture = PIXI.Texture.fromFrame(image);
    this.x = loc.x;
    this.y = loc.y;
    this.h = this.texture.height;
    this.w = this.texture.width;
}

SpeedRisk.Country.prototype.contains = function(x, y) {
  if (this.w <= 0 || this.h <= 0)
    return false;

  var x1 = x - this.x;
  if (x1 < 0 || x1 > this.w)
    return false;

  //console.log(x, y);
  var y1 = y - this.y;
  if (y1 < 0 || y1 > this.h)
    return false;

  //console.log(x, y, this.x, this.y, x1, y1, this.image);
  //console.log(this.texture.frame, this.texture.baseTexture);
  return true;
}

SpeedRisk.button = function(type, x, y, anchor_x, anchor_y) {
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

  return button;
};

angular.module('playtogether').controller('SpeedRiskCtl', ['$scope', '$document', '$http',
  function($scope, $document, $http) {
    var themes;
    var risk = new SpeedRisk.UI($scope.ws);

    $http.get('g/SpeedRisk/themes.json').success(function(data) {
      themes = data;
      for (var t in themes) {
        if (themes[t]['text-color'] === undefined)
          themes[t]['text-color'] = 'fff';
        if (themes[t]['text-color'][0] !== '#') {
          themes[t]['text-color'] = '#' + themes[t]['text-color'];
        }
      }
      risk.themes = themes;
    });

    $scope.$on('join', function(event, data) {
      risk.on_join(data);
    });

    $scope.$on('status', function(event, data) {
      risk.status = data;
    });

    $scope.$on('ready', function(event, data) {
      risk.players[data.player].ready = true;
    });

    $scope.$on('not ready', function(event, data) {
      risk.players[data.player].ready = false;
    });

    $scope.$on('armies', function(event, data) {
      risk.armies = data.armies;
    });

    $scope.$on('placing', function(event, data) {
      for (var p in risk.players) {
        risk.players[p].ready = false;
      }
      risk.countries = data.countries;
    });

    $scope.$on('theme', function(event, data) {
      risk.players[data.player].theme = data.theme;
    });

    $document.bind('keydown', function(e) {
      if (e.which === 82) { // r
        $scope.ws.send({ cmd: 'ready' });
      }
    });

    $scope.ws.send({ cmd: 'status' });
  }]);
