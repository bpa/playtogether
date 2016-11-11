export default class Lobby extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            games: [],
            instances: [],
            selected: {render_config: () => <div/>}
        }
    }

    componentDidMount() {
        this.props.ws.send({cmd: 'games'});
    }

    on_games(msg) {
        console.log("got games");
        this.setState({
            games: msg.games,
            instances: msg.instances
        });
    }

    render() { return (
       <div>
          <div className="page-header">
            <h1>Welcome</h1>
          </div>
          <div className="well container-fluid">
            <div className="row">
              <div className="col-md-2">
                <h4>Available games:</h4>
                <div className="btn-group-vertical form-inline">
                  {this.state.games.map((g) => <button className="btn btn-success" btn-radio="{g}" uncheckable>{g}</button>)}
                </div>
              </div>
              <form className="col-md-10">
                <div className="form-inline">
                  <input name="name" className="form-control" required placeholder="Game name"/>
                  <button type="button" className="btn btn-primary" onClick={this.create}>Create Game</button>
                  {this.state.selected.render_config()}
                </div>
              </form>
            </div>
          </div>
          <div className="well">
            <ul>Join existing game:
              {this.state.instances.map((i) => 
              <li>
                <button type="button" className="btn btn-primary" onClick={this.join}>{i.name}({i.game})</button>
              </li>)}
            </ul>
          </div>
        </div>
    )}

    create() {
        console.log('hello');
    }

    on_error(msg) {
        this.setState({error: msg.reason});
    }
}
