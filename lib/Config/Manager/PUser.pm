
###############################################################################
##                                                                           ##
##    Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.                  ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Config::Manager::PUser;

use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
             $current_user $current_conf $default_user $default_conf );

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw( &current_user &current_conf &default_user &default_conf );

%EXPORT_TAGS = (all => [@EXPORT_OK]);

$VERSION = '1.1';

##############
## Imports: ##
##############

# Must be "use"d first, initializes configuration and log file:
use Config::Manager::Base qw( ReportErrorAndExit );
use Config::Manager::Conf;
use Config::Manager::User qw( user_id user_conf );

#######################################
## Internal configuration constants: ##
#######################################

# (Siehe in Routine "BEGIN" unten!)

#######################
## Static variables: ##
#######################

# (Siehe "use vars qw( ... );" oben!)

########################
## Private functions: ##
########################

BEGIN
{
    my($error,$param,$value);
    my(@DEFAULT_USER) = ('DEFAULT', 'Default-User');
    my(@CmdLineParms) = qw( HOST LANG SRC OBJ EXE );
    my($Section)      = 'Commandline';
    my($FAILED);

    $FAILED = __PACKAGE__ . "::BEGIN(): Initialisierung fehlgeschlagen:";
    unless (defined ($current_user = &user_id()))
    {
        &ReportErrorAndExit( $FAILED ,
"Konnte Kennung des Aufrufers nicht bestimmen!" );
    }
    unless (defined ($current_conf = &user_conf($current_user)))
    {
        &ReportErrorAndExit( $FAILED ,
"Konnte Konfigurations-Objekt des Aufrufers ($current_user) nicht anlegen!" );
    }
    unless (defined ($default_user = $current_conf->get(@DEFAULT_USER)))
    {
        $error = $current_conf->error();
        $error =~ s!\s+$!!;
        &ReportErrorAndExit(
            $FAILED,
"Konnte Kennung des Projekt-Users nicht bestimmen:",
            $error );
    }
    unless (defined ($default_conf = &user_conf($default_user)))
    {
        &ReportErrorAndExit( $FAILED ,
"Konnte Konfigurations-Objekt des Projekt-Users ($default_user) nicht anlegen!" );
    }
    for $param (@CmdLineParms)
    {
        unless (defined ($value = $current_conf->get($Section,$param)))
        {
            $error = $current_conf->error();
            $error =~ s!\s+$!!;
            &ReportErrorAndExit(
                $FAILED,
"Konnte '\$${Section}::$param' des Aufrufers ($current_user) nicht bestimmen:",
                $error );
        }
        unless (defined ($default_conf->set(__PACKAGE__,$Section,$param,$value)))
        {
            $error = $default_conf->error();
            $error =~ s!\s+$!!;
            &ReportErrorAndExit(
                $FAILED,
"Konnte '\$${Section}::$param' des Projekt-Users ($default_user) nicht setzen:",
                $error );
        }
    }
}

#######################
## Public functions: ##
#######################

sub current_user
{
    return $current_user;
}

sub current_conf
{
    return $current_conf;
}

sub default_user
{
    return $default_user;
}

sub default_conf
{
    return $default_conf;
}

1;

__END__

=head1 NAME

Config::Manager::PUser - liefert den Default- bzw. "Projekt"-User

=head1 SYNOPSIS

  $current_user = &current_user();

  $current_conf = &current_conf();

  $default_user = &default_user();

  $default_conf = &default_conf();

=head1 DESCRIPTION

Dieses Modul bestimmt (mit Hilfe der automatisch ausgefuehrten
"BEGIN"-Funktion) die User-IDs des aktuellen (aufrufenden)
und des Default-Benutzers (z.B. fuer Sende-Tools), legt die zugehoerigen
Konfigurations-Objekte im Cache des Moduls "Config::Manager::User" an
(ganz wichtig, weil spaeter z.B. das Modul "Config::SPU::JOB" automatisch
genau auf diese gecachten Objekte zugreifen wird!) und kopiert den
Wert der Konfigurations-Variablen "C<$Host::Platform>" und
"C<$Host::Environment>" aus dem Konfigurations-Objekt des aktuellen
in das des Default-Benutzers.

Ganz wesentlich ist hier, dass z.B. die Werte fuer HOST-ID und HOST-PW
vorher nicht bestimmt worden sind, da sonst diese Werte im Modul
"Config::Manager::Conf" gecacht wuerden und somit das Ueberschreiben
der Variablen "C<$Host::Platform>" wirkungslos bliebe.

Dies ist aber hier insofern gewaehrleistet, als durch den
"use"-Mechanismus die "BEGIN"-Funktion automatisch bereits beim
Hochstarten jedes (Sende-) Tools, das dieses Modul hier benutzt,
ausgefuehrt wird. Das waere nur dann nicht gewaehrleistet, wenn
man dieses Modul nicht mit "use" zu Programmbeginn, sondern
erst spaeter mit "require" einbinden (und zudem die Variablen
wie z.B. HOST-ID und HOST-PW fuer den Default-Benutzer auswerten)
wuerde. Solange dieses Modul also immer mit "use" geladen wird
(und warum sollte es auch nicht!), kann also nichts Schlimmes
passieren.

=head1 HISTORY

 2003_02_05  Steffen Beyer & Gerhard Albers  Version 1.0
 2003_02_14  Steffen Beyer                   Version 1.1
