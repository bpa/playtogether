var RoboRally = function (socket) {
  var stage, viewport, renderer, players, public, id, private, now, cards, board, modal, ready_button, through;
  var direction_in_radians = [0, Math.PI/2, Math.PI, Math.PI * 1.5];
  var assetsLoaded = false;
  var pieces = {};
  var cards = {};
  var tween = [];
  var step = 750;

  function animate(time) {
    now = time;
    for (var i=0; i< tween.length; i++) {
      var f = tween[i];
      if (!f()) {
        tween.splice(i, 1);
      }
    }
    renderer.render(stage);
    requestAnimFrame(animate);
  };

  function onAssetsLoaded() {
    assetsLoaded = true;
    stage = new PIXI.Stage(0xFFFFFF, true);
    renderer = PIXI.autoDetectRenderer(1600, 1600);
    renderer.view.style.position = "absolute";
    renderer.view.style.width = window.innerWidth + "px";
    renderer.view.style.height = window.innerHeight + "px";
    renderer.view.style.display = "block";
    angular.element("[ng-controller=RoboRallyCtl]")[0].appendChild(renderer.view);
    
    renderer.view.style.width = '1600px';
    renderer.view.style.height = '1600px';
    viewport = new PIXI.DisplayObjectContainer();
    viewport.scale.x = .70;
    viewport.scale.y = .70;
    stage.addChild(viewport);

    create_board();
    viewport.addChild(button("Quit", public.course.width * 64 + 96, public.course.height * 64 + 96, function(data){
        if (confirm('Are you sure you want to quit?')) {
          socket.send({cmd: 'quit'});
        }}));


    for (var i=1; i<=8; i++) {
      var sprite = PIXI.Sprite.fromFrame("flag_" + i);
      sprite.visible = false;
      sprite.anchor.x = .5;
      sprite.anchor.y = .5;
      viewport.addChild(sprite);
      pieces["flag_" + i] = sprite;
    }

    for (var b in public.bots) {
      var sprite = PIXI.Sprite.fromFrame(b + "_archive");
      sprite.visible = false;
      sprite.anchor.x = .5;
      sprite.anchor.y = .5;
      viewport.addChild(sprite);
      pieces[b + "_archive"] = sprite;
    }

    for (var b in public.bots) {
      var sprite = PIXI.Sprite.fromFrame(b);
      sprite.visible = false;
      sprite.anchor.x = .5;
      sprite.anchor.y = .5;
      viewport.addChild(sprite);
      pieces[b] = sprite;
    }

    if (private.cards !== undefined) {
      for (var i=0; i<private.cards.length; i++) {
        var c = card(private.cards[i], i);
        cards[c.rr_id] = c;
        viewport.addChild(c);
      }
    }

    update_pieces();
    if (state === 'Joining') {
      show_bot_choices();
    }
    else {
      ready_button = button("Ready", 11 * 64, public.course.height * 64 + 64, function(data){socket.send({cmd: 'ready'})});
      viewport.addChild(ready_button);
    }
    requestAnimFrame(animate);
  }

  function button(str, x, y, f) {
    var t = new PIXI.Text(str);
    t.x = 5;
    t.y = 5;
    var b = new PIXI.Graphics();
    b.x = x - t.width / 2 - 5;
    b.y = y - t.height / 2 - 5;
    b.beginFill(0xBBBBBB);
    b.lineStyle(5, 0x3333FF);
    b.drawRect(0, 0, t.width + 10, t.height + 10);
    b.addChild(t);
    b.interactive = true;
    b.tap = b.click = f;
    return b;
  }
  
  function update_pieces() {
    for (var p in pieces) {
      pieces[p].visible = false;
    }
    for (var p in public.course.pieces) {
      var piece = public.course.pieces[p];
      sprite = pieces[p];
      sprite.x = piece.x * 64 + 32;
      sprite.y = piece.y * 64 + 32;
      sprite.o = piece.o === undefined ? 0 : piece.o;
      sprite.rotation = direction_in_radians[sprite.o]
      sprite.visible = true;
    }
  }

  function create_board() {
    var x = Math.pow(2, Math.ceil(Math.log(public.course.width * 64) / Math.log(2)));
    var y = Math.pow(2, Math.ceil(Math.log(public.course.height * 64) / Math.log(2)));
    var boardTexture = new PIXI.RenderTexture(x, y, renderer, 0, renderer.resolution);
    boardTexture.crop = new PIXI.Rectangle(0, 0, public.course.width * 64, public.course.height * 64);
    var board = new PIXI.DisplayObjectContainer();

    var floor = PIXI.Texture.fromFrame('floor');
    for (var x=0; x<public.course.width; x++) {
      var c_x = x * 64;
      for (var y=0; y<public.course.height; y++) {
        var c_y = y * 64;
        var floorTile = new PIXI.Sprite(floor);
        floorTile.x = c_x;
        floorTile.y = c_y;
        board.addChild(floorTile);
        var tile = public.course.tiles[y][x];
        if (tile.t !== undefined) {
          var sprite = PIXI.Sprite.fromFrame(tile.t);
          sprite.x = c_x + 32;
          sprite.y = c_y + 32;
          sprite.anchor.x = .5;
          sprite.anchor.y = .5;
          sprite.o = tile.o;
          sprite.rotation = direction_in_radians[tile.o]
          board.addChild(sprite);
        }
      }
    }

    boardTexture.render(board);
    viewport.addChild(new PIXI.Sprite(boardTexture));
  }

  function show_bot_choices() {
    modal = new PIXI.Graphics();
    modal.beginFill(0xBBBBBB);
    modal.lineStyle(5, 0x3333FF);
    modal.bot_map = {};
    var bots = Object.keys(public.bots);
    modal.drawRect(0, 0, 512, Math.ceil(bots.length / 4) * 128 + 64);
    modal.x = 128;
    modal.y = 128;
    viewport.addChild(modal);

    var text = new PIXI.Text("Choose a bot", {});
    text.anchor.x = .5;
    text.x = 256;
    text.y = 10;
    modal.addChild(text);

    var i = 0;
    for (var b in public.bots) {
      var bot = public.bots[b];
      var sprite = PIXI.Sprite.fromFrame(b);
      modal.bot_map[b] = sprite;
      modal.addChild(sprite);
      sprite.rr_ind = i;
      sprite.x = (i % 4) * 128 + 32;
      sprite.y = Math.floor(i / 4) * 128 + 48;
      sprite.rr_name = b;

      var owner = new PIXI.Text(bot.player === undefined ? '' : players[bot.player].name, {});
      owner.rotation = Math.PI * 1.75;
      owner.anchor.x = .5;
      owner.anchor.y = .5;
      owner.x = (i % 4) * 128 + 64;
      owner.y = Math.floor(i / 4) * 128 + 80;
      modal.bot_map[b + "_owner"] = owner;
      modal.addChild(owner);

      if (bot.player === undefined) {
        owner.visible = false;
        sprite.interactive = true;
        sprite.tap = sprite.click = function(data) {
          socket.send({cmd: 'bot', bot: data.target.rr_name});
        };
      }
      else {
        sprite.tint = 0xCCCCCC;
      }
      i++;
    }

    var ready = new PIXI.Graphics();
    ready.beginFill(0xE62E00);
    ready.lineStyle(5, 0x000000);
    ready.drawRect(0, 0, 128, 32);
    ready.x = 192;
    ready.y = Math.ceil(bots.length / 4) * 128;
    ready.interactive = true;
    ready.click = ready.tap = function(data) {
      socket.send({cmd: players[id].ready ? "not ready" : "ready" });
    }
    modal.addChild(ready);
    modal.ready = ready;

    ready.label = new PIXI.Text("Not Ready");
    ready.label.anchor.x = .5;
    ready.label.anchor.y = .5;
    ready.label.x = 64;
    ready.label.y = 16;
    ready.addChild(ready.label);
  }

  var rotation_table = {
    r: [[1, 0,         Math.PI/2],   [2, Math.PI/2, Math.PI],     [3, Math.PI, Math.PI*1.5], [0, Math.PI*1.5, Math.PI*2]],
    u: [[2, 0,         Math.PI],     [3, Math.Pi/2, Math.PI*1.5], [0, Math.PI, 0],           [1, Math.PI*1.5, Math.Pi/2]],
    l: [[3, Math.PI*2, Math.PI*1.5], [0, Math.PI/2, 0],           [1, Math.PI, Math.PI/2],   [2, Math.PI*1.5, Math.PI]  ],
  };

  function rotate(sprite, dir, time, after) {
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

  function move(sprite, x, y, time, after) {
    var start = after === undefined ? now : now + after;
    var end = start + time;
    var orig_x, orig_y;

    return function() {
      if (now < start)
        return true;

      if (orig_x === undefined) {
        x += sprite.x;
        y += sprite.y;
        orig_x = sprite.x;
        orig_y = sprite.y;
      }

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

  function moveTo(sprite, x, y, time, after) {
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

  function fall(sprite, time, after) {
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
      players[player.player.id] = new Player(player.player);
    }
  }

  var on_program = this.on_program = function(ev, data) {
    private.registers = data.registers;
    if (!assetsLoaded)
      return;

    var used = {};
    for (var i=0; i<data.registers.length; i++) {
      var register = data.registers[i];
      if (register === null)
        continue;
      for (var j=0; j<register.length; j++) {
        var card = cards[register[j]];
        used[register[j]] = true;
        card.rr_locked = true;
        card.rr_register = i;
        tween.push(moveTo(cards[register[j]], i * 128, public.course.height * 64, 500));
      }
    }
    for (var c in cards) {
      if (!(c in used)) {
        var card = cards[c];
        card.rr_locked = false;
        tween.push(moveTo(card, card.rr_x, card.rr_y, 500));
      }
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
    on_program({}, private);
    if (!assetsLoaded) {
      var assets = ["g/RoboRally/images.json"];
      var loader = new PIXI.AssetLoader(assets);
      loader.onComplete = onAssetsLoaded;
      loader.load();
    }
  }

  this.on_bot = function(ev, data) {
    if (!assetsLoaded)
      return;
    players[data.player].bot = data.bot;
    public.bots[data.bot] = data.player;
    if (assetsLoaded && state === 'Joining') {
      modal.bot_map[data.bot].tint = 0xCCCCCC;
      modal.bot_map[data.bot].interactive = false;
      modal.bot_map[data.bot + "_owner"].setText(players[data.player].name);
      modal.bot_map[data.bot + "_owner"].visible = true;
    }
  }

  this.on_pieces = function(ev, data) {
    delete data.cmd;
    public.course.pieces = data;
    update_pieces();
  }

  this.on_ready = function(ev, data) {
    var ready = data.cmd === 'ready' ? 0 : 1;
    players[data.player].ready = ready;
    if (modal !== undefined && data.player === id) {
      if (ready) {
        modal.ready.beginFill(0x00A300);
        modal.ready.label.setText('Ready');
      }
      else {
        modal.ready.beginFill(0xE62E00);
        modal.ready.label.setText('Not ready');
      }
      modal.ready.lineStyle(5, 0x000000);
      modal.ready.drawRect(0, 0, 128, 32);
    }
  }

  this.on_programming = function(ev, data) {
    private.cards = data.cards;
    private.registers = [];
    if (assetsLoaded) {
      if (modal !== undefined) {
        console.log(modal);
        viewport.removeChild(modal);
        delete modal;
      }
      for (var c in cards) {
        viewport.removeChild(cards[c]);
      }
      cards = {};
      for (var i=0; i<private.cards.length; i++) {
        var c = card(private.cards[i], i);
        cards[c.rr_id] = c;
        viewport.addChild(c);
      }
    }
    if (ready_button === undefined) {
      ready_button = button("Ready", 5 * 128 + 32, public.course.height * 64 + 32, function(data){socket.send({cmd: 'ready'})});
      viewport.addChild(ready_button);
    }
  }

  this.on_execute = function(ev, data) {
    var delay = through > now ? through - now : 0;
    for (var i=0; i<data.actions.length; i++) {
      var action = data.actions[i];
      var max = 1;
      for (var j=0; j<action.length; j++) {
        var l = action[j].move || 1;
        if (action[j].die !== undefined) l++;
        max = Math.max(max, l);
      }
      delay += step * max;
      for (var j=0; j<action.length; j++) {
        var sprite = pieces[action[j].piece];
        var a = action[j];
        if (a.move !== undefined) {
          var d = a.die ? a.move + 1 : a.move;
          var x = [0, 64, 0, -64][a.dir] * a.move;
          var y = [-64, 0, 64, 0][a.dir] * a.move;
          tween.push(move(sprite, x, y, step * a.move, delay - step * d));
          if (a.die === 'fall') tween.push(fall(sprite, step, delay - a.move));
        }
        if (a.rotate !== undefined) {
          if (a.move === undefined) {
            tween.push(rotate(sprite, a.rotate, step, delay - step));
          }
          else {
            tween.push(rotate(sprite, a.rotate, step / 2, delay - step / 2));
          }
        }
      }
    }
    through = now + delay;
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

    sprite.interactive = true;
    sprite.mouseover = card_mouseover;
    sprite.mouseout = card_mouseout;
    sprite.click = sprite.tap = card_select;
    sprite.rr_id = id;
    sprite.rr_order = order;
    sprite.rr_locked = false;
    for (var i=0; i<private.registers.length; i++) {
      var register = private.registers[i];
      if (register !== null) {
        for (var j=0; j<register.length; j++) {
          if (register[j] === id) {
            sprite.x = i * 128;
            sprite.y = public.course.height * 64;
          }
        }
      }
    }
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
    var registers = private.registers.map(function(r){return r === null ? null : r.slice(0)});
    if (data.target.rr_locked) {
      registers[data.target.rr_register] = null;
    }
    else {
      for (var r=0; r<5; r++) {
        if (r>=registers.length || registers[r] === null) {
          data.target.rr_locked = true;
          registers[r] = [data.target.rr_id];
          break;
        }
      }
    }
    socket.send({ cmd: 'program', registers: registers });
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
    $scope.$on('bot', rally.on_bot);
    $scope.$on('pieces', rally.on_pieces);
    $scope.$on('ready', rally.on_ready);
    $scope.$on('not ready', rally.on_ready);
    $scope.$on('programming', rally.on_programming);
    $scope.$on('program', rally.on_program);
    $scope.$on('execute', rally.on_execute);
    $scope.ws.send({ cmd: 'status' });
  }]);
