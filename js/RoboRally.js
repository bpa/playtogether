import { set } from './html';

export default class RoboRally extends React.Component {
}

RoboRally.config = class Config extends React.Component {
	constructor(props) {
		super(props);
		props.setConfig('course', 'checkmate');
	}

	render() { return (
<table>
  <tbody>
    <tr>
      <td><button className="btn btn-success" onClick={set.bind(this, 'course', 'checkmate'
  )}>Checkmate</button></td>
      <td>&nbsp;5 - 8 Players</td>
    </tr>
    <tr>
      <td><button className="btn btn-success" onClick={set.bind(this, 'course', 'risky_exchange')}>Risky Exchange</button></td>
      <td>&nbsp;2 - 8 Players</td>
    </tr>
    <tr>
      <td><button className="btn btn-success" onClick={set.bind(this, 'course', 'dizzy_dash')}>Dizzy Dash</button></td>
      <td>&nbsp;2 - 8 Players</td>
    </tr>
  </tbody>
</table>
	)}
}
