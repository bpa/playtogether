define(['g/RoboRally/Engine'], function(RoboRally) {
  function RoboRallyCtl($scope, $http, $document) {
    var rally = new RoboRally($scope.ws);
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
  }
  RoboRallyCtl.$inject = ['$scope', '$http','$document'];
  return RoboRallyCtl;
});
