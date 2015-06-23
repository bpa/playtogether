package Gamed::Player;

use JSON::MaybeXS;
use Gamed::Login;

my $json = JSON::MaybeXS->new(convert_blessed => 1);
$json->allow_blessed;

sub new {
    my $pkg = shift;
    my $self = bless $_[0], $pkg;
    $self->{game} = Gamed::Login->new;
    return $self;
}

sub handle {
    my ( $self, $msg_json ) = @_;
	#print (($self->{user} ? $self->{user}{name} : 'undef'), " => $msg_json\n");
	my @messages = $json->incr_parse($msg_json);
	for my $msg (@messages) {
    	$self->{game}->handle( $self, $msg );
	}
}

sub send {
    my ( $self, $cmd, $msg ) = @_;
	return unless defined $self->{sock};
    $msg = { $cmd => $msg } unless ref($msg);
    $msg->{cmd} = $cmd;
    $self->{sock}->send( $json->encode($msg) );
}

sub err {
    my ( $self, $reason ) = @_;
    chomp $reason;
    $self->{sock}->send( $json->encode( { cmd => 'error', reason => $reason } ) );
}

1;
