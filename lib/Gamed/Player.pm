package Gamed::Player;

use JSON;

my $json = JSON->new->convert_blessed;

sub new {
    my $pkg = shift;
    bless $_[0], $pkg;
}

sub send {
    my ( $self, $msg ) = @_;
    $self->{sock}->send( $json->encode($msg) );
}

sub err {
    my ( $self, $reason ) = @_;
    chomp $reason;
    $self->{sock}->send( $json->encode( { cmd => 'error', reason => $reason } ) );
}

1;
