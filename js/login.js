export default React.createClass({
    render: function() { return 
<div>
  <form id="login" method="post" action="/">
    <fieldset>
      <legend>Login</legend>
      <table>
        <tr>
          <td align="right"><label for="user">Username:</label></td>
          <td><input name="username"/></td>
        </tr>
        <tr>
          <td align="right"><label for="user">Passphrase:</label></td>
          <td><input name="passphrase" type="password"/></td>
        </tr>
        <tr>
          <td colspan="2" align="center"><button type="button" onClick={this.login()} class="btn btn-primary">Login</button></td>
        </tr>
      </table>
    </fieldset>
  </form>
  <form id="newaccount" method="POST" action="/newaccount">
    <fieldset>
    <legend>Create an account</legend>
    <table>
      <tr>
        <td align="right">Username (or email):</td><td><input name="username" class="required" minlength="2"/></td>
      </tr>
      <tr>
        <td align="right">Password:</td><td><input id="passphrase" type="password" name="passphrase" class="required" minlength="6"/></td>
      </tr>
      <tr>
        <td align="right">Password(again):</td><td><input type="password" name="passphrase2" equalTo="#passphrase"/></td>
      </tr>
      <tr>
        <td align="right">Your name:</td><td><input name="name" class="required" minlength="2"/></td>
      </tr>
      <tr>
        <td colspan="2" align="center"><button type="button" class="btn btn-standard" onClick={this.createAccount()}>Create Account</button></td>
      </tr>
    </table>
    </fieldset>
  </form>
</div>
    }
});
