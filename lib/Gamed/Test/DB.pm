package Gamed::DB;
$INC{'Gamed/DB.pm'} = 'Mocked';

sub login {
    my $args = shift;
	if (ref($args) ne 'HASH') {
		$args = { name => $args };
	}
    return {
        username => $args->{name},
        name     => $args->{name},
        avatar   => $args->{avatar} };
}

*create_user = \&login;
*get_user = \&login;

1;
