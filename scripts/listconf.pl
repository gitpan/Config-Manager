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

package Config::Manager::listconf;

##############
## Imports: ##
##############

use strict;
use vars qw( @ARGV );

use Config::Manager::Base qw( ReportErrorAndExit );
##########################################################
## This automatically initializes Config::Manager::Conf ##
## and Config::Manager::Report! Note that the order of  ##
## your "use" statements is essential here:             ##
## Config::Manager::Base must always be "use"d first,   ##
## before all other Config::Manager::* modules!         ##
##########################################################

use Config::Manager::Conf;
use Config::Manager::User qw(:all);

my($self,$user,$conf,$list,$line);

$self = $0;
$self =~ s!^.*[/\\]!!;
$self =~ s!\.+(?:pl|bat|sh)$!!i;

if (@ARGV > 1)
{
    &Usage();
    &ReportErrorAndExit("Falsche Anzahl von Parametern!");
}

if (@ARGV)
{
    if ($ARGV[0] =~ /^--?(?:h|\?|help|hilfe)/i)
    {
        &Usage();
        exit 0; # 0 = OK
    }
    $user = shift;
}
else
{
    &ReportErrorAndExit()
        unless (defined ($user = &user_id()));
}

&ReportErrorAndExit()
    unless (defined ($conf = &user_conf($user)));

unless (defined ($list = $conf->get_all()))
{
    $line = Config::Manager::Conf->error();
    $line =~ s!\s+$!!;
    &ReportErrorAndExit(
        "Fehler bei der Auswertung der Konfigurationsdaten:",
        $line );
}

unless ((-t STDOUT) && (open(MORE, "| more")))
{
    unless (open(MORE, ">-"))
    {
        &ReportErrorAndExit("Can't open STDOUT: $!");
    }
}

foreach $line (@{$list})
{
    $line =~ s!\s+$!!;
    print MORE "$line\n";
}

close(MORE);

exit 0; # 0 = OK

sub Usage
{
    print <<"VERBATIM";

Aufruf:

  $self -h
  $self [<login>]

  Listet saemtliche Konfigurationskonstanten des Aufrufers
  oder des angegebenen Benutzers auf.

VERBATIM
}

__END__

