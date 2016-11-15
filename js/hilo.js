export default class HiLo extends React.Component {
    render() { return (
<div>
  <div>
    Pick a number: <input ref="number" onKeyPress={this.keyPressed} />
    <button type="button" className="btn btn-primary" onClick={this.pick}>Pick</button>
    <button type="button" className="btn btn-standard" onClick={this.clear}>Clear</button>
    <button type="button" className="btn btn-danger" onClick={this.quit}>Quit</button>
  </div>
  <div className="well inline-form">
    {this.state.guesses}
  </div>
</div>
    )}

    constructor() {
        super();
        this.keyPressed = this.keyPressed.bind(this);
        this.pick = this.pick.bind(this);
        this.clear = this.clear.bind(this);
        this.quit = this.quit.bind(this);
        this.state = {guesses:[]};
    }

    keyPressed(e) {
        if (e.key == 'Enter') {
            this.pick();
        }
    }

    pick() {
        this.value = parseInt(this.refs.number.value);
        if (this.value) {
            this.props.ws.send({cmd: 'guess', guess: this.value});
        }
    }

    clear() {
      this.setState({guesses: []});
      this.refs.number.focus();
    }

    quit() {
        this.props.ws.send({cmd: 'quit'});
    }

    on_guess(msg) {
        let g = this.value;
        if (msg.answer === 'Too low') {
            this.insert(<Guess key={g} value={g} type='info'/>);
        }
        else if (msg.answer === 'Too high') {
            this.insert(<Guess key={g} value={g} type='danger'/>);
        }
        else {
            this.insert(<Guess key={g} value={g} type='success'/>);
        }
        this.refs.number.value = '';
        this.refs.number.focus();
    }

    insert(guess) {
        let i = 0;
        while (    this.state.guesses[i]
                && this.state.guesses[i].props.value > guess.props.value) {
            i++;
        }
        this.state.guesses.splice(i, 0, guess);
        this.setState({guesses: this.state.guesses});
    }
}

function Guess(props) {
    return <div className={'alert alert-'+props.type}>{props.value}</div>
}

HiLo.config = (p) => <div/>;
