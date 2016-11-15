class Game extends React.Component {
    render() { return (
<label className="btn btn-success" key={g}>
  <input type="radio" autoComplete="off" onClick={this.select.bind(this, g)}/>{g}
</label>
    )}
}

export default class Lobby extends React.Component {
    constructor(props) {
        super(props);
        this.config = {};
        this.create = this.create.bind(this);
        this.setConfig = this.setConfig.bind(this);
        this.nameChanged = this.nameChanged.bind(this);
        this.state = {
            games: [],
            instances: [],
            config: () => <div/>
        }
    }

    componentDidMount() {
        this.props.ws.send({cmd: 'games'});
    }

    on_games(msg) {
        let games = msg.games.map((g) => (
<label className="btn btn-success" key={g}>
  <input type="radio" autoComplete="off" onClick={this.select.bind(this, g)}/>{g}
</label>));
        this.setState({
            games: games,
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
                <div className="btn-group-vertical form-inline" data-toggle="buttons">
                  {this.state.games}
                </div>
              </div>
              <form className="col-md-10">
                <div className="form-inline">
                  <input name="name" className="form-control" required placeholder="Game name" onChange={this.nameChanged}/>
                  <button type="button" className="btn btn-primary" onClick={this.create}>Create Game</button>
                  {React.createElement(this.state.config, {setConfig: this.setConfig})}
                </div>
              </form>
            </div>
          </div>
          <div className="well">
            <ul>Join existing game:
              {this.state.instances.map((i) => 
              <li key={i.name}>
                <button type="button" className="btn btn-primary" onClick={this.join.bind(this,i)}>{i.name}({i.game})</button>
              </li>)}
            </ul>
          </div>
        </div>
    )}

    select(e) {
        this.game = e;
        this.config = {};
        this.setState({config: play.games[e].config});
    }

    nameChanged(e) {
        this.config.name = e.target.value;
    }

    create(r) {
        if (this.config) {
            this.config.cmd = 'create';
            this.config.game = this.game;
            this.props.ws.send(this.config);
        }
    }

    on_create(msg) {
        this.setState({instances: this.state.instances.concat(msg)});
        if (this.config.name === msg.name) {
            this.props.ws.send({cmd:'join', name:msg.name});
        }
    }

    join(game) {
        this.props.ws.send({cmd:'join', name:game.name});
    }

    setConfig(k, v) {
        this.config[k] = v;
    }

    on_error(msg) {
        this.setState({error: msg.reason});
    }
}
