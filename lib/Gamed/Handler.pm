package Gamed::Handler;

use Exporter 'import';
our @EXPORT = qw/before on after handle/;
my %handler;

sub before {
    _install( 'before', @_ );
}

sub on {
    _install( 'on', @_ );
}

sub after {
    _install( 'after', @_ );
}

sub _install {
    my ( $when, $cmd, $code ) = @_;
    my $pkg = caller(1);
    $handler{$pkg}{$when}{$cmd} = $code;
}

sub handle {
    my ( $obj, $player, $msg ) = @_;
    for my $p (qw/before on after/) {
        _handle( ref($obj), $obj, $player, $p, $msg );
    }
}

sub _handle {
    my ( $pkg, $obj, $player, $when, $msg ) = @_;
    *isa = *{"$pkg\::ISA"};
    if (@isa) {
        my $parent = $isa[0];
        _handle( $parent, $obj, $player, $when, $msg );
    }
    my $name = $player->{user} ? $player->{user}{name} : 'undef';
    my $p = $handler{$pkg}{$when};
    for my $cmd ( $msg->{cmd}, '*' ) {
        print( $pkg, " $when ", $msg->{cmd}, " ($name)\n" ) if $p->{$cmd};
        $p->{$cmd}( $obj, $player, $msg ) if $p->{$cmd};
    }
    _handle( ref( $obj->{state} ), $obj->{state}, $player, $when, $msg )
      if defined $obj->{state} && ref($obj) eq $pkg;
}

1;
