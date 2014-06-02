package Gamed::Handler;

use Exporter 'import';
our @EXPORT = qw/before on after handle/;
my %handler;

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
	$handler{$pkg}{$when}{$cmd} = $code;
}

sub handle {
	my ($pkg, $handle, $player, $when, $msg) = @_;
	*isa = *{"$pkg\::ISA"};
	if (@isa) {
		my $parent = $isa[0];
		handle($parent, $handle, $player, $when, $msg);
	}
	my $p = $handler{$pkg}{$when};
	for my $cmd ($msg->{cmd}, '*') {
		print($pkg, " $when ", $msg->{cmd}, "\n") if $p->{$cmd};
		$p->{$cmd}($handle, $player, $msg) if $p->{$cmd};
	}
	handle(ref($handle->{state}), $handle->{state}, $player, $when, $msg) if defined $handle->{state};
}

1;
