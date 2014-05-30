package Gamed::Player;

use JSON;

my $json = JSON->new->convert_blessed;

sub new {
    my $pkg = shift;
    my $self = bless $_[0], $pkg;
    $self->{handlers} = [ Gamed::Login->new() ];
	return $self;
}

sub handle {
    my ( $self, $msg_json ) = @_;
    my $msg = $json->decode($msg_json);
    my $cmd = $msg->{cmd};
    if ( !defined $self->{id} ) {
        $cmd = 'login';
    }
    for my $p (qw/before on after/) {
        for my $h ( @{ $self->{handlers} } ) {
            $h->handle( $self, $msg );
        }
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
