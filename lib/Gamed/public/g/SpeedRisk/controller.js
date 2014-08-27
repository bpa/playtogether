angular.module('playtogether').controller('SpeedRiskCtl', ['$scope',
  function($scope) {
    var stage = new PIXI.Stage(0xFFFFFF, true);
    var renderer = PIXI.autoDetectRenderer(1200, 800, angular.element("canvas")[0]);
    var backgroundImg;
    
    function onAssetsLoaded() {
        background = PIXI.Sprite.fromFrame(backgroundImg);
        background.position.x = 0;
        background.position.y = 0;
        stage.addChild(background);

        var quit = button('quit', background.width, background.height, 1, 1);
        quit.click = quit.tap = function() {
          if (confirm('Are you sure you want to quit?')) {
            $scope.ws.send({cmd: 'quit'});
          }
        };

        stage.addChild(quit);
        requestAnimFrame(animate);
    }

    function button(type, x, y, anchor_x, anchor_y) {
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
    }
    
    $scope.$on('join', function(event, data) {
      if ($scope.public === undefined) {
        $scope.ws.send({ cmd: 'status' });
      }
      else {
        $scope.players[data.player.id] = data.player;
      }
    });

    function animate() {
        requestAnimFrame( animate );
        renderer.render(stage);
    }
    
    $scope.$on('status', function(event, data) {
      $scope.state = data.state;
      $scope.id = data.id;
      $scope.public = data.public;
      $scope.private = data.private;
      $scope.players = data.players;
      if (backgroundImg === undefined) {
        backgroundImg = "g/SpeedRisk/" + data.public.rules.board + "/board.png";
        var assets = [backgroundImg, "g/SpeedRisk/images/img.json"];
        var loader = new PIXI.AssetLoader(assets);
        loader.onComplete = onAssetsLoaded;
        loader.load();
      }
    });

    $scope.$on('ready', function(event, data) {
      $scope.players[data.player].ready = true;
    });

    $scope.$on('not ready', function(event, data) {
      $scope.players[data.player].ready = false;
    });
  }]);
