
###############################################################################
##                                                                           ##
##    Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.                  ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    V 1.0 05.02.2003 Steffen Beyer & Gerhard Albers                        ##
##                                                                           ##
###############################################################################

package Config::Manager::User;

use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION );

require Exporter;
@ISA = qw(Exporter);

@EXPORT    = qw();
@EXPORT_OK = qw(
                   user_id
                   user_name
                   user_conf
                   host_id
                   host_pw
                   machine_id
                   SetTestMode
               );

%EXPORT_TAGS = (all => [@EXPORT_OK]);

$VERSION = '1.0';

use Config::Manager::Conf qw( whoami );
use Config::Manager::Report qw(:all);

##############################
## Configuration constants: ##
##############################

my @FULLNAME = ('Person',  'Name');
my @HOST_ID  = ('Host',    'HOST-ID');
my @HOST_PW  = ('Host',    'HOST-PW');
my @MACHINE  = ('DEFAULT', 'MACHINE');

#######################
## Global variables: ##
#######################

my %ConfCache = ();

my $TestDriverFlag = 0;

my @TestDriverData = ("testfall", "Test Fall", "hostTT", "hostXXXX");

########################
## Private Functions: ##
########################

sub _get_user_conf
{
    my($userid) = @_;    # User-Kennung
    my($ownerid,$varname,$scope,$confobj,$error);

    local($@);
    if ((exists  $ConfCache{$userid}) &&
        (defined $ConfCache{$userid}) &&
        (ref     $ConfCache{$userid}))
    {
        return $ConfCache{$userid};
    }
    unless (($ownerid,$varname) = &whoami()) # defined in Conf.pm
    {
        Config::Manager::Report->report
        (
            @ERROR,
            "Benutzerkennung in der Umgebung nicht gefunden!"
        );
        return undef;
    }
    if ($userid eq $ownerid)
    {
        $confobj = Config::Manager::Conf->default();
        $ConfCache{$userid} = $confobj;
        return $confobj;
    }
    $error = '';
    $ENV{$varname} = $userid;
    {
        local($SIG{'__DIE__'}) = 'DEFAULT';
        eval
        {
            if (defined ($scope = Config::Manager::Conf->scope()))
            {
                if (defined ($confobj = Config::Manager::Conf->new()))
                {
                    unless (defined ($confobj->init( $scope )))
                    {
                        $error = $confobj->error();
                    }
                }
                else
                {
                    $error = Config::Manager::Conf->error();
                }
            }
            else
            {
                $error = Config::Manager::Conf->error();
            }
        };
    }
    $ENV{$varname} = $ownerid;
    if (($@ ne '') || ($error ne ''))
    {
        $@ =~ s!\s+$!!;
        $error =~ s!\s+$!!;
        if (($@ ne '') && ($error ne '')) { $error = join("\n", $@, $error); }
        else                              { $error = $@ . $error; }
        Config::Manager::Report->report
        (
            @ERROR,
"Fehler beim Ermitteln der Konfigurationsdaten fuer Benutzer '$userid':",
            $error
        );
        return undef;
    }
    $ConfCache{$userid} = $confobj;
    return $confobj;
}

#######################
## Public functions: ##
#######################

sub user_id
{
    my($user_id);

    if ($TestDriverFlag)
    {
        return $TestDriverData[0];
    }
    if (($user_id) = &whoami()) # defined in Conf.pm
    {
        return $user_id;
    }
    Config::Manager::Report->report
    (
        @ERROR,
        "Benutzerkennung in der Umgebung nicht gefunden!"
    );
    return undef;
}

sub user_name
{
    my($conf,$user_name,$error);

    if ($TestDriverFlag)
    {
        return $TestDriverData[1];
    }
    if (@_ > 0)
    {
        return undef
            unless (defined ($conf = &_get_user_conf($_[0])));
    }
    else
    {
        $conf = Config::Manager::Conf->default();
    }
    if (defined ($user_name = $conf->get(@FULLNAME)))
    {
        return $user_name;
    }
    $error = $conf->error();
    $error =~ s!\s+$!!;
    Config::Manager::Report->report
    (
        @ERROR,
        "Benutzername in den Konfigurationsdaten nicht gefunden:",
        $error
    );
    return undef;
}

sub user_conf
{
    if (@_ > 0)
    {
        return &_get_user_conf($_[0]);
    }
    Config::Manager::Report->report(@FATAL, "Kein Benutzer angegeben!");
    return undef;
}

sub host_id
{
    my($conf,$host_id,$error);

    if ($TestDriverFlag)
    {
        return $TestDriverData[2];
    }
    if (@_ > 0)
    {
        return undef
            unless (defined ($conf = &_get_user_conf($_[0])));
    }
    else
    {
        $conf = Config::Manager::Conf->default();
    }
    if (defined ($host_id = $conf->get(@HOST_ID)))
    {
        return $host_id;
    }
    $error = $conf->error();
    $error =~ s!\s+$!!;
    Config::Manager::Report->report
    (
        @ERROR,
        "HOST-ID in den Konfigurationsdaten nicht gefunden:",
        $error
    );
    return undef;
}

sub host_pw
{
    my($conf,$host_pw,$error);

    if ($TestDriverFlag)
    {
        return $TestDriverData[3];
    }
    if (@_ > 0)
    {
        return undef
            unless (defined ($conf = &_get_user_conf($_[0])));
    }
    else
    {
        $conf = Config::Manager::Conf->default();
    }
    if (defined ($host_pw = $conf->get(@HOST_PW)))
    {
        return $host_pw;
    }
    $error = $conf->error();
    $error =~ s!\s+$!!;
    Config::Manager::Report->report
    (
        @ERROR,
        "HOST-PW in den Konfigurationsdaten nicht gefunden:",
        $error
    );
    return undef;
}

sub machine_id
{
    my($machine,$error);

    if (defined ($machine = Config::Manager::Conf->get(@MACHINE)))
    {
        return $machine;
    }
    $error = Config::Manager::Conf->error();
    $error =~ s!\s+$!!;
    Config::Manager::Report->report
    (
        @ERROR,
        "MACHINE-ID in den Konfigurationsdaten nicht gefunden:",
        $error
    );
    return undef;
}

sub SetTestMode
{
    $TestDriverFlag = 1;
}

1;

__END__

=head1 NAME

Config::Manager::User - Routinen zur Abfrage von Benutzerinformationen

=head1 SYNOPSIS

 use Config::Manager::User qw(:all);

 # Login-Kennung des momentanen Users ermitteln
 my $user    = user_id();

 # HOST-ID des momentanen Users bestimmen
 my $host_id = host_id();

 # HOST-PW des momentanen Users bestimmen
 my $host_pw = host_pw();

 # HOST-ID des angegebenen Users (client) bestimmen
 my $host_id = host_id("client");

 # HOST-PW des angegebenen Users (client) bestimmen
 my $host_pw = host_pw("client");

 # MACHINE-ID des Aufrufers bestimmen
 my $machine = machine_id();

 # Benutzername (Vor- und Nachname) des
 # momentanen Users ermitteln
 my $name    = user_name();

 # Benutzername (Vor- und Nachname) des
 # angegebenen Users (client) ermitteln
 my $name    = user_name("client");

 # "Config::Manager::Conf"-Objekt fuer den angegebenen
 # User zurueckgeben
 my $conf    = user_conf("client");

 # Andere Benutzer-spezifische Informationen
 # ermitteln (Beispiel)
 my $phone   = $conf->get('Person', 'Telefon');

=head1 DESCRIPTION

In diesem Modul finden sich einige Routinen, um Informationen ueber den
Benutzer des Programms (oder andere Benutzer) zu erhalten. Es stuetzt
sich dabei auf das Modul "Config::Manager::Conf" ab.

Im Testtreiber-Modus liefert das Modul immer die gleichen Benutzer-Daten,
unabhaengig vom Aufrufer.

=head1 ZUGANG & SICHERHEIT

Dieses Modul setzt voraus, dass die Konfigurationsdateien von allen
Benutzern fuer alle Benutzer zugaenglich und lesbar sind (also z.B.
nicht lokal auf dem Rechner des jeweiligen Benutzers, sondern zentral
auf einem Netzlaufwerk abgelegt sind), so dass die persoenlichen
Informationen wie voller Name, Host-ID usw. auch fuer andere
Benutzer als den momentanen Aufrufer ermittelt werden koennen.

Dies ist insbesondere fuer den Daemon wichtig, der die Job-Outputs vom
Host abholt, da er z.B. nachschauen koennen muss, in welches Verzeichnis
der jeweilige Absender die Job-Outputs gestellt haben moechte.

Es ist dabei jedoch trotzdem moeglich, sensible Daten wie Passwoerter
in eine separate und speziell geschuetzte Datei auszulagern, die auch
lokal auf der jeweiligen Maschine liegen darf.

Dazu muss man lediglich die letzte der einzulesenden Konfigurationsdateien
mit Hilfe des "NEXTCONF"-Zeigers auf eine Datei zeigen lassen, die nur vom
jeweiligen Besitzer gelesen und geschrieben werden kann, und deren Name in
"PRIVATE.ini" enden muss (es koennen aber z.B. auch Namen wie
".../SPU-PRIVATE.ini" o.ae. verwendet werden - der Name muss nur
dem Regulaeren Ausdruck "C</\bPRIVATE?\.ini$/i>" genuegen).

In dieser Datei legt dann der jeweilige Benutzer seine sensiblen Daten
ab - und zwar nur diese, da alle uebrigen Angaben ggfs. von anderen Tools
benoetigt werden (wie z.B. vom Daemon zum Abholen der Job-Outputs, von
Tools zum Auflisten der kompletten Konfiguration, von Tools zum Anzeigen
von allen gesendeten Auftraegen (Jobs), usw.).

Der Besitzer der "privaten" Datei muss darauf achten, dass niemand ausser
ihm selbst Lese- oder Schreibrechte fuer diese Datei hat, und dass niemand
ausser ihm Schreibrechte auf das Verzeichnis hat, in dem diese Datei liegt.

=head1 DATENSTRUKTUREN

=over 4

=item *

C<%ConfCache>

Speichert die Konfigurationsobjekte von verschiedenen Benutzern zwischen.
Schluessel sind die User-Kennungen, Werte die Objekt-Referenzen von Instanzen
von "Config::Manager::Conf".

=item *

C<$TestDriverFlag>

Flag, ob Module von einem Testtreiber aus aufgerufen werden.

Wenn das Flag gesetzt ist, wird ein fester Benutzer zurueckgeliefert,
damit die Referenzdatei unabhaengig vom Aufrufer gueltig ist.

=item *

C<@TestDriverData>

Benutzerdaten fuer den Testtreiber.

 Inhalt: ($user_id,$user_name,$host_id,$host_pw)

=back

=head1 OEFFENTLICHE ROUTINEN

=over 4

=item *

C<user_id()>

Benutzerkennung des momentanen Users (d.h. des Aufrufers).

 Parameter: -
 Rueckgabe: Benutzerkennung oder undef bei Fehler

=item *

C<user_name()>

Benutzername (Vor- und Nachname) des momentanen oder
angegebenen Users bestimmen.

 Parameter: [user-id] (optional)
 Rueckgabe: Benutzername (Vor- und Nachname) oder undef

=item *

C<user_conf()>

Das Konfigurationsobjekt fuer den angegebenen User.

 Parameter: user-id (Login-Kennung des Users)
 Rueckgabe: Referenz auf Konfigurationsobjekt oder undef bei Fehler

=item *

C<host_id()>

HOST-ID des momentanen oder angegebenen Users bestimmen.

 Parameter: [user-id] (optional)
 Rueckgabe: HOST-ID  oder  undef

=item *

C<host_pw()>

HOST-PW des momentanen oder angegebenen Users bestimmen.

 Parameter: [user-id] (optional)
 Rueckgabe: HOST-PW  oder  undef

=item *

C<machine_id()>

MACHINE-ID des momentanen Users bestimmen.

 Parameter: -
 Rueckgabe: MACHINE-ID  oder  undef

=item *

C<SetTestMode()>

Modul arbeitet fortan im Testtreiber-Modus.

 Parameter: -
 Rueckgabe: -

=back

=head1 PRIVATE ROUTINEN

=over 4

=item *

C<private _get_user_conf()>

Gibt zu einer Login-Kennung ein Objekt mit der Konfiguration des
betreffenden Benutzers zurueck.

 Parameter: user-id   Login-Kennung des Users
 Rueckgabe: Referenz auf "Config::Manager::Conf"-Objekt  oder  undef

=back

=head1 HISTORY

 2003_02_05  Steffen Beyer & Gerhard Albers  Version 1.0

