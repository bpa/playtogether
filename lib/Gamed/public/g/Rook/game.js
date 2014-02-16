$(function() {
  $('#suit').buttonset();
  var spinner = $('#bid-spinner').spinner({
    min: 100,
    max: 200,
    step: 5,
  });

  $('#start').button().click(start_now);
});

function callback (msg) {
	console.log(msg);
    if (msg['cmd'] == 'join') {
        show_players(4, msg);
    }
	if ('dealing' in msg) {
		$('#waiting-tab').hide();
		$('#bidding-tab').show();
	}
}

function start_now () {
	ws.send(JSON.stringify({ 'start': 'now' }));
}

