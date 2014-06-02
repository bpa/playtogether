package Gamed::DB;
$INC{'Gamed/DB.pm'} = 'Mocked';

sub login {
    my $args = shift;
    return {
        username => $args->{username},
        name     => $args->{name},
        avatar   => $args->{avatar} };
}

*create_user = \&login;

1;
