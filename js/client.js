import Lobby from './lobby';
import Login from './login';
import HiLo from './hilo';
import Rook from './rook';

export let games = {
    HiLo: HiLo,
    Rook: Rook,
}

export function together() {
	ReactDOM.render(<Client/>, document.getElementById('root'));
}

let Socket = function(on_message) {
    let self = this;

    self.init = function() {
        let loc = window.location;
        self.ws = new WebSocket('ws:'+loc.hostname+':'+loc.port+'/websocket');
        self.ws.onmessage = on_message;
        self.send = self._ign;
        self.ws.onopen = function(e) {
            self.send = self._send;
        }
        self.ws.onclose = self.init;
    };

    self.close = function() {
        self.ws.onclose = undefined;
        self.ws.close();
    };

    self._ign = function(msg) {};
    self._send = function(msg) {
        console.log('<', msg);
        self.ws.send(JSON.stringify(msg));
    };

    self.init();
};

function deliver(msg, obj) {
	if (msg.cmd) {
		let o = obj, f;
		let f_name = 'on_' + msg.cmd;
		while (o) {
			f = o[f_name];
			if (typeof f === 'function') {
				f.call(obj, msg);
				return;
			}
			o = Object.getPrototypeOf(o);
		}
	}
}

function on_message(m) {
	let msg = JSON.parse(m.data);
	console.log('>', msg);
	deliver(msg, this);
	deliver(msg, this.game);
}

export class Client extends React.Component {
	constructor() {
		super();
		this.ws = new Socket(on_message.bind(this));
		this.state = {game: null};
	}

    render() {
        if (this.state.game) {
            return React.createElement(this.state.game, {
                ws: this.ws,
                ref: (e) => this.game = e
            });
        }
        else {
            return <div>Logging in...</div>;
        }
    }

    on_login(msg) {
      if ( window.sessionStorage.token !== undefined
		|| window.localStorage.username !== undefined) {
        	this.ws.send({
				cmd: 'login',
				token: window.sessionStorage.token,
				username: window.localStorage.username
			});
      }
      else {
        this.setState({game: Login, name: 'Login'});
      }
	}

	on_delete(msg) {
		if (msg.game !== undefined && msg.name !== undefined) {
			this.setState({game: Lobby, name: 'Lobby'});
		}
	}

  	on_welcome(msg) {
		window.sessionStorage.token = msg.token;
		window.localStorage.username = msg.username;
		this.setState({game: Lobby, name: 'Lobby'});
	}

    on_join(msg) {
        if (this.state.name !== msg.game) {
            this.setState({game: games[msg.game], name: msg.game});
        }
    }
}
