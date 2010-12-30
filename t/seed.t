#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;
use Test::Warn;
use Math::Random::Secure qw(srand irand);
use Math::Random::Secure::RNG;

my $seed = srand();
cmp_ok(length($seed), '==', 64, 'seed is the right size');

my @sequence_one = map { irand() } (1..100);
srand($seed);
my @sequence_two = map { irand() } (1..100);
is_deeply(\@sequence_one, \@sequence_two, 
          'Same seed generates the same sequence');

warning_like { Math::Random::Secure::RNG->new(seed_size => 4) }
             qr/Setting seed_size to less than/,
             "Using too-small of a seed size throws a warning";

my $int32 = 2**31;
warning_like { srand($int32) } qr/RNG seeded with a 32-bit integer/,
             "Using a 32-bit integer throws a warning";

my $short_seed = "abcde";
warning_like { srand($short_seed) } qr/Your seed is less than/,
             "Short seeds throw a warning";
