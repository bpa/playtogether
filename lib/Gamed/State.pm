package Gamed::State;

use Carp;
use Module::Pluggable::Object;

sub import {
    Module::Pluggable::Object->new( search_path => shift, require => 1, inner => 0 )->plugins;
}

sub new {
    my ( $pkg, %opts ) = @_;
    my $self = bless \%opts, $pkg;
    $self->{name} ||= ( split( /::/, $pkg ) )[-1];
    confess "Missing next state" unless $self->{next};
    return $self;
}

sub clone {
    my $self = shift;
    return bless {%$self}, ref($self);
}

sub on_enter_state { }
sub on_leave_state { }

1;
