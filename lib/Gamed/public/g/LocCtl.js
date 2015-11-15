define([], function() {
  function LocCtl($scope, $location) {
    $scope.gameStyle = function() {
      var g = $location.path().match(/game\/([^/]*)/);
      return g === null ? undefined : "g/" + g[1] + "/style.css";
    }
  }
  LocCtl.$inject = ['$scope', '$location'];
  return LocCtl;
});
