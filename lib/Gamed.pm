package Gamed;

use EV;
use AnyEvent;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use JSON::Any;
use File::Find;

my $json = JSON::Any->new;

our %games;
our %game_instances;
our %player;

opendir DIR, catdir( dirname(__FILE__) , 'Gamed', 'Game' );
for my $file (readdir DIR) {
	my ($module) = $file =~ /(.*)\.pm/;
	next unless $module;
    eval "CORE::require Gamed::Game::$module";
	$games{$module} = bless [], "Gamed::Game::$module";
}
closedir(DIR);

sub on_connect {
	my ($name, $sock) = @_;
	$player{$name} = $sock;
}

sub on_message {
	my ($name, $msg) = @_;
	my $sock = $player{$name};
   	if ($msg->{type} == 'chat') {
		$sock->send(
			$json->objToJson({
					type => 'chat',
					text => $msg->{'text'},
					user => $name,
				}));
    }
}

sub on_disconnect {
	my $name = shift;
	delete $player{$name};
}

1;
