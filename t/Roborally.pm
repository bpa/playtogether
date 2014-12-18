package T::Roborally;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw/N E S W bot archive flag/;

use constant N => 0;
use constant E => 1;
use constant S => 2;
use constant W => 3;

sub bot {
    my ( $id, $x, $y, $o ) = @_;
    return $id => { id => $id, type => 'bot', x => $x, y => $y, o => $o, flag => 0, solid => 1 };
}

sub archive {
    my ( $id, $x, $y, $o ) = @_;
    return "$id\_archive" => { id => "$id\_archive", type => 'archive', x => $x, y => $y };
}

sub flag {
    my ( $id, $x, $y ) = @_;
    return "flag_$id" => { id => "flag_$id", type => 'flag', x => $x, y => $y, flag => $id };
}

1;
