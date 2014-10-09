var RoboRally = function (socket) {
  var stage, renderer, players, public, id, private, backgroundImg;

  var animate = function() {
    requestAnimFrame(animate);
    renderer.render(stage);
  };

  var onAssetsLoaded = function() {
    stage = new PIXI.Stage(0xFFFFFF, true);
    renderer = PIXI.autoDetectRenderer(1600, 1066, angular.element("canvas")[0]);
    renderer.view.style.width = '1200px';
    renderer.view.style.height = '800px';
    var background = PIXI.Texture.fromFrame('floor');
    var board = new PIXI.TilingSprite(background, public.course.width * 64, public.course.height * 64);
    board.position.x = 0;
    board.position.y = 0;
    stage.addChild(board);
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
            case 'e': sprite.rotation = Math.PI / 2; break;
            case 's': sprite.rotation = Math.PI; break;
            case 'w': sprite.rotation = Math.PI * 1.5; break;
          }
          stage.addChild(sprite);
        }
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
    $scope.$on('ready', rally.on_ready);
    $scope.$on('not ready', rally.on_ready);
    $scope.ws.send({ cmd: 'status' });
  }]);
