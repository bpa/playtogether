package Gamed::Player;

use JSON;

my $json = JSON->new->convert_blessed;

sub new {
    my $pkg = shift;
    bless $_[0], $pkg;
}

sub send {
    shift->{sock}->send( $json->encode( $_[0] ) );
}

sub err {
    my ( $self, $reason ) = @_;
    $self->{sock}->send( $json->encode({ cmd => 'error', reason => $reason }));
}

sub game {
    my ( $self, $msg ) = @_;
    $msg->{cmd} = 'game';
    $self->{sock}->send( $json->encode($msg));
}

1;
