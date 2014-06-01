package Gamed::Test::DB;

package Gamed::DB;
$INC{'Gamed/DB.pm'} = 'Mocked';

sub login {
print Dumper \@_;
    my $args = shift;
    return {
        username => $args->{username},
        name     => $args->{name},
        avatar   => $args->{avatar} };
}

*create_user = \&login;

1;
