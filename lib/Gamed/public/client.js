ws.onmessage = function (event) {
	var msg;
	try {
		msg = jQuery.parseJSON(event.data);
		switch (msg['cmd']) {
			case 'game':
				document.getElementById("game").contentWindow.callback(msg);
				break;
			case 'chat':
				var chat = $('#chat')
				chat.val(chat.val() + msg['user'] + ': ' + msg['text'])
				break;
			default:
				console.log(msg);
		}
	}
	catch (err) {
		console.log(err);
	}
};

function game_message(msg) {
	msg['cmd'] = 'game';
	ws.send(JSON.stringify(msg));
}

function do_chat() {
	var input = $('#chat_input');
	ws.send(JSON.stringify({cmd: 'chat', text: input.val()}));
	input.val('');
}
