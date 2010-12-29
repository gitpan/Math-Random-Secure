package inc::Test::RandomWalk::Int;
use strict;
use warnings;
use base qw(Statistics::Test::RandomWalk);
use Math::BigFloat;

sub new {
    my $invo = shift;
    my $self = $invo->SUPER::new(@_);
    $self->{limit} = shift;
    return $self;
}

sub test {
    my ($self, $num_bins) = @_;
    my $data = $self->{data};
    my $limit = $self->{limit};

    my $step = $limit / $num_bins;
    my @quantiles;
    foreach my $bin (1..$num_bins) {
        push(@quantiles, $bin * $step);
    }

    my @bins = (0) x $num_bins;
    my $numbers = 0;

    my $calls = $self->{n};
    foreach (1..$calls) {
        my $item = $data->();
        $numbers++;
        foreach my $i (0..$#quantiles) {
            if ($item <= $quantiles[$i]) {
                $bins[$_]++ foreach $i..$#quantiles;
                last;
            }
        }
    }

    my @expected_smaller = map { Math::BigFloat->new($numbers * ($_ / $limit)) }
                               @quantiles;

    @quantiles = map { sprintf('%u', $_) } @quantiles;
    return (\@quantiles, \@bins, \@expected_smaller);
}

__PACKAGE__;
