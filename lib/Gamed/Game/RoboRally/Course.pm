package Gamed::Game::RoboRally::Course;

use strict;
use warnings;
use JSON::MaybeXS;
use File::Slurp;
use File::Spec::Functions 'catdir';
use List::Util qw/min reduce sum/;
use Gamed::Game::RoboRally::Pieces;

my $json              = JSON::MaybeXS->new;
my %rotations         = ( r => 1, u => 2, l => 3 );
my @rotations         = qw/_ r u l/;
my @movement          = ( -1, 1, 1, -1 );
my @walls             = ( 1, 2, 4, 8 );
my %conveyor_rotation = (
    'r' => [ 0, 1, 0, 0 ],
    'l' => [ 0, 0, 0, 3 ],
    '^' => [ 0, 1, 0, 3 ] );

sub new {
    my ( $pkg, $name ) = @_;
    my $text = read_file( catdir( $Gamed::public, "g", "RoboRally", "courses", "$name.json" ) );
    die "No course named " . $name . " known" unless $text;
    my $course = $json->decode($text);
    my %self   = (
        course => $course,
        tiles  => $course->{tiles},
        pieces => $course->{pieces},
        w      => $course->{width},
        h      => $course->{height} );

    for my $y ( 0 .. $#{ $course->{tiles} } ) {
        my $row = $course->{tiles}[$y];
        for my $x ( 0 .. $#$row ) {
            my $tile = $row->[$x];
            $tile->{pieces} = [];
            $tile->{w} ||= 0;
            $tile->{o} ||= 0;
            $tile->{t} ||= 'floor';
            if ( $tile->{t} =~ /^[1-8]$/o ) {
                $self{start}{ $tile->{t} } = [ $x, $y ];
            }
        }
    }

    for my $p ( values %{ $course->{pieces} } ) {
        if ( $p->{type} eq 'flag' ) {
            $p = Gamed::Game::RoboRally::Flag->new( $p->{flag}, $p->{x}, $p->{y} );
        }
        else {
            $p = Gamed::Game::RoboRally::Piece->new( $p->{id}, $p->{type}, $p->{x}, $p->{y}, $p->{o} || 0, $p->{solid} || 0 );
        }
        push @{ $course->{tiles}[ $p->{y} ][ $p->{x} ]{pieces} }, $p;
    }

    bless \%self, $pkg;
}

sub remove(&$) {
    my $f = \&{ shift @_ };
    for my $ind ( 0 .. $#{$_[0]} ) {
        local $_ = $_[0][$ind];
        if ($f->()) {
            return splice @{$_[0]}, $ind, 1;
        }
    }
    return;
}

sub died {
    my ($self, $bot) = @_;
    $bot->{lives}--;
    $bot->{active} = 0;
    $self->move($bot, 0, 0);
}

sub add_bot {
    my ( $self, $bot ) = @_;
    my $piece = Gamed::Game::RoboRally::Bot->new( $bot, 0, 0, N );
    $self->{course}{pieces}{$bot} = $piece;
    push @{$self->{tiles}[0][0]{pieces}}, $piece;
}

sub place {
    my ( $self, $bot, $num ) = @_;
    my $loc = $self->{start}{$num};
    $bot->{archive}{loc}{x} = $loc->[0];
    $bot->{archive}{loc}{y} = $loc->[1];
    $self->move($bot, @$loc);
    $bot->{active} = 1;
}

sub move {
    my ($self, $piece, $x, $y) = @_;
    my $tile = $self->{tiles}[$piece->{y}][$piece->{x}];
    remove { $_->{id} eq $piece->{id} } $tile->{pieces};
    push @{$self->{tiles}[$y][$x]{pieces}}, $piece;
    $piece->{x} = $x;
    $piece->{y} = $y;
}

sub tile {
    my ($self, $x, $y) = @_;
    return if $x < 0 || $y < 0 || $x >= $self->{w} || $y >= $self->{h};
    return $self->{tiles}[$y][$x];
}

sub pieces { return $_[0]->{course}{pieces} }

sub piece { return $_[0]->{course}{pieces}{$_[1]} }

sub do_movement {
    my ( $self, $register, $cards ) = @_;
    my @moves;
    for my $c (@$cards) {
        my ( $action, $priority ) = $c->[1][0] =~ /^(.)(\d+)$/o;
        push @moves, [ $c->[0], $priority, $action ];
    }
    @moves = map { $self->do_move( $register, @$_ ) } sort { $b->[1] <=> $a->[1] } @moves;
    return \@moves;
}

sub do_move {
    my ( $self, $register, $piece, $priority, $move, $optional ) = @_;
    if ( $move =~ /[rlu]/o ) {
        $piece->{o} = ( $piece->{o} + $rotations{$move} ) % 4;
        return [ { piece => $piece->{id}, rotate => $move } ];
    }

    my $dir = $piece->{o};
    if ( $move eq 'b' ) {
        $dir  = ( $dir + 2 ) % 4;
        $move = 1;
    }
    $self->_push( $move, $dir, $piece->{x}, $piece->{y} );
}

sub _push {
    my ( $self, $move, $dir, $x, $y ) = @_;
    my $d = $movement[$dir];
    my ( $xy, $z ) = $dir % 2 == 0 ? qw/y x/ : qw/x y/;
    my ( $loc, $track ) = $dir % 2 == 0 ? ( $y, $x ) : ( $x, $y );

    my @actions;
    my @pieces = grep { $_->{solid} && $_->{$z} == $track } values %{ $self->{pieces} };

    while ($move) {
        my $piece = remove { $_->{$xy} == $loc } \@pieces;
        $loc += $d;
        unless ( $piece ) {
            $move--;
            next;
        }
        $move = $self->max_movement( $piece->{x}, $piece->{y}, $move, $dir, \@pieces );
        if ($move) {
            my $tile = $self->{tiles}[ $piece->{y} ][ $piece->{x} ];
            remove { $_->{id} eq $piece->{id} } $tile->{pieces};
            $piece->{$xy} += $d * $move;
            my %action = ( piece => $piece->{id}, move => $move, dir => $dir );
            $tile = $self->{tiles}[ $piece->{y} ][ $piece->{x} ];
            push @{$tile->{pieces}}, $piece;
            if (   $piece->{x} < 0
                || $piece->{y} < 0
                || $piece->{x} >= $self->{w}
                || $piece->{y} >= $self->{h}
                || $tile->{t} eq 'pit' )
            {
                $self->died($piece);
                $action{die} = 'fall';
            }
            push @actions, \%action;
        }
    }

    return @actions ? \@actions : ();
}

sub max_movement {
    my ( $self, $x, $y, $move, $dir, $pieces ) = @_;
    my $front = $walls[$dir];
    my $back  = $walls[ ( $dir + 2 ) % 4 ];
    my @d     = ( 0, 0 );
    $d[ $dir % 2 ] = $movement[$dir];
    my $tile = $self->{tiles}[$y][$x];
    my ( $wall, $pit ) = ( 0, 0 );
    while ( $wall < $move || $pit < $move ) {
        return $wall if $tile->{w} & $front;
        $y += $d[0];
        $x += $d[1];
        if ( $x < 0 || $y < 0 || $x >= $self->{w} || $y >= $self->{h} ) {
            return min ++$pit, $move;
        }
        $tile = $self->{tiles}[$y][$x];
        return $wall if $tile->{w} & $back;
        $pit++;
        $wall++ unless grep { $_->{x} == $x && $_->{y} == $y } @$pieces;
        return min $move, $pit unless $tile;
        return min $move, $pit if $tile->{t} eq "pit";
    }
    return $move;
}

sub do_express_conveyors {
    my ( $self, $register ) = @_;
    return $self->move_conveyors('conveyor2');
}

sub do_conveyors {
    my ( $self, $register ) = @_;
    return $self->move_conveyors('conveyor');
}

sub move_conveyors {
    my ( $self, $type ) = @_;
    my ( @new, %actions, @replace );
    for my $p ( values %{ $self->{pieces} } ) {
        next unless $p->{active};
        my $x = $p->{x};
        my $y = $p->{y};
        my $tile = $self->{tiles}[$y][$x];
        my $dir  = $tile->{o};
        if ( $tile->{t} =~ $type ) {
            next if $tile->{w} & $walls[$dir];
            my @d = ( 0, 0 );
            $d[ $dir % 2 ] = $movement[$dir];
            $y += $d[0];
            $x += $d[1];
            if ( $x < 0 || $y < 0 || $x >= $self->{w} || $y >= $self->{h} ) {
                $actions{ $p->{id} } = { piece => $p->{id}, move => 1, dir => $dir, die => 'fall', x => $x, y => $y };
                next;
            }
            $tile = $self->{tiles}[$y][$x];
            my $next_dir = $tile->{o};
            next if $tile->{t} =~ $type && $next_dir == ( $dir + 2 ) % 4;
            next if $tile->{w} & $walls[ ( $dir + 2 ) % 4 ];
            if ( $tile->{t} eq "pit" ) {
                $actions{ $p->{id} } = { piece => $p->{id}, move => 1, dir => $dir, die => 'fall', x => $x, y => $y };
                next;
            }
        }
        else {
            next unless $p->{solid};
            $new[$x][$y] ||= $p;
        }
        if ( $p->{solid} && $new[$x][$y] ) {
            my @replace = ( $p, $new[$x][$y] );
            while (@replace) {
                my $o = shift @replace;
                my $r = $new[ $o->{x} ][ $o->{y} ];
                delete $actions{ $o->{id} };
                $new[ $o->{x} ][ $o->{y} ] = $o;
                if ( $r && $r->{id} ne $o->{id} ) {
                    push @replace, $r;
                }
            }
            next;
        }
        $actions{ $p->{id} } = { piece => $p->{id}, move => 1, dir => $dir, x => $x, y => $y };
        my ($r) = $tile->{t} =~ /conveyor2?([rl^])$/;
        my $table = $r ? $conveyor_rotation{$r} : undef;
        if ($table) {
            my $side = ( 4 + $tile->{o} - $dir ) % 4;
            $actions{ $p->{id} }{rotate} = $rotations[ $table->[$side] ] if $table->[$side];
            $actions{ $p->{id} }{o} = ( 4 + $p->{o} + $table->[$side] ) % 4;
        }
        if ( $p->{solid} ) {
            $new[$x][$y] = $p;
        }
    }
    for my $p ( values %actions ) {
        my $piece = $self->{pieces}{ $p->{piece} };
        my $x = delete $p->{x};
        my $y = delete $p->{y};
        if ($p->{die}) {
            $self->died($piece);
            next;
        }
        $self->move($piece, $x, $y);
        $piece->{o} = delete $p->{o} || $piece->{o};
    }
    return [ %actions ? [ values %actions ] : () ];
}

sub do_pushers {
    my ( $self, $register ) = @_;
    my @actions;
    for my $p ( values %{ $self->{pieces} } ) {
        next unless $p->{solid};
        my $tile = $self->{tiles}[ $p->{y} ][ $p->{x} ];
        next unless $tile->{t} eq 'pusher';
        next unless $tile->{r} & 1 << ( $register - 1 );
        my $actions = $self->_push( 1, $tile->{o}, $p->{x}, $p->{y} );
        push @actions, @$actions if $actions;
    }
    return @actions ? \@actions : ();
}

sub do_gears {
    my ( $self, $register ) = @_;
    my @actions;
    for my $p ( values %{ $self->{pieces} } ) {
        next unless $p->{solid};
        my $tile = $self->{tiles}[ $p->{y} ][ $p->{x} ];
        my ($dir) = $tile->{t} =~ /^gear_([rl])/;
        next unless $dir;
        $p->{o} = ( $p->{o} + $rotations{$dir} ) % 4;
        push @actions, { piece => $p->{id}, rotate => $dir, o => $p->{o} };
    }
    return [ @actions ? \@actions : () ];
}

sub do_lasers {
    my ( $self, $register ) = @_;
    return [];
}

sub available_placements {
    my ($self, $x, $y) = @_;
    my %valid;
    my $size = 0;
    my @ind = (0);
    $self->add_if_valid(\%valid, $x, $y);
    while (!%valid) {
        $size++;
        for my $i (@ind) {
            $self->add_if_valid(\%valid, $x + $size, $y + $i);
            $self->add_if_valid(\%valid, $x - $size, $y + $i);
        }
        push @ind, -$size, $size;
        for my $i (@ind) {
            $self->add_if_valid(\%valid, $x + $i, $y + $size);
            $self->add_if_valid(\%valid, $x + $i, $y - $size);
        }
    }
    return \%valid;
}

sub add_if_valid {
    my ($self, $valid, $x, $y) = @_;
    return if $x < 0 || $y < 0 || $x >= $self->{w} || $y >= $self->{h};
    my $tile = $self->{tiles}[$y][$x];
    return if $tile->{t} eq 'pit';
    for my $p ( @{ $tile->{pieces} } ) {
        return if $p->{solid} && $p->{active};
    }
    my $seen = $self->line_of_sight($x, $y);
    return unless sum(@$seen);

    $valid->{$x}{$y} = $seen;
}

sub line_of_sight {
    my ($self, $x, $y) = @_;

    return [
        $self->look( $x, $y,  0, -1 ),
        $self->look( $x, $y,  1,  0 ),
        $self->look( $x, $y,  0,  1 ),
        $self->look( $x, $y, -1,  0 ),
    ];
}

sub look {
    my ($self, $x, $y, $dx, $dy) = @_;
    for my $d ( 1 .. 3 ) {
        $x += $dx;
        $y += $dy;
        return 1 if $x < 0 || $y < 0 || $x >= $self->{w} || $y >= $self->{h};
        for my $p ( @{ $self->{tiles}[$y][$x]{pieces} } ) {
            return if $p->{type} eq 'bot';
            return 1 if $p->{solid};
        }
    }
    return 1;
}

sub TO_JSON {
    return $_[0]->{course};
}

1;
