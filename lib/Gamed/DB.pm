package Gamed::DB;

use DBI;
use Authen::Passphrase::SaltedDigest;

my $dbh = DBI->connect("dbi:SQLite:data") or die "Could not connect to database";
unless (
    $dbh->selectrow_arrayref(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name = 'users'") )
{
    $dbh->do(
        "create table users (username text PRIMARY KEY, passphrase, name text, avatar text)"
    );
}

sub login {
    my $param = shift;
    my $user  = $dbh->selectall_arrayref(
        "select * from users where username=?",
        { Slice => {} },
        $param->{username},
    );
    return unless @$user > 0;
    $user = $user->[0];
    my $ppr = Authen::Passphrase::SaltedDigest->from_rfc2307( delete $user->{passphrase} );
    return $ppr->match( $param->{passphrase} ) ? $user : ();
}

sub create_user {
    my $param = shift;
    my $ppr   = Authen::Passphrase::SaltedDigest->new(
        algorithm   => 'SHA-1',
        salt_random => 20,
        passphrase  => $param->{passphrase} );
    if (
        $dbh->do(
            "insert into users (username, passphrase, name, avatar) values (?,?,?,?)",
            {},
            $param->{username},
            $ppr->as_rfc2307,
            $param->{name},
            $param->{avatar} ) )
    {
        return {
            username => $param->{username},
            name     => $param->{name},
            avatar   => $param->{avatar},
        };
    }
    return;
}

1;
