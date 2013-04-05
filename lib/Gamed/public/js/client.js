ws.onmessage = function (event) {
	var msg;
	try {
		msg = jQuery.parseJSON(event.data);
		if (msg['cmd'] == 'chat') {
			var chat = $('#chat')
			chat.val(chat.val() + msg['user'] + ': ' + msg['text'])
		}
		else {
			callback(msg);
		}
	}
	catch (err) {
		console.log(err);
	}
};

function do_chat() {
	var input = $('#chat_input');
	ws.send(JSON.stringify({cmd: 'chat', text: input.val()}));
	input.val('');
}
