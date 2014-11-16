var RoboRally = function (socket) {
  var stage, renderer, players, public, id, private, backgroundImg, now, cards;
  var direction_in_radians = [0, Math.PI/2, Math.PI, Math.PI * 1.5];
  var pieces = {};
  var cards = {};
  var tween = [];

  var animate = function(time) {
    now = time;
    requestAnimFrame(animate);
    for (var i=0; i< tween.length; i++) {
      var f = tween[i];
      if (!f()) {
        tween.splice(i, 1);
      }
    }
    renderer.render(stage);
  };

  var onAssetsLoaded = function() {
    stage = new PIXI.Stage(0xFFFFFF, true);
    renderer = PIXI.autoDetectRenderer(1600, 1600, angular.element("canvas")[0]);
    //renderer.view.style.width = '1600px';
    //renderer.view.style.height = '1600px';
    var background = PIXI.Texture.fromFrame('floor');
    for (var y=0; y<public.course.height; y++) {
      for (var x=0; x<public.course.width; x++) {
        var floor = PIXI.Sprite.fromFrame('floor');
          floor.position.x = x * 64;
          floor.position.y = y * 64;
          stage.addChild(floor);
      }
    }
    //var board = new PIXI.TilingSprite(background, public.course.width * 64, public.course.height * 64);
    //board.position.x = 0;
    //board.position.y = 0;
    //stage.addChild(board);
    for (var y in public.course.tiles) {
      var row = public.course.tiles[y];
      for (var x in row) {
        var tile = row[x];
        if (tile.t !== undefined) {
          var sprite = PIXI.Sprite.fromFrame(tile.t);
          sprite.position.x = x * 64 + 32;
          sprite.position.y = y * 64 + 32;
          sprite.anchor.x = .5;
          sprite.anchor.y = .5;
          sprite.o = tile.o;
          sprite.rotation = direction_in_radians[tile.o]
          stage.addChild(sprite);
        }
      }
    }

    for (var i=0; i<private.cards.length; i++) {
      var c = card(private.cards[i], i);
      cards[c.rr_id] = c;
      stage.addChild(c);
    }

    update_pieces();
  }
  
  var update_pieces = function () {
    for (var p in pieces) {
      console.log(p, pieces[p]);
      stage.removeChild(pieces[p]);
    }
    pieces = {};

    var layers = [[],[],[]];
    for (var p in public.course.pieces) {
      if (p.indexOf("_archive", this.length - "_archive".length) !== -1) { layers[0].push(p); }
      else if (p.indexOf('flag_') == 0) { layers[1].push(p); }
      else { layers[2].push(p); }
    }
    for (var l=0; l<3; l++) {
      for (var p =0; p<layers[l].length; p++) {
        var id = layers[l][p];
        var piece = public.course.pieces[id];
        var sprite = PIXI.Sprite.fromFrame(id);
        sprite.position.x = piece.x * 64 + 32;
        sprite.position.y = piece.y * 64 + 32;
        sprite.anchor.x = .5;
        sprite.anchor.y = .5;
        sprite.o = 0;
        stage.addChild(sprite);
        pieces[id] = sprite;
      }
    }

//    this.quit = pixi_button('quit', background.width, background.height, 1, 1);
//    quit.click = quit.tap = function() {
//      if (confirm('Are you sure you want to quit?')) {
//        socket.send({cmd: 'quit'});
//      }
//    };
//
//    stage.addChild(quit);
    requestAnimFrame(animate);
  }

  var rotation_table = {
    r: [[1, 0,         Math.PI/2],   [2, Math.PI/2, Math.PI],     [3, Math.PI, Math.PI*1.5], [0, Math.PI*1.5, Math.PI*2]],
    u: [[2, 0,         Math.PI],     [3, Math.Pi/2, Math.PI*1.5], [0, Math.PI, 0],           [1, Math.PI*1.5, Math.Pi/2]],
    l: [[3, Math.PI*2, Math.PI*1.5], [0, Math.PI/2, 0],           [1, Math.PI, Math.PI/2],   [2, Math.PI*1.5, Math.PI]  ],
  };

  var rotate = function(sprite, dir, time, after) {
    var start = after === undefined ? now : now + after;
    var end = start + time;
    var start_rotation = rotation_table[dir][sprite.o][1];
    var end_rotation   = rotation_table[dir][sprite.o][2];
    sprite.o           = rotation_table[dir][sprite.o][0];

    return function() {
      if (now < start)
        return true;

      if (now >= end) {
        sprite.rotation = end_rotation;
        return false;
      }
        
      var remaining = (end - now) / time;
      sprite.rotation = end_rotation - ((end_rotation - start_rotation) * remaining);
      return true;
    }
  }

  var move = function(sprite, x, y, time, after) {
    var start = after === undefined ? now : now + after;
    var end = start + time;
    var orig_x = sprite.x;
    var orig_y = sprite.y;

    return function() {
      if (now < start)
        return true;

      if (now >= end) {
        sprite.x = x;
        sprite.y = y;
        return false;
      }

      var remaining = (end - now) / time;
      sprite.x = x - ((x - orig_x) * remaining);
      sprite.y = y - ((y - orig_y) * remaining);
      return true;
    }
  }

  var fall = function(sprite, time, after) {
    var start = after === undefined ? now : now + after;
    var end = start + time;

    return function() {
      if (now < start)
        return true;

      if (now >= end) {
        sprite.scale.x = 0;
        sprite.scale.y = 0;
        return false;
      }

      var remaining = (end - now) / time;
      sprite.scale.x = remaining;
      sprite.scale.y = remaining;
      return true;
    }
  }

  this.on_join = function(ev, player) {
    if (players === undefined) {
      socket.send({cmd: 'status'});
    }
    else {
      players[player.player] = new Player(player);
    }
  }

  this.on_status = function(ev, data) {
    if (data === undefined)
      return;

    state = data.state;
    id = data.id;
    public = data.public;
    private = data.private;
    players = {};
    for (var p in data.players) {
      players[p] = new Player(data.players[p]);
    }
    if (backgroundImg === undefined) {
      var assets = ["g/RoboRally/images.json"];
      var loader = new PIXI.AssetLoader(assets);
      loader.onComplete = onAssetsLoaded;
      loader.load();
    }
  }

  this.on_pieces = function(ev, data) {
    delete data.cmd;
    public.course.pieces = data;
    update_pieces();
  }

  this.on_ready = function(ev, data) {
    console.log(data);
  }

  this.on_programming = function(ev, data) {
  }

  function card(id, order) {
    var sprite = PIXI.Sprite.fromFrame("card");
    sprite.x = order % 2 == 0 ? public.course.width * 64 : public.course.width * 64 + 128;
    sprite.y = Math.floor(order / 2) * 128;
    sprite.rr_x = sprite.x;
    sprite.rr_y = sprite.y;
    var type = id.substring(0, 1);
    var priority = id.substring(1);
    var rotation = 0;
    var image;
    var text;
    switch (type) {
      case '1':
      case '2':
      case '3':
        text = "Move " + type;
        image = "card_move";
        break;
      case 'b':
        rotation = Math.PI;
        image = "card_move";
        text = "Back Up";
        break;
      case 'r':
        image = "card_right";
        text = "Rotate Right";
        break;
      case 'l':
        image = "card_left";
        text = "Rotate Left";
        break;
      case 'u':
        image = "card_u-turn";
        text = "U-Turn";
        break;
    }
    var icon = PIXI.Sprite.fromFrame(image);
    icon.rotation = rotation;
    icon.anchor.x = .5;
    icon.anchor.y = .5;
    icon.x = 64;
    icon.y = 64;
    sprite.addChild(icon);

    var move_text = new PIXI.Text(text, {});
    move_text.anchor.x = .5;
    move_text.anchor.y = 1;
    move_text.x = 64;
    move_text.y = 120;
    sprite.addChild(move_text);

    var priority_text = new PIXI.Text(priority, {});
    priority_text.anchor.x = .5;
    priority_text.x = 64;
    priority_text.y = 8;
    sprite.addChild(priority_text);

    sprite.setInteractive(true);
    sprite.mouseover = card_mouseover;
    sprite.mouseout = card_mouseout;
    sprite.click = sprite.tap = card_select;
    sprite.rr_id = id;
    sprite.rr_order = order;
    sprite.rr_locked = false;
    return sprite;
  }

  function card_mouseover(data) {
    if (data.target.rr_locked)
      data.target.tint = 0xFFCCCC;
    else
      data.target.tint = 0xCCCCFF;
  }

  function card_mouseout(data) {
    data.target.tint = 0xFFFFFF;
  }

  function card_select(data) {
    if (data.target.rr_locked) {
        tween.push(move(data.target, data.target.rr_x, data.target.rr_y, 500));
        data.target.rr_locked = false;
        return;
    }
    for (var r=0; r<5; r++) {
      if (r>=private.registers.length || private.registers[r] === null) {
        tween.push(move(data.target, r * 128, public.course.height * 64, 500));
        data.target.rr_locked = true;
        private.registers[r] = [data.target.rr_id];
        socket.send({ cmd: 'program', registers: private.registers });
        break;
      }
    }
  }

  var Player = function(data) {
    for (var k in data) {
      this[k] = data[k];
    }
  }
}

angular.module('playtogether').controller('RoboRallyCtl', ['$scope', '$http','$document',
  function($scope, $http, $document) {
    var rally = new RoboRally($scope.ws, $http);
    $scope.$on('join', rally.on_join);
    $scope.$on('status', rally.on_status);
    $scope.$on('pieces', rally.on_pieces);
    $scope.$on('ready', rally.on_ready);
    $scope.$on('not ready', rally.on_ready);
    $scope.$on('programming', rally.on_programming);
    $scope.ws.send({ cmd: 'status' });
    //$document.bind('keydown', rally.test);
  }]);
