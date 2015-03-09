use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

like(
    exception {
        my $tzil = Builder->from_config(
            { dist_root => 't/does_not_exist' },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        'Chrome::ExtraPrompt',
                    ),
                    path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                },
            },
        );
        $tzil->build;
    },
    qr{must be used in ~/.dzil/config.ini -- NOT dist.ini!},
    'plugin cannot be used within dist.ini',
);

done_testing;
