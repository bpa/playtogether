var RoboRally = function (socket) {
  var stage, renderer, players, public, id, private, backgroundImg;
  var pieces = {};

  var animate = function() {
    requestAnimFrame(animate);
    renderer.render(stage);
  };

  var onAssetsLoaded = function() {
    stage = new PIXI.Stage(0xFFFFFF, true);
    renderer = PIXI.autoDetectRenderer(1600, 1066, angular.element("canvas")[0]);
    renderer.view.style.width = '1600px';
    renderer.view.style.height = '1066px';
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
          switch (tile.o) {
            case 1: sprite.rotation = Math.PI / 2; break;
            case 2: sprite.rotation = Math.PI; break;
            case 3: sprite.rotation = Math.PI * 1.5; break;
          }
          stage.addChild(sprite);
        }
      }
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
};

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
  }

  var Player = function(data) {
    for (var k in data) {
      this[k] = data[k];
    }
  }
}

angular.module('playtogether').controller('RoboRallyCtl', ['$scope', '$http',
  function($scope, $http) {
    var rally = new RoboRally($scope.ws, $http);
    $scope.$on('join', rally.on_join);
    $scope.$on('status', rally.on_status);
    $scope.$on('pieces', rally.on_pieces);
    $scope.$on('ready', rally.on_ready);
    $scope.$on('not ready', rally.on_ready);
    $scope.ws.send({ cmd: 'status' });
  }]);
