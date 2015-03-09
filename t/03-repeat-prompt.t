use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use File::Temp 'tempdir';

# most of this file is copied from t/01-basic.t

{
    require Dist::Zilla::Chrome::Term;
    my $meta = Moose::Util::find_meta('Dist::Zilla::Chrome::Term');
    $meta->make_mutable;
    $meta->add_around_method_modifier(
        prompt_yn => sub {
            sleep 1;    # allow time for the file to be written
            # avoid calling real term ui
        },
    );
}

{
    package Dist::Zilla::Plugin::_TestPrompter;
    use Moose;
    with 'Dist::Zilla::Role::BeforeBuild';
    sub before_build
    {
        my $self = shift;
        my $continue = $self->zilla->chrome->prompt_yn('hello, are you there?', { default => 0 });
    }
}

# I need to make sure the chrome sent to the real zilla builder is the same
# chrome that was received from setup_global_config -- because the test
# builder actually unconditionally overwrites it with a ::Chrome::Test.

my $tempdir = tempdir(CLEANUP => 1);
my $promptfile = path($tempdir, 'gotprompt');

my $config_ini = <<'CONFIG';
[Chrome::ExtraPrompt]
command = %s -MPath::Tiny -e"path(q[%s])->spew(@ARGV)"
repeat_prompt = 1
CONFIG

path($tempdir, 'config.ini')->spew(sprintf($config_ini, $^X, $promptfile));

my $chrome = Dist::Zilla::Chrome::Term->new;

# stolen from Dist::Zilla::App

require Dist::Zilla::MVP::Assembler::GlobalConfig;
require Dist::Zilla::MVP::Section;
my $assembler = Dist::Zilla::MVP::Assembler::GlobalConfig->new({
    chrome => $chrome,
    stash_registry => {},
    section_class  => 'Dist::Zilla::MVP::Section',
});

require Dist::Zilla::MVP::Reader::Finder;
Dist::Zilla::MVP::Reader::Finder->new->read_config(path($tempdir, 'config'), { assembler => $assembler });

my $tzil = Builder->from_config(
    { dist_root => 't/does_not_exist' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                '_TestPrompter',    # will send a prompt during build
                'GatherDir',
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

# grab chrome object we saved from earlier, and assign it back again
$tzil->chrome($chrome);

$tzil->build;

SKIP: {
    ok(-e $promptfile, 'we got prompted')
        or skip 'no file was created to test', 1;

    is(
        $promptfile->slurp,
        'hello, are you there?',
        'prompt string was correctly sent to the command, as a single argument',
    );
}

done_testing;
