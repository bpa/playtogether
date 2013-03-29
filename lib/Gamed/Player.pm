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
	chomp $reason;
    $self->{sock}->send( $json->encode({ cmd => 'error', reason => $reason }));
}

1;
