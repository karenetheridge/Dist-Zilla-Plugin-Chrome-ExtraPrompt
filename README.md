# NAME

Dist::Zilla::Plugin::Chrome::ExtraPrompt - Perform arbitrary commands when Dist::Zilla prompts you

# VERSION

version 0.005

# SYNOPSIS

In your `~/.dzil/config.ini` (__NOT__ `dist.ini`):

    [Chrome::ExtraPrompt]
    command = say Dist zilla would like your attention.
    repeat_prompt = 1

# DESCRIPTION

This is a [Dist::Zilla](http://search.cpan.org/perldoc?Dist::Zilla) plugin that is loaded from your
`~/.dzil/config.ini`, which affects the behaviour of prompts within
[Dist::Zilla](http://search.cpan.org/perldoc?Dist::Zilla) commands. When you are prompted, the specified command is run;
it is killed when you provide prompt input.

I have mine configured as in the synopsis, which uses the `say` command on
OS X to provide an audio prompt to bring me back to this screen session.

# CONFIGURATION OPTIONS

- `command`: the string containing the command and arguments to call.
required.
- `repeat_prompt`: a boolean flag (defaulting to false) that, when set,
appends the prompt string to the command and arguments that are called,
passing as a single (additional?) argument.

# SUPPORT

Bugs may be submitted through [the RT bug tracker](https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Chrome-ExtraPrompt)
(or [bug-Dist-Zilla-Plugin-Chrome-ExtraPrompt@rt.cpan.org](mailto:bug-Dist-Zilla-Plugin-Chrome-ExtraPrompt@rt.cpan.org)).
I am also usually active on irc, as 'ether' at `irc.perl.org`.

# AUTHOR

Karen Etheridge <ether@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
