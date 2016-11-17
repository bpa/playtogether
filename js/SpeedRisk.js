import { set } from './html';

export default class SpeedRisk extends React.Component {
}

SpeedRisk.config = class Config extends React.Component {
    constructor(props) {
        super(props);
        props.setConfig('board', 'Classic');
    }

    render() { return (
<table>
  <tbody>
    <tr>
      <td><button className="btn btn-success" onClick={set.bind(this,'board','Classic')}>Classic</button></td>
      <td>&nbsp;2 - 6 Players</td>
    </tr>
    <tr>
      <td><button className="btn btn-success" onClick={set.bind(this,'board','Ultimate')}>Ultimate</button></td>
      <td>&nbsp;2 - 12 Players</td>
    </tr>
  </tbody>
</table>
	)}
}
