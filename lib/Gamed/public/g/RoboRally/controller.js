var RoboRally = RoboRally || {};

RoboRally.UI = function(socket) {
  this.stage = new PIXI.Stage(0xFFFFFF, true);
  this.renderer = PIXI.autoDetectRenderer(1600, 1066, angular.element("canvas")[0]);
  this.renderer.view.style.width = '1200px';
  this.renderer.view.style.height = '800px';
  this.socket = socket;
};

RoboRally.UI.prototype.animate = function() {
    requestAnimFrame( this.animate.bind(this) );
    this.renderer.render(this.stage);
};

RoboRally.UI.prototype.onAssetsLoaded = function() {
    var background = PIXI.Texture.fromFrame('floor');
    console.log(background);
    var board = new PIXI.TilingSprite(background, this.public.course.width * 64, this.public.course.height * 64);
    board.position.x = 0;
    board.position.y = 0;
    this.stage.addChild(board);
    for (var y in this.public.course.tiles) {
      var row = this.public.course.tiles[y];
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
          this.stage.addChild(sprite);
        }
      }
    }

//    var quit = pixi_button('quit', background.width, background.height, 1, 1);
//    quit.click = quit.tap = function() {
//      if (confirm('Are you sure you want to quit?')) {
//        this.socket.send({cmd: 'quit'});
//      }
//    };
//
//    this.stage.addChild(quit);
    requestAnimFrame(this.animate.bind(this));
};

RoboRally.UI.prototype.on_join = function(ev, player) {
  if (this.players === undefined) {
    this.socket.send({cmd: 'status'});
  }
  else {
    this.players[player.player] = new RoboRally.Player(player);
  }
}

RoboRally.UI.prototype.on_status = function(ev, data) {
    if (data === undefined)
      return;

    this.state = data.state;
    this.id = data.id;
    this.public = data.public;
    this.private = data.private;
    this.players = {};
    for (var p in data.players) {
      this.players[p] = new RoboRally.Player(data.players[p]);
    }
    if (this.backgroundImg === undefined) {
      var assets = ["g/RoboRally/images.json"];
      var loader = new PIXI.AssetLoader(assets);
      console.log(this);
      loader.onComplete = this.onAssetsLoaded.bind(this);
      loader.load();
    }
}

RoboRally.UI.prototype.on_ready = function(ev, data) {
}

RoboRally.Player = function(data) {
  for (var k in data) {
    this[k] = data[k];
  }
}

angular.module('playtogether').controller('RoboRallyCtl', ['$scope', '$http',
  function($scope, $http) {
    var rally = new RoboRally.UI($scope.ws, $http);
    $scope.$on('join', rally.on_join.bind(rally));
    $scope.$on('status', rally.on_status.bind(rally));
    $scope.$on('ready', rally.on_ready.bind(rally));
    $scope.$on('not ready', rally.on_ready.bind(rally));
    $scope.ws.send({ cmd: 'status' });
  }]);
