$(function() {
  $('#suit').buttonset();
  var spinner = $('#bid-spinner').spinner({
    min: 100,
    max: 200,
    step: 5,
  });
});
function callback (msg) {
	console.log(msg);
}
