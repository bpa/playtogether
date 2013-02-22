use Test::More;
use Test::Mojo;

use FindBin;
require "$FindBin::Bin/../echo.pl";

# Test echo web service
my $t = Test::Mojo->new;
$t->websocket_ok('/echo')
->send_ok('Hello Mojo!')
->message_ok
->message_is('echo: Hello Mojo!')
->finish_ok;

done_testing();
