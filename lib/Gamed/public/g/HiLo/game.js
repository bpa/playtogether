$(function() {
	$('#pick').keypress(function(event) {
		if ( event.which == 13 ) {
			pick();
		}
	});
	$('#pick').focus();
});

function callback (msg) {
	console.log(msg);
	var r = $('#results');
	if (msg['guesses']) {
		r.val(msg['guesses'] + ': ' + msg['answer'] + "\n" + r.val());
	}
}
function pick() {
	console.log($('#pick'));
	console.log($('#pick').val());
	ws.send(JSON.stringify({guess: $('#pick').val()}));
	$('#pick').focus();
	$('#pick').select();
}
