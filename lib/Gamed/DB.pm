use DBI;
use Mojolicious::Lite;
use Data::UUID;
use Authen::Passphrase::SaltedDigest;

my $uuid = Data::UUID->new;
my $dbh = DBI->connect("dbi:SQLite:data") or die "Could not connect to database";
unless ( $dbh->selectrow_arrayref("SELECT 1 FROM sqlite_master WHERE type='table' AND name = 'user'") ) {
    $dbh->do("create table user (username text PRIMARY KEY, passphrase, name text, avatar text)");
}

helper login => sub {
    my $self = shift;
    my $user = $dbh->selectall_arrayref( "select * from user where username=?", { Slice => {} }, $self->param('username'), );
    return unless @$user > 0;
    $user = $user->[0];
    my $ppr = Authen::Passphrase::SaltedDigest->from_rfc2307( delete $user->{passphrase} );
    return $ppr->match($self->param('passphrase')) ? $user : ();
};

helper create_user => sub {
    my $self = shift;
    my $ppr = Authen::Passphrase::SaltedDigest->new(
        algorithm   => 'SHA-1',
        salt_random => 20,
        passphrase  => $self->param('passphrase') );
    if (
        $dbh->do(
            "insert into user (username, passphrase, name, avatar) values (?,?,?,?)",
            {}, $self->param('username'),
            $ppr->as_rfc2307, $self->param('name'), $self->param('avatar') ) )
    {
        return { username => $self->param('username'), name => $self->param('name'), avatar => $self->param('avatar') };
    }
    return;
};

1;
