#! /usr/bin/perl

use strict;
use warnings;

use JSON;
use File::Slurp;
use Config::Properties;
use Data::Dumper;
use Image::Magick;
use File::Basename;
use List::Util 'max';

my $game_dir = "lib/Gamed/public/g/SpeedRisk";
#make_themes('Classic');
make_themes('Ultimate');

sub make_themes {
    my $type  = shift;
    clean_dir($type);
    my $board = decode_json( read_file("$game_dir/$type/board.json") );
    for my $theme ( read_themes() ) {
		eval {
			my @images;
			my $bg = get_image_for_theme($theme, 'background');
			push @images, $bg;
			push @images, get_image_for_theme($theme, 'icon');
			for my $c ( @{ $board->{territories} } ) {
				push @images, make_themed_country( $type, $theme->{id}, $c, $bg );
			}
			pack_sheet( "$game_dir/$type", $theme->{id}, \@images );
		};
		print "Error making theme: $@\n" if $@;
    }
}

sub clean_dir {
	my $theme = shift;
    opendir( my $dh, "$game_dir/$theme" ) || die "can't opendir $game_dir/$theme: $!";
	for my $file (grep { !/^\./ && -f "$game_dir/$theme/$_" && !/^board.(png|json)$/ } readdir($dh)) {
		unlink "$game_dir/$theme/$file";
	}
	closedir($dh);
}

sub read_themes {
    opendir( my $dh, "resources/themes" ) || die "can't opendir resources/themes: $!";
    my @themes;
	for my $theme (grep { !/^\./ && -d "resources/themes/$_" } readdir($dh)) {
		eval {
			open my $fh, '<', "resources/themes/$theme/theme.properties" || return;
			my $props = Config::Properties->new();
			$props->load($fh);
			my $info = $props->getProperties;
			$info->{dir} = "resources/themes/$theme";
			$info->{id} = $theme;
			push @themes, $info;
			close $fh;
		};
		print "Error reading theme: $@\n" if $@;
	}
    closedir $dh;
	return @themes;
}

sub get_image_for_theme {
	my ($theme, $type) = @_;
	if ($theme->{"$type\-image"}) {
		my $im = Image::Magick->new;
		$im->Read($theme->{dir} . "/" . $theme->{"$type\-image"});
		return wrap_image($im, $theme->{id} . "_$type");
	}

    my $bg = Image::Magick->new( size => 24 . 'x' . 24 );
	my $c = $theme->{"$type\-color"};
	$c =~ s/([0-9a-z])/$1$1/ig if length($c) < 5;
	my ($alpha, $color) = $c =~ /^#?([0-9a-f]{2})?([0-9a-f]{6})$/i;
	$alpha ||= '00';

    $bg->Read("xc:#$color$alpha");
	return wrap_image($bg, $theme->{id} . "_$type");
}

sub make_themed_country {
    my ( $type, $theme, $country, $bg ) = @_;
	my $bg_image = $bg->{image};
	my ( $bg_h, $bg_w ) = $bg_image->Get( 'height', 'width' );
	my $image = Image::Magick->new;
	$image->Read("resources/$type" . "Risk/" . $country->{name} . ".png");
	my ( $h, $w ) = $image->Get( 'height', 'width' );
	for my $x ( 0 .. $w ) {
		my $bg_x = ($country->{sprite}{x} + $x) % $bg_w;
		for my $y ( 0 .. $h ) {
			my $bg_y = ($country->{sprite}{y} + $y) % $bg_h;
			my ($a) = $image->GetPixel( x => $x, y => $y, channel => 'alpha' );
			my @pixel = $bg_image->GetPixel( x => $bg_x, y => $bg_y );
			$pixel[3] = $a;
			$image->SetPixel( x => $x, y => $y, color => \@pixel );
		}
	}
	$image->Quantize(colorspace => 'rgb');
	return wrap_image($image, $theme . "_" . $country->{name});
}

sub wrap_image {
	my ($image, $file) = @_;
	return
          { filename         => $file,
            rotated          => 'false',
            trimmed          => 'false',
            spriteSourceSize => {
                x => 0,
                y => 0,
                w => $image->Get('width'),
                h => $image->Get('height'),
            },
            sourceSize => { w => $image->Get('width'), h => $image->Get('height'), },
            image      => $image,
          };
}

sub pack_sheet {
    my ($dir, $name, $img) = @_;
    my @images = sort {
        my $as = $a->{sourceSize};
        my $bs = $b->{sourceSize};
        ( $bs->{h} > $bs->{w} ? $bs->{h} : $bs->{w} )
          <=>
		( $as->{h} > $as->{w} ? $as->{h} : $as->{w} )
    } @$img;
    my $size;
    for my $i (@images) {
        $size += $i->{sourceSize}{h} * $i->{sourceSize}{w};
    }

    my $width = 16;
    while ( $width**2 < $size ) {
        $width *= 2;
    }

    while (1) {
        eval { pack_images( $width, \@images ); };
        last unless $@;
        $width *= 2;
    }

    write_sheet( $dir, $name, $width, \@images );
}

sub pack_images {
    my ( $width, $images ) = @_;
    my @space = [ { h => $width, w => $width, full => 0, x => 0, y => 0 } ];
	my @display;
    for my $i (@$images) {
        for my $y (0 .. $#space) {
			for my $x (0 .. $#{ $space[$y] }) {
				goto FOUND if place($i, $x, $y, \@space);
			}
		}
		die "Can't place image\n";
		FOUND:
		push @display, $i;
		#display($width, \@space, \@display);
    }
}

sub place {
	my ($image, $x, $y, $space) = @_;
	my ($dx, $dy) = ($x, $y);
	my ($w, $h) = ($image->{sourceSize}{w}, $image->{sourceSize}{h});
	my ($aw, $ah) = (0, 0);

	#Check to see if cells are used
	while (1) {
		return if $dx > $#$space;
		my $cell = $space->[$dx][$y];
		return if $cell->{full};
		$aw += $cell->{w};
		last if $aw >= $w;
		$dx++;
	}
	while (1) {
		return if $dy > $#{$space->[$x]};
		my $cell = $space->[$x][$dy];
		return if $cell->{full};
		$ah += $cell->{h};
		last if $ah >= $h;
		$dy++;
	}

	#Split cells if image doesn't fill space
	if ( $ah > $h ) {
		my $diff = $ah - $h;
		for my $row (@$space) {
			my $c = $row->[$dy];
			$c->{h} -= $diff;
			splice(
				@$row, $dy + 1, 0,
				{   w    => $c->{w},
					h    => $diff,
					full => $c->{full},
					x    => $c->{x},
					y    => $c->{y} + $c->{h}} );
		}
	}

	if ( $aw > $w ) {
		my $diff = $aw - $w;
		my $row  = $space->[$dx];
		my @new_row;
		for my $c (@$row) {
			$c->{w} = $c->{w} - $diff;
			push @new_row,
			  { w    => $diff,
				h    => $c->{h},
				full => $c->{full},
				x    => $c->{x} + $c->{w},
				y    => $c->{y}};
		}
		splice( @$space, $dx + 1, 0, \@new_row );
	}

	#Mark space as used
	my $cell = $space->[$x][$y];
	$image->{frame} = { x => $cell->{x}, y => $cell->{y}, w => $w, h => $h };
	for my $row_id ( $x .. $dx ) {
		my $row = $space->[$row_id];
		for my $col_id ( $y .. $dy ) {
			my $cell = $row->[$col_id];
			$cell->{full} = 1;
		}
	}

	return 1;
}

sub write_sheet {
    my ( $dir, $theme, $width, $images ) = @_;

    my (%frames);
    my ( $max_x, $max_y ) = ( 0, 0 );
    my $image = Image::Magick->new( size => $width . 'x' . $width );
    $image->Read('NULL:black');
    for my $i (@$images) {
        my $mask = delete $i->{image};
        my ($base) = delete $i->{filename};
        $image->Composite(
            image => $mask,
            x     => $i->{frame}{x},
            y     => $i->{frame}{y} );
        $frames{$base} = $i;
        $max_x = max( $max_x, $i->{frame}{x} + $i->{frame}{w} );
        $max_y = max( $max_y, $i->{frame}{y} + $i->{frame}{h} );
    }
    $image->Crop( width => next_square($max_x), height => next_square($max_y) );
    $image->Write("$dir/$theme.png");
    write_file(
        "$dir/$theme.json",
        to_json (
            {   frames => \%frames,
                meta   => {
                    image   => "$dir/$theme.png",
                    format  => "RGBA8888",
                    size    => { w => $width, h => $width },
                    scale   => 1,
                } } ) );
}

sub next_square {
	my $i = shift;
	my $s = 2;
	while ($s < $i) {
		$s *= 2;
	}
	return $s;
}

