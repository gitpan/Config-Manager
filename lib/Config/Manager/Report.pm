
###############################################################################
##                                                                           ##
##    Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.                  ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Config::Manager::Report;

use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION %SIG
             $USE_LEADIN $STACKTRACE $LEVEL_TRACE $LEVEL_INFO
             $LEVEL_WARN $LEVEL_ERROR $LEVEL_FATAL $TO_HLD
             $TO_OUT $TO_ERR $TO_LOG $FROM_HOLD $SHOW_ALL
             @TRACE @INFO @WARN @ERROR @FATAL );

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw( $USE_LEADIN $STACKTRACE $LEVEL_TRACE $LEVEL_INFO
                 $LEVEL_WARN $LEVEL_ERROR $LEVEL_FATAL $TO_HLD
                 $TO_OUT $TO_ERR $TO_LOG $FROM_HOLD $SHOW_ALL
                 @TRACE @INFO @WARN @ERROR @FATAL end abort );

%EXPORT_TAGS = (all => [@EXPORT_OK]);

$VERSION = '1.1';

use Config::Manager::Conf qw( whoami );
use IO::File;

#######################
## Public constants: ##
#######################

$TO_HLD      = 0x01;
$TO_OUT      = 0x02;
$TO_ERR      = 0x04;
$TO_LOG      = 0x08;
$FROM_HOLD   = 0x10;

$USE_LEADIN  = 0x01;
$STACKTRACE  = 0x02;

$LEVEL_TRACE = 0x00;
$LEVEL_INFO  = 0x04;
$LEVEL_WARN  = 0x08;
$LEVEL_ERROR = 0x0C;
$LEVEL_FATAL = 0x10;

$SHOW_ALL    = 0x00;

@TRACE = ( $TO_LOG          , $LEVEL_TRACE + $USE_LEADIN );
@INFO  = ( $TO_LOG + $TO_OUT, $LEVEL_INFO  + $USE_LEADIN );
@WARN  = ( $TO_LOG + $TO_ERR, $LEVEL_WARN  + $USE_LEADIN );
@ERROR = ( $TO_LOG + $TO_HLD, $LEVEL_ERROR + $USE_LEADIN );
@FATAL = ( $TO_LOG + $TO_HLD, $LEVEL_FATAL + $USE_LEADIN );

#######################################
## Internal configuration constants: ##
#######################################

my @LOGFILEPATH  = ('DEFAULT', 'LOGFILEPATH');
my @FULLNAME     = ('Person',  'Name');

my $RULER   = '_' x 78 . "\n";
my $HEADER  = 'PROTOKOLL';
my $CMDLINE = 'KOMMANDO';
my $LOGFILE = 'LOGFILE';
my $FOOTER  = 'ENDE';

my @LEADIN =
(
    [ 'AUFRUF',  'HINWEIS',  'WARNUNG',   'FEHLER', 'AUSNAHME'  ], # Singular
    [ 'AUFRUFE', 'HINWEISE', 'WARNUNGEN', 'FEHLER', 'AUSNAHMEN' ]  # Plural
);

my $LINE0 = 'Zeile auf Halde';
my $LINE1 = 'Zeilen auf Halde';

my $STAT_MIN = 1;
my $STAT_MAX = 4;

my $STARTDEPTH = 0;
my $MAXEVALLEN = 0; # 0 = no limit

#######################
## Static variables: ##
#######################

my $singleton = 0;

########################
## Private functions: ##
########################

sub _warn_
{
    my($text) = @_;
    $text =~ s!\s+$!!;
    Config::Manager::Report->report
    (
        $TO_LOG+$TO_ERR, $LEVEL_WARN+$USE_LEADIN, $text
    )
}

sub _die_
{
    my($text) = @_;
    $text =~ s!\s+$!!;
    Config::Manager::Report->report
    (
        $TO_LOG+$TO_ERR, $LEVEL_FATAL+$USE_LEADIN, $text
    )
    if (defined $^S); # no logging during startup
}

sub _adjust # code "stolen" from Carp.pm:
{
    my($pack,$file,$line,$sub,$hargs,$warray,$eval,$require) = @_;

    if (defined $eval)
    {
        if ($require)
        {
            $sub = "require $eval";
        }
        else
        {
            if ($MAXEVALLEN && length($eval) > $MAXEVALLEN)
            {
                substr($eval,$MAXEVALLEN) = '...';
            }
            $eval =~ s!([\\\'])!\\$1!g;
            $sub = "eval '$eval'";
        }
    }
    elsif ($sub eq '(eval)')
    {
        $sub = 'eval {...}';
    }
    return $sub;
}

sub _ShortTime
{
    my($s,$m,$h,$day,$mon) = localtime(time);
    return sprintf("%02d%02d-%02d%02d%02d", ++$mon,$day,$h,$m,$s);
}

sub _LongTime
{
    my($s,$m,$h,$day,$mon);

    if ($_[0]) # called by a test driver?
    {
        return "TT.MM. hh:mm:ss";
    }
    else
    {
        ($s,$m,$h,$day,$mon) = localtime(time);
        return sprintf("%02d.%02d. %02d:%02d:%02d", $day,++$mon,$h,$m,$s);
    }
}

sub _which
{
    my($self) = @_;

    if (ref $self) { return $self; }
    else
    {
        unless (ref $singleton)
        {
            $singleton = Config::Manager::Report->new();
            $SIG{'__WARN__'} = \&_warn_;
            $SIG{'__DIE__'}  = \&_die_;
        }
        return $singleton;
    }
}

sub DESTROY
{
    my($self) = @_;
    my($file,$handle,$text,$item,$count);

    $file = ${$self}{'file'};
    $handle = ${$self}{'hand'};
    if (${$self}{'flag'})
    {
        $self->report($TO_LOG+$TO_OUT,$LEVEL_INFO,"$LOGFILE = '$file'");
    }
    $text = "\n" . $RULER . "\n $FOOTER: " . _LongTime(${$self}{'test'});
    for ( $item = $STAT_MIN; $item <= $STAT_MAX; $item++ )
    {
        if ((defined ($count = ${${$self}{'stat'}}[$item])) && ($count > 0))
        {
            $text .= " - $count ";
            if ($count == 1) { $text .= ucfirst(lc($LEADIN[0][$item])); }
            else             { $text .= ucfirst(lc($LEADIN[1][$item])); }
        }
    }
    if (($count = scalar(@{${$self}{'hold'}})) > 0)
    {
        $text .= " - $count ";
        if ($count == 1) { $text .= $LINE0; }
        else             { $text .= $LINE1; }
    }
    $text .= "\n" . $RULER;
    $self->report($TO_LOG,$LEVEL_INFO,$text);
    unless ($handle->close())
    {
        print STDERR __PACKAGE__ .
            "::DESTROY(): Can't close logfile '$file': $!\n";
    }
}

END { &end(); }

#######################
## Public functions: ##
#######################

sub end
{
    $SIG{'__WARN__'} = 'DEFAULT';
    $SIG{'__DIE__'}  = 'DEFAULT';
    $singleton = 0; # trigger destruction of singleton object if it exists
}

sub abort
{
    &end();
    print STDERR @_ if @_;
    print STDERR "<Programmabbruch>\n";
    exit 1;
}

#####################
## Public methods: ##
#####################

sub singleton
{
    return _which($singleton); # trigger creation if necessary
}

sub new
{
    my($class,$tool,$path,$test) = @_;
    my($err,$self,$file,$handle,$user,$name,$time,$text);

    local($_);
    $class = ref($class) || $class || __PACKAGE__;
    unless (defined $tool && $tool !~ /^\s*$/)
    {
        $tool = $0;
        $tool =~ s!^.*[/\\]!!;
        $tool =~ s!\.+(?:pl|bat|sh)$!!i;
    }
    unless (defined $path && $path !~ /^\s*$/)
    {
        unless (defined ($path = Config::Manager::Conf->get(@LOGFILEPATH)))
        {
            $err = Config::Manager::Conf->error();
            $err =~ s!\s+$!!;
            &abort(__PACKAGE__ .
                "::new(): Can't find log directory in configuration data: $err\n");
        }
    }
    $path =~ s![/\\]+$!!;
    if (defined $test && $test) # we've been called by a test driver
    {
        $test = 1;
        $file = $path;
    }
    else # normal operation
    {
        $test = 0;
        unless (-d $path)
        {
            &abort(__PACKAGE__ .
                "::new(): Log directory '$path' does not exist!\n");
        }
        $path .= "/$tool";
        $file = "$path/$tool-" . _ShortTime . "-$$.log";
        unless (-d $path)
        {
            unless (mkdir($path, 0777))
            {
                &abort(__PACKAGE__ .
                    "::new(): Can't create log directory '$path': $!\n");
            }
        }
    }
    unless (defined ($handle = IO::File->new(">$file")))
    {
        &abort(__PACKAGE__ .
            "::new(): Can't open logfile '$file': $!\n");
    }
    $handle->autoflush(1);
    $user = (&whoami())[0] || '';
    $name = Config::Manager::Conf->get(@FULLNAME) || '';
    $self = { };
    bless($self, $class);
    ${$self}{'test'} = $test; # flag for "called by a test driver"
#   ${$self}{'user'} = $user;
#   ${$self}{'name'} = $name;
#   ${$self}{'tool'} = $tool;
#   ${$self}{'path'} = $path;
    ${$self}{'file'} = $file; # log file name
    ${$self}{'hand'} = $handle; # log file handle
    ${$self}{'hold'} = [ ];   # for putting lines on hold
    ${$self}{'stat'} = [ ];   # for statistics
    ${$self}{'flag'} = 0;     # for automatic dump of logfile name
    ${$self}{'level'} = $SHOW_ALL;
    # (for suppressing messages below the indicated level)
    if (($user ne '') && ($name ne ''))
    {
        $user = "$name ($user)";
    }
    else
    {
        if (($user eq '') && ($name eq ''))
        {
            $user = "(User name not found)";
        }
        elsif ($name ne '')
        {
            $user = $name;
        }
    }
    $time = _LongTime($test);
    $text =
        $RULER .
        "\n $HEADER: $tool - $time - $user\n" .
        $RULER .
        "\n $CMDLINE: " .
        join(' ', map("'$_'", $^X, $0, @ARGV)) .
        "\n";
    $self->report($TO_LOG,$LEVEL_INFO,$text); # increments counter
    ${$self}{'stat'} = [ ]; # reset counters to zero
    return $self;
}

sub report
{
    my($self)    = _which(shift);
    my($command) = shift || 0;
    my($level)   = shift || 0;
    my($text,$leadin,$indent,$item,$handle);
    my($depth,$sub,$file,$line);
    my(@stack,@trace);

    if ($command & $FROM_HOLD)
    {
        return if ($command == $FROM_HOLD + $TO_HLD);
        return unless (@{${$self}{'hold'}} > 0);
        $text = ${$self}{'hold'};
    }
    else
    {
        return if ($level < ${$self}{'level'});
        $leadin = '';
        $indent = '';
        if ($level & $USE_LEADIN)
        {
            $leadin = $LEADIN[0][$level >> 2] . ': ';
            $indent = ' ' x length($leadin);
        }
        $text = [ ];
        foreach $item (@_)
        {
            push( @{$text}, split(/\n/, $item, -1) );
        }
        foreach $item (@{$text})
        {
            $item = $leadin . $item;
            $item =~ s!\s+$!!;
            $item .= "\n";
            $leadin = $indent;
        }
        $depth = $STARTDEPTH;
        if ((($level & $STACKTRACE) || (($level >> 2) >= ($LEVEL_ERROR >> 2))) &&
            (!${$self}{'test'}))
        {
            @trace = ();
            while (@stack = caller($depth++))
            {
                $sub = _adjust(@stack);
                push
                (
                    @trace,
                    $indent . "in $sub\n",
                    $indent . "called at $stack[1] line $stack[2]\n"
                );
            }
####        if ($level & $STACKTRACE)     #
####        {                             # Comment this out if stack
####            $depth = $STARTDEPTH;     # traces are to appear in
####            push( @{$text}, @trace ); # the log file ONLY!
####        }                             #
        }
    }
    if ($command & $TO_LOG)
    {
        $handle = ${$self}{'hand'};
        print $handle join('', @{$text});
        print $handle join('', @trace) if ($depth > $STARTDEPTH);

    }
    if ($command & $TO_ERR)
    {
        print STDERR join('', @{$text});
    }
    if ($command & $TO_OUT)
    {
        print STDOUT join('', @{$text});
    }
    if ($command & $TO_HLD)
    {
        unless ($command & $FROM_HOLD)
        {
            push( @{${$self}{'hold'}}, @{$text} );
            # Comment out next line if stack traces in log file ONLY:
####        push( @{${$self}{'hold'}}, @trace ) if ($depth > $STARTDEPTH);
        }
    }
    if ($command & $FROM_HOLD)
    {
        ${$self}{'hold'} = [ ];
    }
    else
    {
        ${${$self}{'stat'}}[$level >> 2]++;
    }
}

sub trace
{
    my($self) = _which(shift);
    my($first,$depth,$sub,$item);
    my(@stack,@trace,@args);

    # Do nothing if test driver or trace unwanted:
    return if (${$self}{'test'} || ($LEVEL_TRACE < ${$self}{'level'}));
    $first = 1;
    $depth = 1;
    @trace = (); # code "borrowed" from Carp.pm:
    while ( do {{ package DB; @stack = caller($depth++) }} )
    {
        $sub = _adjust(@stack);
        if ($first)
        {
            if ($stack[4]) # $hargs
            {
                @args = @DB::args;
                foreach $item (@args)
                {
                    if (defined $item)
                    {
                        $item = "$item";
                        $item =~ s!([\\\'])!\\$1!g;
                        $item = "'$item'"
                            unless ($item =~ /^-?(?:[1-9]\d*|0)(?:\.\d+)?$/);
#                       $item =~ s!([\x80-\xFF])!'M-'.chr(ord($1)&0x7F)!eg;
                        $item =~ s!([\x00-\x1F\x7F])!'^'.chr(ord($1)^0x40)!eg;
                    }
                    else { $item = "undef"; }
                }
                $sub .= '(' . join(',', @args) . ')';
            }
            else { $sub .= '()'; }
        }
        else { $sub = "in $sub"; }
        push
        (
            @trace,
            $sub,
            "called at $stack[1] line $stack[2]"
        );
        $first = 0;
    }
    $self->report(@TRACE,@trace);
}

sub level
{
    my($self) = _which(shift);
    my($level) = ${$self}{'level'};

    if (@_ > 0)
    {
        ${$self}{'level'} = $_[0] + 0;
    }
    return $level;
}

sub logfile
{
    my($self) = _which(shift);

    return ${$self}{'file'};
}

sub test
{
    my($self) = _which(shift);
    my($test) = ${$self}{'test'};

    if (@_ > 0)
    {
        ${$self}{'test'} = ($_[0] ? 1 : 0);
    }
    return $test;
}

sub notify # set flag for notifying user at exit about where logfile lies
{
    my($self) = _which(shift);
    my($flag) = ${$self}{'flag'};

    if (@_ > 0)
    {
        ${$self}{'flag'} = ($_[0] ? 1 : 0);
    }
    return $flag;
}

sub ret_hold
{
    my($self) = _which(shift);

    if (defined wantarray && wantarray)
    {
        return (@{${$self}{'hold'}});
    }
    else
    {
        return scalar(@{${$self}{'hold'}});
    }
}

sub clr_hold
{
    my($self) = _which(shift);

    ${$self}{'hold'} = [ ];
}

1;

__END__

=head1 NAME

Config::Manager::Report - Error Reporting and Logging Module

=head1 SYNOPSIS

  use Config::Manager::Report qw(:all);

  $logobject = Config::Manager::Report->new([TOOL[,PATH[,TEST]]]);
  $newlogobject = $logobject->new([TOOL[,PATH[,TEST]]]);

  $default_logobject = Config::Manager::Report->singleton();

  $logobject->report($CMD,$LEVEL,@text);
  Config::Manager::Report->report($CMD,$LEVEL,@text);

    Fuer ($CMD,$LEVEL) sollte stets eine der folgenden
    (oeffentlichen) Konstanten verwendet werden:

        @TRACE
        @INFO
        @WARN
        @ERROR
        @FATAL

    Beispiel:
        Config::Manager::Report->report(@ERROR,@text);

  $logobject->trace();
  Config::Manager::Report->trace();

  $logfile = $logobject->logfile();
  $logfile = Config::Manager::Report->logfile();

  [ $oldlevel = ] $logobject->level([NEWLEVEL]);
  [ $oldlevel = ] Config::Manager::Report->level([NEWLEVEL]);

  [ $oldflag = ] $logobject->test([NEWFLAG]);
  [ $oldflag = ] Config::Manager::Report->test([NEWFLAG]);

  [ $oldflag = ] $logobject->notify([NEWFLAG]);
  [ $oldflag = ] Config::Manager::Report->notify([NEWFLAG]);

  $lines = $logobject->ret_hold();
  @text  = $logobject->ret_hold();
  $lines = Config::Manager::Report->ret_hold();
  @text  = Config::Manager::Report->ret_hold();

  $logobject->clr_hold();
  Config::Manager::Report->clr_hold();

=head1 DESCRIPTION

Das Logging ist so realisiert, dass die Ausgabe der Meldungen auf den
verschiedenen Ausgabekanaelen einzeln (unabhaengig voneinander) gesteuert
werden kann. Es gibt die Ausgabekanaele STDOUT, STDERR, Logdatei und Halde.

STDOUT und STDERR sind die ueblichen Standard-Ausgabekanaele. Auf Wunsch
koennen Meldungen aber auch in das Logfile geschrieben werden. Auf der
Halde koennen Meldungen gekellert werden. Die Meldungen werden dann erst
auf Anforderung auf dem Bildschirm ausgegeben.

Bei Verwendung der Funktion "ReportErrorAndExit()" aus dem Modul
"Config::Manager::Base.pm" wird vor Beendigung des Programms die Halde
auf STDERR ausgegeben, falls sie nicht leer ist.

Bei Verwendung der Standard-Konstanten @TRACE @INFO @WARN @ERROR @FATAL
werden alle Meldungen immer auch in die Logdatei geschrieben, damit keine
(moeglicherweise wichtige!) Information verlorengehen kann.

Das sollte man auch dann immer tun, wenn man diese Standard-Konstanten nicht
verwendet.

=over 4

=item *

C<private &_warn_($text,...)>

Dieser Signal-Handler gibt alle Warnungen weiter an das Modul
"Config::Manager::Report.pm", indem er die Methode "report()" aufruft. Trailing
Whitespace im Parameter wird eliminiert - es geht hier vor allem um moegliche
Newlines am Zeilenende, die entfernt werden muessen.

 Parameter: $text - Text der Warnungsmeldung
            ...   - weitere Parameter, die Perl liefert

 Rueckgabe: -

Durch diesen Handler wird sichergestellt, dass auch Warnungen in die Logdatei
geschrieben werden, wo sie zur Aufklaerung von Fehlern nuetzlich sein koennen.

Dies ist in erster Linie fuer externe Module gedacht, die Warnungsmeldungen
absetzen, und nicht fuer Tools der vorliegenden SPU. Letztere sollten statt
"warn" immer die Methode "report()" mit dem Parameter "C<@WARN>" verwenden.

Dieser Signal-Handler wird jedoch nur dann aktiviert, wenn das
Singleton-Log-Objekt angelegt wird (dies geschieht durch alle Aufrufe von
Objekt-Methoden, die statt C<$objekt-E<gt>methode();> die Form
C<Config::Manager::Report-E<gt>methode();> verwenden).

=item *

C<private &_die_($text,...)>

Dieser Signal-Handler gibt alle Ausnahmen weiter an das Modul
"Config::Manager::Report.pm", indem er die Methode "report()" aufruft,
vorausgesetzt das "die" trat nicht waehrend der Compilierung (beim
Programmstart) auf. Trailing Whitespace im Parameter wird eliminiert -
es geht hier vor allem um moegliche Newlines am Zeilenende, die entfernt
werden muessen.

 Parameter: $text - Text der Fehlermeldung
            ...   - weitere Parameter, die Perl liefert

 Rueckgabe: -

Durch diesen Handler wird ermoeglicht, dass man statt "ReportErrorAndExit()"
theoretisch auch einfach nur "die" verwenden kann. Im Unterschied zu ersterem
wird mit "die" aber die Halde nicht mit ausgegeben. Man sollte daher "die"
lieber nicht benutzen. Dieses Feature ist vielmehr dafuer gedacht, dass auf
diese Art und Weise auch "die"s in Modulen abgefangen werden, die nicht zur
SPU gehoeren aber von dieser verwendet werden (Perl Standard-Module, externe
Module wie Net::FTP, usw.), damit auch deren Fehlermeldungen in der Logdatei
landen, wo sie bei der Fehlersuche hilfreich sein koennen.

Dieser Signal-Handler wird jedoch nur dann aktiviert, wenn das
Singleton-Log-Objekt angelegt wird (dies geschieht durch alle Aufrufe von
Objekt-Methoden, die statt C<$objekt-E<gt>methode();> die Form
C<Config::Manager::Report-E<gt>methode();> verwenden).

=item *

C<private &_adjust($pack,$file,$line,$sub,$hargs,$warray,$eval,$require)>

Diese Routine bereitet die Parameter auf, die von der System-Funktion
"caller()" zurueckgeliefert werden.

Die Routine ist aus dem Standard-Modul "Carp.pm" "geklaut"; sie sorgt dafuer,
dass im Stacktrace hinterher die "richtigen" Subroutine-Namen und -Parameter
ausgegeben werden.

 Parameter: $pack    - Package-Name des Aufrufers
            $file    - Dateiname des Aufrufers
            $line    - Zeilennummer des Aufrufers
            $sub     - Name der aufgerufenen Routine
            $hargs   - wahr falls Aufrufparameter vorhanden
            $warray  - wahr falls in List-Kontext aufgerufen
            $eval    - wahr falls eval-Aufruf
            $require - wahr falls require-Aufruf

 Rueckgabe:
            $sub     - aufbereiteter Name der aufgerufenen Routine

=item *

C<private &_ShortTime()>

 Rueckgabe: Die aktuelle Zeit im Format MMTT-HHMMSS

=item *

C<private &_LongTime()>

 Rueckgabe: Die aktuelle Zeit im Format TT.MM. HH:MM:SS

=item *

C<private &_which($self)>

 Parameter: $self - Referenz auf Log-Objekt oder Klassenname

 Rueckgabe: $self, falls $self eine Objekt-Referenz ist,
            oder eine Referenz auf das Singleton-Objekt sonst

Falls der Aufrufparameter eine Referenz ist, wird diese unveraendert
zurueckgegeben.

Falls der Aufrufparameter ein Skalar ist (z.B. durch den Aufruf als
Klassenmethode), wird eine Referenz auf das Default-Log-Objekt (das
sogenannte "Singleton"-Objekt) dieser Klasse zurueckgeliefert.

Falls das Singleton-Objekt noch nicht existiert, wird es durch den Aufruf
dieser Routine erzeugt.

Man kann diese Routine uebrigens sowohl als Funktion als auch als Methode
verwenden; der Aufruf als Funktion ist jedoch etwas schneller.

=item *

C<private $self-E<gt>DESTROY()>

In dieser Methode werden Aktionen definiert, die beim "Tod" eines Log-Objekts
(typischerweise bei Beendigung des Programms, im Rahmen der Global
Destruction) noch durchgefuehrt werden muessen. Dazu gehoeren:

  - Auf (vorherige) Anforderung Ausgabe des Logfilenamens auf dem Bildschirm
  - Den Footer der Logdatei schreiben
  - Logdatei schliessen

 Parameter: $self - Referenz auf das zu zerstoerende Objekt

 Rueckgabe: -

Diese Funktion wird implizit von Perl aufgerufen und darf nicht explizit
aufgerufen werden.

=item *

C<reserved &end()>

Diese Routine setzt die Signal-Handler fuer "warn" und "die" wieder auf
"DEFAULT" zurueck, die moeglicherweise (falls das Singleton-Log-Objekt
benutzt wurde) auf die Routinen "&_warn_()" und "&_die_()" eingestellt
waren.

Dies ist notwendig, um Endlos-Rekursionen im Zusammenhang mit "DESTROY()"
zu vermeiden.

Ausserdem wird hier die Aufloesung des Singleton-Log-Objekts (d.h. der Aufruf
von "DESTROY()" fuer dieses Objekt) getriggert, falls es waehrend des
Programmlaufs erzeugt wurde.

Ohne diese explizite Triggerung der Zerstoerung des Singleton-Objekts wuerde
es zu Fehlern (Footer nicht geschrieben, Datei nicht ordnungsgemaess
geschlossen) kommen.

Dies kann ggfs. auch mit anderen Log-Objekten passieren, falls die letzte
auf sie zeigende Referenz nicht schon B<VOR> der Global Destruction
zurueckgegeben (geloescht) wurde. Man sollte daher die letzte Referenz
auf ein Log-Object z.B. in einer "END"-Routine explizit zuruecksetzen
(z.B. durch Ueberschreiben der Referenz durch einen konstanten Skalar),
falls das nicht automatisch und vorher schon durch das Verlassen
des Scopes (des umschliessenden Code-Blocks in geschweiften Klammern)
der Variablen mit der Referenz geschehen ist.

Damit diese Triggerung funktioniert, duerfen zum Zeitpunkt des Aufrufs von
"END()" im Programm keine Kopien der Referenz auf das Singleton-Objekt mehr
existieren. Mit anderen Worten, der Rueckgabewert der Methode "singleton()"
darf im Programm nicht dauerhaft gespeichert werden.

(Die "singleton()"-Methode sollte sowieso normalerweise NICHT verwendet
werden!)

 Parameter: -

 Rueckgabe: -

Diese Funktion wird implizit von Perl aufgerufen (durch die Funktion "END")
und sollte im Normalfall nicht explizit verwendet werden.

=item *

C<reserved &abort()>

Diese Funktion bricht die Programmausfuehrung ab.

Zuvor wird die Funktion "&end()" aufgerufen, um die Signal-Handler fuer
"die" und "warn" zurueckzusetzen und ggfs. die Default-Log-Datei zu
schliessen.

Anschliessend werden die als Parameter mitgegebenen Zeilen Text auf STDERR
ausgegeben, gefolgt von der Zeile "<Programmabbruch>"; zuletzt wird dann die
Ausfuehrung des Programms beendet.

 Parameter: Beliebig viele Zeilen Fehlermeldung (oder keine)
            (MIT Newlines ("\n") wo gewuenscht!)

 Rueckgabe: -

Der Exit-Code des Programms wird auf 1 gesetzt.

Diese Funktion sollte im Normalfall B<NICHT> verwendet werden (statt dessen
sollte die Funktion "ReportErrorAndExit()" aus dem Modul "Config::Manager::Base.pm"
gerufen werden, die ihrerseits auf der "abort()"-Funktion beruht).

=item *

C<public Config::Manager::Report-E<gt>singleton()>

Diese Methode gibt eine Referenz auf das Singleton-Objekt zurueck.

Das Singleton-Objekt ist die Default-Logdatei. Man ist als Benutzer des
Report-Moduls jedoch nicht gezwungen, dieses Singleton-Objekt zu verwenden (es
wird nur dann automatisch erzeugt, wenn man sich implizit darauf bezieht).
Vielmehr kann man mit diesem Modul beliebig viele Log-Objekte (denen jeweils
eine separate Logdatei und eine eigene Halde zugeordnet sind) erzeugen und
benutzen.

Alle Methodenaufrufe der Form "C<Config::Manager::Report-E<gt>methode();>" beziehen
sich auf das Singleton-Objekt und legen es automatisch an, falls es noch nicht
existiert (genauer gesagt alle Objekt-Methoden, in denen auf den Parameter
"C<$self>" nur ueber die Funktion "C<&_which()>" zugegriffen wird).

 Parameter: -

 Rueckgabe: Gibt eine Referenz auf das Singleton-Objekt zurueck

Falls das Singleton-Objekt noch nicht existiert, wird es durch diesen Aufruf
erzeugt.

"C<Config::Manager::Report-E<gt>methode();>" ist dabei dasselbe wie
"C<Config::Manager::Report-E<gt>singleton()-E<gt>methode();>" oder wie
"C<$singleton = Config::Manager::Report-E<gt>singleton();>" und
"C<$singleton-E<gt>methode();>".

Es sollte jedoch immer die erste dieser Formen
("C<Config::Manager::Report-E<gt>methode();>") verwendet werden. Ausserdem darf der
Rueckgabewert dieser Methode nicht dauerhaft im Programm gespeichert werden,
da sonst das automatische Schliessen der Logdatei nicht funktioniert.

Es gibt im Grunde nur eine einzige sinnvolle Verwendung fuer diese Methode,
naemlich, um die Erzeugung des Singleton-Objekts auszuloesen (wie das
beispielsweise in "Config::Manager::Base.pm" geschieht).

=item *

C<public $class-E<gt>new([$tool[,$path[,$test]]])>

Bei Aufruf - in der Regel bei Toolstart - wird das Logfile angelegt. Ist das
Logverzeichnis nicht vorhanden, so wird auch dieses angelegt.

Danach wird der Header des Logfiles geschrieben. Dieser enthaelt z.B. Uhrzeit,
Namen des Aufrufers und Kommandoaufruf samt Optionen.

 Parameter: $class - Name der Klasse oder Objekt derselben Klasse wie Neues
            $tool  - Optional; wird kein Toolname uebergeben, so wird er
                     in der Funktion ermittelt
            $path  - Optional; wird kein Logpfad angegeben, so wird er aus
                     der Konfiguration ausgelesen
            $test  - Optional; hier kann eingestellt werden, dass man sich
                     im Testtreibermodus befindet. Abhaengig davon werden
                     manche Aktionen im Ablauf anders behandelt, z.B. fuer
                     Regressionstests die Angabe eines Einheitsdatums.

 Rueckgabe: -

Diese Methode muss (d.h. darf) nicht explizit aufgerufen werden, falls man nur
die Default-Logdatei ("Singleton-Log-Objekt") verwenden will (in diesem Fall
ist statt dessen die Methode "singleton()" zu verwenden).

=item *

C<public $self-E<gt>report($command[,$level[,@zeilen]])>

Die Funktion realisiert das bereits im allgemeinen Teil beschriebene
Loggingkonzept. Meldungen werden auf Anforderung entsprechend eingerueckt.

 Besonderheit: Der Stacktrace wird nie auf dem Bildschirm ausgegeben,
               sondern nur in das Logfile. Damit sind fuer den Benutzer
               die Fehlermeldungen uebersichtlicher.

 Parameter: $self     - Referenz auf Log-Objekt oder Klassenname
            (Es wird das Singleton-Objekt verwendet, falls die Methode
            als Klassen- und nicht als Objekt-Methode aufgerufen wurde)
            $command  - Angabe darueber, wohin die Meldung geleitet
                        werden soll. Moegliche Werte:
                            $TO_HLD $TO_OUT $TO_ERR $TO_LOG
                            $FROM_HOLD $USE_LEADIN $STACKTRACE
                        Diese Werte koennen beliebig durch Addition
                        kombiniert werden.
            $level    - Auf welcher Stufe ist die Meldung einzuordnen:
                            $LEVEL_TRACE $LEVEL_INFO $LEVEL_WARN
                            $LEVEL_ERROR $LEVEL_FATAL
            @zeilen   - Beliebig viele weitere Parameter. Jeder wird als
                        Textzeile fuer das Log interpretiert. Die Zeilen
                        sollten nicht mit Newlines abgeschlossen werden,
                        ausser man will (entsprechend viele) Leerzeilen
                        nach der betreffenden Meldungszeile erzwingen.

 Rueckgabe: -

Es ist moeglich, Newlines im Inneren der Meldungszeilen zu verwenden; dies
sollte jedoch vermieden werden (Einrueckungen erfolgen dennoch auch bei
Verwendung von eingebetteten Newlines "richtig").

Generell sollte jedes Element der Parameterliste eine Zeile der Meldung
darstellen, und es sollten keinerlei Newlines verwendet werden, auch und
insbesondere nicht am Zeilenende.

Mit Hilfe des Kommando-Bestandteils "$FROM_HOLD" lassen sich die Inhalte der
Halde wiederum auf STDOUT, STDERR und/oder in die Logdatei ausgeben, z.B. wie
folgt:

    Config::Manager::Report->report($FROM_HOLD+$TO_ERR);

Durch die Verwendung von "$FROM_HOLD" wird die Halde automatisch (nach ihrer
Ausgabe) geloescht, ausser bei einem Kommando wie

    Config::Manager::Report->report($FROM_HOLD+$TO_HLD);

welches (da sinnlos) vollstaendig ignoriert wird.

Die Methode zaehlt automatisch die Anzahl der Meldungen, die auf jedem Level
ausgegeben wurden, mit - unabhaengig davon, auf welchem Kanal (STDOUT, STDERR,
Halde oder Logdatei) diese Meldungen ausgegeben wurden.

Meldungen, die zuerst auf die Halde gelegt wurden und spaeter von dort aus
(mit Hilfe des Kommando-Bestandteils "$FROM_HOLD") auf einem der anderen
Kanaele ausgegeben werden, werden nicht noch einmal gezaehlt (das ginge auch
schon allein deshalb nicht, weil der Level der Meldung zu diesem Zeitpunkt
nicht mehr bekannt ist).

Diese kleine "Statistik" wird von der Methode "DESTROY()" mit in den Footer
der Logdatei geschrieben.

=item *

C<public $self-E<gt>trace()>

Diese Methode erlaubt es, Funktions- und Methodenaufrufe zu "tracen".

 Parameter: $self     - Referenz auf Log-Objekt oder Klassenname
            (Es wird das Singleton-Objekt verwendet, falls die Methode
            als Klassen- und nicht als Objekt-Methode aufgerufen wurde)

 Rueckgabe: -

Indem man die Zeile

     Config::Manager::Report->trace();

 (unter Verwendung der Default-Logdatei) oder

     $objekt->trace();

 (unter Verwendung der dem "$objekt" zugeordneten Logdatei)

ganz an den Anfang einer Funktion (insbesondere VOR irgendwelche
"shift"-Anweisungen, die sich auf die Aufrufparameter beziehen!) oder Methode
setzt, wird automatisch ein Stacktrace, zusammen mit allen Aufrufparametern
der aktuellen Funktion oder Methode, in die betreffende Logdatei geschrieben.

Setzt man den Ausgabe-"Level" (siehe dazu auch die Methode "C<level()>" direkt
hierunter) vom Default-Wert ("C<$LEVEL_TRACE>") auf den Wert "C<$LEVEL_INFO>",
werden alle Trace-Ausgaben effizient unterdrueckt, d.h. Trace-Informationen
werden dann gar nicht erst erzeugt, sondern die Methode "C<trace()>" kehrt
sofort (nach einem "C<if>") mit "C<return>" zur aufrufenden Routine zurueck.

=item *

C<public $self-E<gt>level([$value])>

Gibt den bisherigen Level des Loggings zurueck. Kann auch dazu verwendet
werden, diesen Level zu setzen, falls im Aufruf ein Wert angegeben wurde.

Moegliche Werte in diesem Zusammenhang sind:

    $SHOW_ALL $LEVEL_TRACE $LEVEL_INFO
    $LEVEL_WARN $LEVEL_ERROR $LEVEL_FATAL

Es sollten stets nur diese vordefinierten Konstanten zum Setzen des Levels
verwendet werden.

Das Setzen eines Levels groesser als Null (= Konstante "C<$SHOW_ALL>", bzw.
"C<$LEVEL_TRACE>", die Default-Einstellung) bewirkt, dass alle Meldungen
mit einem Level kleiner als diesem Wert unterdrueckt werden (und insbesondere
auch nicht in der Logdatei erscheinen).

 Parameter: $self     - Referenz auf Log-Objekt oder Klassenname
            (Es wird das Singleton-Objekt verwendet, falls die Methode
            als Klassen- und nicht als Objekt-Methode aufgerufen wurde)
            $value    - Optional der neue Wert

 Rueckgabe: Es wird immer der bisherige Wert zurueckgeliefert.

=item *

C<public $self-E<gt>logfile()>

Gibt den Namen und Pfad der Logdatei des betreffenden Log-Objekts zurueck.

 Parameter: $self     - Referenz auf Log-Objekt oder Klassenname
            (Es wird das Singleton-Objekt verwendet, falls die Methode
            als Klassen- und nicht als Objekt-Methode aufgerufen wurde)

 Rueckgabe: Gibt den Namen und Pfad der Logdatei zurueck.

=item *

C<public $self-E<gt>test([$value])>

Gibt den bisherigen Wert des Flags zurueck, das angibt, ob man sich im
Testtreiber-Modus befindet. Kann auch dazu verwendet werden, dieses Flag zu
setzen oder zu loeschen, falls im Aufruf ein Wert angegeben wurde.

 Parameter: $self     - Referenz auf Log-Objekt oder Klassenname
            (Es wird das Singleton-Objekt verwendet, falls die Methode
            als Klassen- und nicht als Objekt-Methode aufgerufen wurde)
            $value    - Optional der neue Wert

 Rueckgabe: Es wird immer der bisherige Wert zurueckgeliefert.

=item *

C<public $self-E<gt>notify([$value])>

Gibt den bisherigen Wert des Flags zurueck, das angibt, ob bei Programmende
der Name und Pfad der Logdatei auf dem Bildschirm ausgegeben werden soll. Kann
auch dazu verwendet werden, dieses Flag zu setzen oder zu loeschen, falls im
Aufruf ein Wert angegeben wurde.

 Parameter: $self     - Referenz auf Log-Objekt oder Klassenname
            (Es wird das Singleton-Objekt verwendet, falls die Methode
            als Klassen- und nicht als Objekt-Methode aufgerufen wurde)
            $value    - Optional der neue Wert

 Rueckgabe: Es wird immer der bisherige Wert zurueckgeliefert.

=item *

C<public $self-E<gt>ret_hold()>

In List-Kontext:

Gibt die Halde des betreffenden Objekts (als Liste von Zeilen) zurueck (ohne
sie zu veraendern).

In Scalar-Kontext:

Gibt die Anzahl der Zeilen zurueck, die sich auf Halde befinden.

 Parameter: $self     - Referenz auf Log-Objekt oder Klassenname
            (Es wird das Singleton-Objekt verwendet, falls die Methode
            als Klassen- und nicht als Objekt-Methode aufgerufen wurde)

 Rueckgabe: Liste der Zeilen der Halde
            (jedes Element der Liste ist eine Zeile der Halde)
            - oder -
            Anzahl der Zeilen auf der Halde

=item *

C<public $self-E<gt>clr_hold()>

Loescht die Halde des betreffeden Objekts.

 Parameter: $self     - Referenz auf Log-Objekt oder Klassenname
            (Es wird das Singleton-Objekt verwendet, falls die Methode
            als Klassen- und nicht als Objekt-Methode aufgerufen wurde)

 Rueckgabe: -

=back

=head1 HISTORY

 2003_02_05  Steffen Beyer & Gerhard Albers  Version 1.0
 2003_02_14  Steffen Beyer                   Version 1.1

