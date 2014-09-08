angular.module('playtogether').controller('SpeedRiskCtl', ['$scope', '$document',
  function($scope, $document) {
    var stage = new PIXI.Stage(0xFFFFFF, true);
    var renderer = PIXI.autoDetectRenderer(1200, 800, angular.element("canvas")[0]);
    var backgroundImg;
    var country;
    
    function onAssetsLoaded() {
        background = PIXI.Sprite.fromFrame(backgroundImg);
        background.position.x = 0;
        background.position.y = 0;
        stage.addChild(background);

        for (var i in $scope.public.countries) {
          var c = $scope.public.countries[i];
          var theme = c.owner === undefined ? $scope.players[$scope.id].theme : $scope.players[c.owner].theme;
          var t = {};
          t.sprite = PIXI.Sprite.fromFrame(theme + '_' + c.name);
          t.sprite.position.x = c.sprite.x
          t.sprite.position.y = c.sprite.y
          stage.addChild(t.sprite);
          t.token = PIXI.Sprite.fromFrame(theme + '_icon');
          t.token.position.x = c.token.x
          t.token.position.y = c.token.y
          t.token.anchor.x = t.token.anchor.y = 0.5;
          stage.addChild(t.token);
          t.armies = new PIXI.Text(c.armies === undefined ? '' : c.armies);
          t.armies.position.x = c.token.x
          t.armies.position.y = c.token.y + 24
          t.armies.anchor.x = t.token.anchor.y = 0.5;
          stage.addChild(t.armies);
          country[i] = t;
        }

        var quit = button('quit', background.width, background.height, 1, 1);
        quit.click = quit.tap = function() {
          if (confirm('Are you sure you want to quit?')) {
            $scope.ws.send({cmd: 'quit'});
          }
        };

        stage.addChild(quit);
        requestAnimFrame(animate);
    }

    function updateCountries() {
      for (i in country) {
        var c = country[i];
      }
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
      players = data.players;
      if (backgroundImg === undefined) {
        backgroundImg = "g/SpeedRisk/" + data.public.rules.board + "/board.png";
        var assets = [backgroundImg, "g/SpeedRisk/images/img.json"];
        for (var theme in data.public.themes) {
          assets.push('g/SpeedRisk/' + data.public.rules.board + '/' + theme + '.json');
        }
        var loader = new PIXI.AssetLoader(assets);
        loader.onComplete = onAssetsLoaded;
        loader.load();
      }
      else {
        updateCountries();
      }
    });

    $scope.$on('ready', function(event, data) {
      $scope.players[data.player].ready = true;
    });

    $scope.$on('not ready', function(event, data) {
      $scope.players[data.player].ready = false;
    });

    $scope.$on('armies', function(event, data) {
      $scope.private.armies = data.armies;
    });

    $scope.$on('placing', function(event, data) {
      $scope.public.countries = data.countries;
    });

    $document.bind('keydown', function(e) {
      if (e.which === 82) { // r
        $scope.ws.send({ cmd: 'ready' });
      }
    });

    $scope.ws.send({ cmd: 'status' });
  }]);
