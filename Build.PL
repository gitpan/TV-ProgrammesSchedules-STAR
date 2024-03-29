use strict;use warnings;
use Module::Build;

my $builder = Module::Build->new(
    sign              => 1,
    module_name       => 'TV::ProgrammesSchedules::STAR',
    license           => 'perl',
    dist_author       => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    dist_version_from => 'lib/TV/ProgrammesSchedules/STAR.pm',
    add_to_cleanup    => [ 'TV-ProgrammesSchedules-STAR-*' ],
    build_requires    => {
        'Test::More'            => 0,
        'Readonly'              => '1.03',
        'HTTP::Request::Common' => 0,
        'Time::localtime'       => '1.02',
        'LWP::UserAgent'        => '2.33',
    },
);

$builder->create_build_script();