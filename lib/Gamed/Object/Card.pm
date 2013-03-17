package Gamed::Object::Card;

sub new {
    my ( $pkg, $value, $suit, ) = @_;
    bless { value => $value, suit => $suit }, $pkg;
}

sub TO_JSON {
	return $_[0]->{value} . $_[0]->{suit};
}
1;
