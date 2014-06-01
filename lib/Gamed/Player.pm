package Gamed::Player;

use JSON;
use Gamed::Login;

my $json = JSON->new->convert_blessed;

sub new {
    my $pkg = shift;
    my $self = bless $_[0], $pkg;
    $self->{game} = Gamed::Login->new;
    return $self;
}

sub handle {
    my ( $self, $msg_json ) = @_;
    my $msg = $json->decode($msg_json);
    for my $p (qw/before on after/) {
		#These aren't put in a temporary variable because the game can change in a handler
        ref($self->{game})->handle( $self->{game}, $self, $p, $msg );
        ref($self->{game}{state})->handle( $self->{game}{state}, $self, $p, $msg ) if $self->{game}{state};
    }
}

sub send {
    my ( $self, $cmd, $msg ) = @_;
    $msg->{cmd} = $cmd;
    $self->{sock}->send( $json->encode($msg) );
}

sub err {
    my ( $self, $reason ) = @_;
    chomp $reason;
    $self->{sock}->send( $json->encode( { cmd => 'error', reason => $reason } ) );
}

1;
