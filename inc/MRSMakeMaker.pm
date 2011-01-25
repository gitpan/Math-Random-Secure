package inc::MRSMakeMaker;
use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_dump => sub {
    my $dump = super();
    $dump .= <<'END';

if ($^O =~ /Win32/i) {
    $WriteMakefileArgs{PREREQ_PM}->{'Crypt::Random::Source::Strong::Win32'} = 0;
}
END
    return $dump;
};

override _build_WriteMakefile_args => sub {
    my $args = super();
    $args->{CONFIGURE_REQUIRES}->{'ExtUtils::MakeMaker'} = '6.12';
    return $args;
};

override _build_MakeFile_PL_template => sub {
    my $string = super();
    $string =~ s/{{ \$eumm_version }}/6.12/g;
    return $string;
};

__PACKAGE__->meta->make_immutable;
