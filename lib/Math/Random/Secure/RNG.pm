package Math::Random::Secure::RNG;
BEGIN {
  $Math::Random::Secure::RNG::VERSION = '0.04';
}
use Any::Moose;
use Math::Random::ISAAC;
use Crypt::Random::Source::Factory;
use constant ON_WINDOWS => $^O =~ /Win32/i ? 1 : 0;
use if ON_WINDOWS, 'Crypt::Random::Source::Strong::Win32';

has seeder => (is => 'ro', isa => 'Crypt::Random::Source::Base', 
               lazy_build => 1);
# Default to a 512-bit key, which should be impossible to break. I wrote
# to the author of ISAAC and he said it's fine to not use a full 256
# integers to seed ISAAC.
has seed_size => (is => 'ro', isa => 'Int', default => 64);
has seed => (is => 'ro', isa => 'Str', lazy_build => 1,
             clearer => 'clear_seed', predicate => 'has_seed');
has rng => (is => 'ro', isa => 'Object', lazy_build => 1);

sub BUILD {
    my ($self) = @_;

    if ($self->has_seed) {
        my $seed = $self->seed;
        if (length($seed) < 8) {
            warn "Your seed is less than 8 bytes (64 bits). It could be"
                 . " easy to crack";
        }
        # If it looks like we were seeded with a 32-bit integer, warn the
        # user that they are making a dangerous, easily-crackable mistake.
        # We do this during BUILD so that it happens during srand() in
        # Math::Secure::RNG.
        elsif (length($seed) <= 10 and $seed =~ /^\d+$/) {
            warn "RNG seeded with a 32-bit integer, this is easy to crack";
        }
    }
    elsif ($self->seed_size < 8) {
        warn "Setting seed_size to less than 8 is not recommended";
    }
}

sub _build_seeder {
    my $factory = Crypt::Random::Source::Factory->new();
    # On Windows, we want to always pick Crypt::Random::Source::Strong::Win32,
    # which this will do.
    if (ON_WINDOWS) {
        return $factory->get_strong;
    }

    my $source = $factory->get;
    # Never allow rand() to be used as a source, it cannot possibly be
    # cryptographically strong with 2^15 or 2^32 bits for its seed.
    if ($source->isa('Crypt::Random::Source::Weak::rand')) {
        $source = $factory->get_strong;
    }
    return $source;
}

sub _build_seed {
    my ($self) = @_;
    return $self->seeder->get($self->seed_size);
}

sub _build_rng {
    my ($self) = @_;
    my @seed_ints = unpack('L*', $self->seed);
    my $rng = Math::Random::ISAAC->new(@seed_ints);
    # One part of having a cryptographically-secure RNG is not being
    # able to see the seed in the internal state of the RNG.
    $self->clear_seed;
    return $rng;
}

sub generate {
    my ($self) = @_;
    return $self->rng->irand();
}

__PACKAGE__

__END__

=head1 NAME

Math::Random::Secure::RNG - The underlying PRNG, as an object.

=head1 SYNOPSIS

 use Math::Random::Secure::RNG;
 my $rng = Math::Random::Secure::RNG->new();
 my $int = $rng->generate();

=head1 DESCRIPTION

This represents a random number generator, as an object.

Generally, you shouldn't have to worry about this, and you should just use
L<Math::Random::Secure>. But if for some reason you want to modify how the
random number generator works or you want an object-oriented interface
to a random-number generator, you can use this.

Math::Random::Secure::RNG uses L<Any::Moose>, meaning that it has a
C<new> method that works like L<Mouse> or L<Moose> modules work.

=head1 METHODS

=head2 generate

Generates a random unsigned 32-bit integer.

=head1 ATTRIBUTES

These are all options that can be passed to C<new()> or called as methods
on an existing object.

=head2 rng

The underlying random number generator. Defaults to an instance of
L<Math::Random::ISAAC>.

=head2 seed

The random data used to seed L</rng>, as a string of bytes. This should
be large enough to properly seed L</rng>. This means I<minimally>, it
should be 8 bytes (64 bits) and more ideally, 32 bytes (256 bits) or 64 
bytes (512 bits). For an idea of how large your seed should be, see 
L<http://burtleburtle.net/bob/crypto/magnitude.html#brute> for information
on how long it would take to brute-force seeds of each size.

Note that C<seed> should not be an integer, but a B<string of bytes>.

It is very important that the seed be large enough, and also that the seed
be very random. B<There are serious attacks possible against random number
generators that are seeded with non-random data or with insufficient random
data.>

By default, we use a 512-bit (64 byte) seed. If 
L<Moore's Law|http://en.wikipedia.org/wiki/Moore's_law> continues to hold
true, it will be approximately 1000 years before computers can brute-force a
512-bit (64 byte) seed at any reasonable speed (and physics suggests that
computers will never actually become that fast, although there could always
be improvements or new methods of computing we can't now imagine, possibly
making Moore's Law continue to hold true forever).

If you pass this to C<new()>, L</seeder> and L</seed_size> will be ignored.

=head2 seeder

An instance of L<Crypt::Random::Source::Base> that will be used to
get the seed for L</rng>.

=head2 seed_size

How much data (in bytes) should be read using L</seeder> to seed L</rng>.
Defaults to 64 bytes (which is 512 bits).

See L</seed> for more info about what is a reasonable seed size.

=head1 SEE ALSO

L<Math::Random::Secure>
