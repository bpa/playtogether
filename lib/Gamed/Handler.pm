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

sub _install {
	my ($when, $cmd, $code) = @_;
	my $pkg = caller(1);
	*h = *{"$pkg\::_h"};
	$h{$when}{$cmd} = $code;
}

sub handle {
	my ($pkg, $self, $player, $when, $msg) = @_;
	*isa = *{"$pkg\::ISA"};
	if (@isa) {
		my $parent = $isa[0];
		$parent->handle($self, $player, $when, $msg);
	}
	*h = *{"$pkg\::_h"};
	my $p = $h{$when};
	return unless $p;
	my $cmd = $msg->{cmd};
	$p->{$cmd}($self, $player, $msg) if $p->{$cmd};
	$p->{'*'}($self, $player, $msg) if $p->{'*'};
}

1;
