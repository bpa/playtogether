import { set, Toggle } from './html';

export default class Spitzer extends React.Component {
}

Spitzer.config = class Config extends React.Component {
    constructor(props) {
        super(props);
		this.state = {points: 42};
    }

    render() { return (
<table>
  <tbody>
    <tr>
      <td>Points to win: <span>{this.state.points}</span></td>
      <td>
        <div>
        <input type="range" min="3" max="42" step="3" onChange={set.bind(this,'points')}/>
      </div>
      </td>
    </tr>
    <tr>
      <td>
        <i className="glyphicon glyphicon-info-sign" popover="Allow players to call Schneider, meaning their team commits to taking 90 points.  This is opposed to Zola Schneider which is done solo." popover-trigger="mouseenter"></i>
        Allow Schneider:
      </td>
      <td>
        &nbsp;<Toggle onChange={set.bind(this,'allow_schneider')} on={false}/>
      </td>
    </tr>
    <tr>
      <td>
        <i className="glyphicon glyphicon-info-sign" popover="Show who played key cards (Aces, Queens, etc.), and show which trump have been played" popover-trigger="mouseenter"></i>
        Lazy player aids:
      </td>
      <td>
        &nbsp;<Toggle onChange={set.bind(this,'autocount')} on={true}/>
      </td>
    </tr>
    <tr>
      <td>
        <i className="glyphicon glyphicon-info-sign" popover="Play evil.  Queens or Jacks played in suit (except diamonds) are not trump.  They follow the Pinochle ordering instead (A 10 K Q J 9 8 7).  You are required to play a Queen or Jack when its suit is led if it is your only card in that suit, meaning the Queens and Jacks can be drawn out like any other card and taken with a lower trump or higher non-trump." popover-trigger="mouseenter"></i>
        Play with "Reztips" rule:
      </td>
      <td>
        &nbsp;<Toggle onChange={set.bind(this,'restips')} on={false}/>
      </td>
    </tr>
  </tbody>
</table>
	)}
}
