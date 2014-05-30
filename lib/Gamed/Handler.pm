package Gamed::Handler;

use Exporter 'import';
our @EXPORT = qw/before on after handle/;

sub before {
	_install('before', @_);
}

sub on {
	_install('on', @_);
}

sub after {
	_install('after', @_);
}

use Data::Dumper;
sub _install {
print Dumper \@_;
	my $pkg = caller(1);
	print "$pkg\n";
}

sub handle {
}

1;
