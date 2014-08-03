angular.module('playtogether').controller('SpeedRiskCtl', ['$scope',
  function($scope) {
    var stage = new PIXI.Stage(0xFFFFFF);
    var renderer = PIXI.autoDetectRenderer(1200, 800, angular.element("canvas")[0]);
    var background;
    
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
      if (background === undefined) {
        var backgroundImg = new PIXI.Texture.fromImage("g/SpeedRisk/" + data.public.rules.board + "/board.png");
        background = new PIXI.Sprite(backgroundImg);
        background.position.x = 0;
        background.position.y = 0;
        stage.addChild(background);
        requestAnimFrame( animate );
      }
    });

    $scope.$on('ready', function(event, data) {
      $scope.players[data.player].ready = true;
    });

    $scope.$on('not ready', function(event, data) {
      $scope.players[data.player].ready = false;
    });

    $scope.quit = function() {
      if (confirm('Are you sure you want to quit?')) {
        $scope.ws.send({cmd: 'quit'});
      }
    };
  }]);
