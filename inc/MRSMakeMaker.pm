package inc::MRSMakeMaker;
use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_dump => sub {
    my ($self) = @_;
    my $dump = super();
    $dump .= <<'END';

if ($^O =~ /Win32/i) {
    $WriteMakefileArgs{PREREQ_PM}->{'Crypt::Random::Source::Strong::Win32'} = 0;
}
END
    return $dump;
};

__PACKAGE__->meta->make_immutable;
