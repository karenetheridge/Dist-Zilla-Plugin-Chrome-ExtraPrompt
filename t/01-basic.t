use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use File::Temp 'tempdir';

use lib 't/lib';

{
    require Dist::Zilla::Chrome::Term;
    my $meta = Moose::Util::find_meta('Dist::Zilla::Chrome::Term');
    $meta->make_mutable;
    $meta->add_around_method_modifier(
        prompt_yn => sub {
            sleep 1;    # time for signal to reach us
            # avoid calling real term ui
        },
    );
}

# I need to make sure the chrome sent to the real zilla builder is the same
# chrome that was received from setup_global_config -- because the test
# builder actually unconditionally overwrites it with a ::Chrome::Test.

my $tempdir = tempdir(CLEANUP => 1);
my $promptfile = path($tempdir, 'gotprompt');

path($tempdir, 'config.ini')->spew("[Chrome::ExtraPrompt]\ncommand = echo hi > $promptfile\n");

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
            path(qw(source dist.ini)) => simple_ini(
                '=TestPrompter',    # will send a prompt during build
                'GatherDir',
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

# grab chrome object we saved from earlier, and assign it back again
$tzil->chrome($chrome);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

ok(-e $promptfile, 'we got prompted');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
