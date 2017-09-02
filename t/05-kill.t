use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;

my $start_time = time();

use lib 't/lib';
my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);

{
    require Dist::Zilla::Chrome::Test;
    my $meta = Moose::Util::find_meta('Dist::Zilla::Chrome::Test');
    $meta->make_mutable;
    $meta->add_around_method_modifier(
        prompt_yn => sub {
            sleep 1;
            # avoid calling real prompt
        },
    );
}

# for some reason, if the shell is used as an intermediary, we are incapable of
# having it respond to a kill signal? see test results for 0.013
$tempdir->child('config.ini')->spew(qq{[Chrome::ExtraPrompt]\ncommand = sleep 300\n});

# I need to make sure the chrome sent to the real zilla builder is the same
# chrome that was received from setup_global_config -- because the test
# builder actually unconditionally overwrites it with a ::Chrome::Test.

my $chrome = Dist::Zilla::Chrome::Test->new;

# stolen from Dist::Zilla::App

require Dist::Zilla::MVP::Assembler::GlobalConfig;
require Dist::Zilla::MVP::Section;
my $assembler = Dist::Zilla::MVP::Assembler::GlobalConfig->new({
    chrome => $chrome,
    stash_registry => {},
    section_class  => 'Dist::Zilla::MVP::Section',
});

require Dist::Zilla::MVP::Reader::Finder;
Dist::Zilla::MVP::Reader::Finder->new->read_config($tempdir->child('config'), { assembler => $assembler });

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
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

# the command takes 300 seconds to run, but we responded to the prompt after (usually) 1s
# -- but sometimes the machine could go to sleep in between and make it seem to take longer
cmp_ok(time() - $start_time, '<', 300, 'the command was aborted before it ran to completion');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
