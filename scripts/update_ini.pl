#!perl -w

$running_under_some_shell = $running_under_some_shell = 0; # silence warning

###############################################################################
##                                                                           ##
##    Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.                  ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    V 1.0 05.02.2003 Steffen Beyer & Gerhard Albers                        ##
##                                                                           ##
###############################################################################

###############################################################################
## Header (controls the automatic initialization in Config::Manager::Base!): ##
###############################################################################

package Config::Manager::update_ini;

##############
## Imports: ##
##############

use strict;

use Config::Manager::Base qw( GetOrDie ReportErrorAndExit );
##########################################################
## This automatically initializes Config::Manager::Conf ##
## and Config::Manager::Report! Note that the order of  ##
## your "use" statements is essential here:             ##
## Config::Manager::Base must always be "use"d first,   ##
## before all other Config::Manager::* modules!         ##
##########################################################

use Config::Manager::Report qw(:all);
use Config::Manager::File   qw(:all);

#######################
## Global variables: ##
#######################

my($HOME) = &GetOrDie( ['DEFAULT', 'Home-Dir'] );

my $INI = "$HOME/Config/SPU.ini";

my $ORIG = "$INI.orig";

my $section = "DEFAULT";

my($self,$ini,$item,$line);

###################################
## Process command line options: ##
###################################

$self = $0;
$self =~ s!^.*[/\\]!!;
$self =~ s!\.+(?:pl|bat|sh)$!!i;

if (@ARGV)
{
    &Usage();
    exit 0 if ((@ARGV == 1) && ($ARGV[0] =~ /^--?(?:h|\?|help|hilfe)/i));
    &ReportErrorAndExit("Falsche Anzahl von Parametern!");
}

###########
## Main: ##
###########

# Datei einlesen

&ReportErrorAndExit()
    unless (defined ($ini = &ReadFile($INI)));

# Pass #1: Whitespace und [CR]LF am Ende der Zeilen entfernen

foreach $item (@{$ini}) { $item =~ s!\s+$!!; }

# Pass #2: Diverse Aenderungen durchfuehren

$item = 0;
LINE:
while ($item < @{$ini})
{
    $line = ${$ini}[$item];
    if ($line =~ /^\s*\[\s*(.+?)\s*\]\s*$/)
    {
        $section = $1;
        if (($section eq 'Host') or ($section eq 'BS2000'))
        {
            splice(@{$ini},$item,1);
        }
        else { $item++; }
        next LINE;
    }
    else
    {
        if ($section eq 'Host')
        {
            if ($line =~ s!^(\s*\$?)Platform(\s*=)!${1}HOST${2}!)
            {
                splice(@{$ini},$item,1,"[Commandline]",$line,"");
                $item += 3;
            }
            else
            {
                splice(@{$ini},$item,1);
            }
        }
        elsif ($section eq 'BS2000')
        {
            splice(@{$ini},$item,1);
        }
        else { $item++; }
    }
}

# Originaldatei sichern (falls nicht schon geschehen)

unless (-f $ORIG)
{
    unless (rename($INI,$ORIG))
    {
        &ReportErrorAndExit("Konnte Datei '$INI' nicht in '$ORIG' umbenennen: $!");
    }
}

# Pass #3: Newlines ("\n") am Ende der Zeilen wieder hinzufuegen

foreach $item (@{$ini}) { $item .= "\n"; }

# Neue Datei schreiben

umask(022);

&ReportErrorAndExit()
    unless (defined (&WriteFile($INI,$ini)));

exit 0; # 0 = OK

sub Usage
{
    print <<"VERBATIM";

Aufruf:

  $self -h
  $self

  Fuehrt automatische Aenderungen in der Datei "$INI"
  des jeweiligen Aufrufers durch.

  Mehrmaliges Aufrufen ist unschaedlich.

  Die urspruengliche Datei wird in "$ORIG" gesichert.

VERBATIM
}

__END__

