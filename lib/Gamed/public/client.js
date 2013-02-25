function noop (message) {}
var callback = noop;

var ws = new WebSocket('<%= url_for('websocket')->to_abs->scheme('ws') %>');
ws.onmessage = function (event) {
	var msg;
	try {
		msg = jQuery.parseJSON(event.data);
		if (msg['type'] == 'game') {
			callback(msg);
		}
		else {
			console.log(msg);
		}
	}
	catch (err) {
		console.log(err);
	}
};


