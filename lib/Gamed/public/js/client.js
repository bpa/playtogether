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

function show_players(seats, msg) {
    var me = msg['player'];
    for (i=0; i<msg['players'].length; i++) {
        var pos = (4 - me + i) % seats;
        var player = msg['players'][i];
        if (pos != 0 && player) {
            $('#player'+pos+' .avatar').css('backgroundImage', 'url('+player['avatar']+')');
            $('#player'+pos+' .player-name').text(player['name']);
        }
    }
}
