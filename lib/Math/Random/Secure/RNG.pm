package Math::Random::Secure::RNG;
use Any::Moose;
use Math::Random::ISAAC;
use Crypt::Random::Source::Factory;
use constant ON_WINDOWS => $^O =~ /Win32/i ? 1 : 0;
use if ON_WINDOWS, 'Crypt::Random::Source::Strong::Win32';

has seeder => (is => 'ro', isa => 'Crypt::Random::Source::Base', 
               lazy_build => 1);
has seed_size => (is => 'ro', isa => 'Int', default => 1024);
has seed => (is => 'ro', isa => 'Str', lazy_build => 1);
has rng => (is => 'ro', isa => 'Object', lazy_build => 1);

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
    return Math::Random::ISAAC->new(@seed_ints);
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
be large enough to properly seed L</rng>. For the default ISAAC
implementation, this means it must be 1024 bytes (256 32-bit integers). It is
very important that the seed be large enough. B<There are serious attacks
possible against random number generators that are seeded with non-random
data or with insufficient random data.>

If you pass this to C<new()>, L</seeder> and L</seed_size> will be ignored.

=head2 seeder

An instance of L<Crypt::Random::Source::Base> that will be used to
get the seed for L</rng>.

=head2 seed_size

How much data (in bytes) should be read using L</seeder> to seed L</rng>.

=head1 SEE ALSO

L<Math::Random::Secure>
