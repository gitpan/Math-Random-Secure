#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
use Math::Random::Secure qw(srand irand);

my $seed = srand();
cmp_ok(length($seed), '==', 1024, 'seed is the right size');

my @sequence_one = map { irand() } (1..100);
srand($seed);
my @sequence_two = map { irand() } (1..100);
is_deeply(\@sequence_one, \@sequence_two, 
          'Same seed generates the same sequence');
