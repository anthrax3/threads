package Threads::Helper::Date;

use strict;
use warnings;

use parent 'Tu::Helper';

use Time::Piece;

sub format {
    my $self = shift;
    my ($epoch) = @_;

    return Time::Piece->new($epoch)->strftime('%Y-%m-%d %H:%M');
}

sub is_distant_update {
    my $self = shift;
    my ($object) = @_;

    my $created = $object->{created};
    my $updated = $object->{updated};

    return 0 unless $updated;

    return $updated - $created > 15 * 60;
}

1;
