# Mastermind for irssi 1.0 (2011-01-15)
# by Jari Jaanto (jaffa)
#
# jari.jaanto AT gmail.com
# http://jaan.to/
#
# get the latest version from: https://github.com/jaffastc/Mastermind
#
# Usage: 
# 
# Begin game with !begin
#   -t turns
#   -a answer
#   -c character
# 
# example: !begin 
# example: !begin -t 10 -a 0001 -c 01
# example: !begin -t 20 -a abrg -c abcdefghijklmopqrstuvwxyz0123456789
#
# It is possible that one begins the game with a private message 
# and others try to answer in the channel. No parameters required to
# start the game
# 
# Guess with !mm 1223
# 
# End game with !end
#
# * - correct character in wrong place
# O - correct character in correct place
#
# Example game:
# 
# <jaffa> !begin
# <derp> GAME ON! charset: 123456, answer: *hidden*, turns: 12, codemaster: jaffa
# <jaffa> !mm 1122
# <derp> 1122  (1/12)
# <jaffa> !mm 3344
# <derp> 3344 O** (2/12)
# <jaffa> !mm 5555
# <derp> 5555  (3/12)
# <jaffa> !mm 3436
# <derp> 3436 OOO (4/12)
# <jaffa> !mm 4436
# <derp> 4436 OO (5/12)
# <jaffa> !mm 3433
# <derp> 3433 OOOO (6/12) WIN! \o/ (Time: 41s)

use strict;
use Irssi qw (command_bind settings_get_str settings_set_str settings_add_str);
use vars qw($VERSION %IRSSI);

use constant S_MASTERMIND     => 'mastermind';

use constant S_LETTERS     => 'mastermind_letters';
use constant S_ANSWER     => 'mastermind_answer';
use constant S_QUESS     => 'mastermind_quess';
use constant S_TURNS     => 'mastermind_turns';
use constant S_TURN     => 'mastermind_turn';
use constant S_STATE     => 'mastermind_state';
use constant S_MASTER     => 'mastermind_master';
use constant S_START     => 'mastermind_start';

my $letters;
my $answer;
my $quess;
my $turns;
my $turn;
my $state;
my $master;
my $start;

my $def_turns = 12;
my $def_answer = '1234';
my $def_letters = '123456';

$VERSION = "1.0";
%IRSSI = (
    author => 'Jari Jaanto (jaffa)',
    contact => 'jari.jaanto AT gmail.com',
    name => 'mastermind',
    description => 'Mastermind for irssi 1.0',
    license => 'GNU GPL v3',
    url => 'http://jaan.to/'
);

sub reset_globals {
    $letters = '';
    $answer  = '';
    $quess   = '';
    $turns   = '';
    $turn    = '';
    $state   = '';
    $master  = '';
    $start   = '';
}

sub load_globals {
    $letters = settings_get_str(S_LETTERS);
    $answer  = settings_get_str(S_ANSWER);
    $quess   = settings_get_str(S_QUESS);
    $turns   = settings_get_str(S_TURNS);
    $turn    = settings_get_str(S_TURN);
    $state   = settings_get_str(S_STATE);
    $master  = settings_get_str(S_MASTER);
    $start   = settings_get_str(S_START);
}

sub save_globals {
    settings_set_str(S_LETTERS, $letters);
    settings_set_str(S_ANSWER, $answer);
    settings_set_str(S_QUESS, $quess);
    settings_set_str(S_TURNS, $turns);
    settings_set_str(S_TURN, $turn);
    settings_set_str(S_STATE, $state);
    settings_set_str(S_MASTER, $master);
    settings_set_str(S_START, $start);
}

sub event_privmsg {
    my ($server, $data, $nick, $mask, $target) = @_;
    my ($target, $text) = $data =~ /^(\S*)\s:(.*)/;

    if ( $text !~ /^!/i ) {
        return;
    }

    if ( $text =~ /^!end$/ ) {
        if ($state ne 'on') {
            $server->command ( "msg $target No game running at the moment." );
            return;
        }

        if ($nick ne $master && $state eq 'on' && $master ne '') {
            $server->command ( "msg $target Only codemaster '".$master."' can end the game!");
            return;
        }

        reset_globals();
        $state = 'off';        
        $server->command ( "msg $target Game ended. Begin a new game with !begin.");
        save_globals();
    }

    if ( $text =~ /^!mm/i ) {
        load_globals();

        if ($state ne 'on') {
            $server->command ( "msg $target No game in progress. Please begin a new game with !begin.");
            return;
        }

        my @args = split(/\s+/, $text);
        $quess = $args[1];

        if (length($quess) != length($answer)) {
            $server->command ( "msg $target Wrong number of characters in answer '".$answer."'! Please try again.");
            return;
        } 

        my @_answer = split('', $answer); 
        my @_quess = split('', $quess);

        my $out = '';

        for (my $i = 0; $i < length($answer); $i++) {
            if ($_answer[$i] eq $_quess[$i] && $_quess[$i] ne '\0') {
                $_answer[$i] = '\0';
                $_quess[$i] = '\0';
                $out .= 'O';
            }
        }

        for (my $i = 0; $i < length($answer); $i++) {
            for (my $j = 0; $j < length($quess); $j++) {
                if ($_answer[$i] eq $_quess[$j] && $_answer[$i] ne '\0' && $_quess[$j] ne '\0') {
                    $_answer[$i] = '\0';
                    $_quess[$j] = '\0';
                    $out .= '*';
                }
            }
        }

        $turn++;

        my $wintime = (time()) - $start;

        if ($out eq 'OOOO') {
            $server->command ( "msg $target $quess $out ($turn/$turns) WIN! \\o/ (Time: ".$wintime."s)");
            $state = 'off';
        } elsif ($turn == $turns) {
            $server->command ( "msg $target $quess $out ($turn/$turns) fail :(. Answer: ".$answer .". (Time: ".$wintime."s)");
            $state = 'off';
        } else {
            $server->command ( "msg $target $quess $out ($turn/$turns)");
        }

        save_globals();
    }

    if ( $text =~ /^!begin/i ) {
        load_globals();
        if ($state eq 'on') {
            $server->command ( "msg $target Another game still in progress! End it first with !end.");
            return;
        }
        
        reset_globals();

        my @args = split(/\s+/, $text);
        my $obj;

        foreach $obj(@args) {
            if ($obj =~ m/^-t/) { $turns = substr(lc($obj), 2); }
            if ($obj =~ m/^-a/) { $answer = substr(lc($obj), 2); }
            if ($obj =~ m/^-c/) { $letters = substr(lc($obj), 2); }
        }

        if (!$turns) { $turns = $def_turns; }
        if (!$letters) { $letters = $def_letters; }

        if (length($letters) < 4) {
            $server->command ( "msg $target The number of characters must be at least 4. '".$letters."' contains ".length($letters)." characters.");
            return;
        }

        if ($turns < 2 || $turns % 2 == 1) {
            $server->command ( "msg $target The number of turns must be 2 or greater even number! Game not started. ");
            return;
        }

        my @_letters = split('', $letters); 

        if (!$answer) {
            $answer = '';
            for (my $i = 0; $i < 4; $i++) {
                $answer .= $_letters[rand(length($letters))];
            }
        }

        if (length($answer) != 4) {
            $server->command ( "msg $target The answer may contain 4 characters only! '".$answer."' has ".length($answer)." characters.");
            return;
        }

        my @_answer = split('', $answer); 
        my $ok = 0;
        my $ans;
        my $let;

        foreach $ans(@_answer) {
            foreach $let(@_letters) {
                if ($ans eq $let) {
                    $ok++;
                }
            }
        }

        if ($ok < 4) {
            $server->command ( "msg $target Answer '".$answer."' contains characters not included in the character set '".$letters."'! Please check.");
            return;
        }

        $ok = 0;

        foreach $ans(@_letters) {
            foreach $let(@_letters) {
                if ($ans eq $let) {
                    $ok++;
                }
            }
        }

        if ($ok > length($letters)) {
            $server->command ( "msg $target Duplicate characters in character set '".$letters."'. Please check.");
            return;
        }

        $master = $nick;

        if ($nick eq $target) {
            $server->command ( "msg #mastermind GAME ON! charset: ".$letters.", answer: *hidden*, turns: ".$turns.", codemaster: ".$master );
        } else {
            $server->command ( "msg $target GAME ON! charset: ".$letters.", answer: *hidden*, turns: ".$turns.", codemaster: ".$master );
        }

        $start = time();
        $state = 'on';
        $turn = 0;
        save_globals();
    }
}

Irssi::settings_add_str(S_MASTERMIND, S_LETTERS, '');
Irssi::settings_add_str(S_MASTERMIND, S_ANSWER, '');
Irssi::settings_add_str(S_MASTERMIND, S_QUESS, '');
Irssi::settings_add_str(S_MASTERMIND, S_TURNS, '');
Irssi::settings_add_str(S_MASTERMIND, S_TURN, '');
Irssi::settings_add_str(S_MASTERMIND, S_STATE, '');
Irssi::settings_add_str(S_MASTERMIND, S_MASTER, '');
Irssi::settings_add_str(S_MASTERMIND, S_START, '');

Irssi::signal_add('event privmsg', 'event_privmsg');


