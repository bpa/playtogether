define([], function() {
  function LoginCtl ($scope) {
    $scope.login = function() {
      $scope.ws.send({cmd: 'login', username: $scope.username, passphrase: $scope.passphrase });
    };
    $scope.createAccount = function() {
      $scope.ws.send({cmd: 'create_user', username: $scope.newUser, passphrase: $scope.newPass, name: $scope.name });
    };
  }
  LoginCtl.$inject = ['$scope'];
  return LoginCtl;
});
