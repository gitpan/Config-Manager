#!perl -w

package Config::Manager::listconf;

use strict;
no strict "vars";

print "1..30\n";

$n = 1;

eval
{
    require Config::Manager::Base;
    Config::Manager::Base->import();
};
if ($@)
{
    print "not ok $n\n";
    $n++;
    print "not ok $n\n";
}
else
{
    print "ok $n\n";
    $n++;
    if ($Config::Manager::Base::VERSION eq '1.4')
    {print "ok $n\n";} else {print "not ok $n\n";}
}
$n++;

eval
{
    require Config::Manager::Conf;
    Config::Manager::Conf->import();
};
if ($@)
{
    print "not ok $n\n";
    $n++;
    print "not ok $n\n";
}
else
{
    print "ok $n\n";
    $n++;
    if ($Config::Manager::Conf::VERSION eq '1.4')
    {print "ok $n\n";} else {print "not ok $n\n";}
}
$n++;

eval
{
    require Config::Manager::User;
    Config::Manager::User->import(qw(user_id user_conf));
};
if ($@)
{
    print "not ok $n\n";
    $n++;
    print "not ok $n\n";
}
else
{
    print "ok $n\n";
    $n++;
    if ($Config::Manager::User::VERSION eq '1.4')
    {print "ok $n\n";} else {print "not ok $n\n";}
}
$n++;

$user = $Config::Manager::Base::VERSION +
        $Config::Manager::Conf::VERSION +
        $Config::Manager::User::VERSION;

if (defined ($user = &user_id()))
{print "ok $n\n";} else {print "not ok $n\n";$user='';}
$n++;

if (defined ($conf = &user_conf($user)))
{print "ok $n\n";} else {print "not ok $n\n";$conf=Config::Manager::Conf->new();}
$n++;

if (defined ($list = $conf->get_all()))
{print "ok $n\n";} else {print "not ok $n\n";$list=[];}
$n++;

@compare =
(
    '  $[DEFAULT]{CONFIGPATH} = "t"',
    '  $[DEFAULT]{LASTCONF} = "t/soft_defaults.ini"',
    '  $[DEFAULT]{LOGFILEPATH} = "."',
    '  $[DEFAULT]{PROJCONF} = "t/project.ini"',
    '  $[DEFAULT]{USERCONF} = "t/user.ini"',
    '  $[Eureka]{Hat_geklappt} = "Juppie"',
    '  $[Manager]{NEXTCONF} = "t/hard_defaults.ini"',
    '  $[Person]{Name} = "Steffen Beyer"',
    '  $[Person]{Telefon} = "0162 77 49 721"',
    '  $[TEST]{NEXTCONF} = "t/TEST.ini"'
);

$index = 0;
for ( $count = 0; $count < @{$list}; $count++ )
{
    $line = ${$list}[$count];
    $line =~ s!\s+$!!;
    next if ($line =~ /^\s+\$\[(?:ENV|SPECIAL)\]/);
    if ($line eq $compare[$index])
    {print "ok $n\n";} else {print "not ok $n\n";}
    $index++;
    $n++;
}

$self = '02____example.t';

if (-d $self)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

opendir(DIR, $self);
@dir = sort grep !/^\./, readdir(DIR);
closedir(DIR);

$file = $dir[$#dir];

if ($file =~ m!^02____example\.t-\d{6}-\d{6}-\d+-\d+\.log$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (-f "$self/$file")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

open(FILE, "<$self/$file");
@log = <FILE>;
close(FILE);

if (@log == 7)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($log[0] =~ m!^_+$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($log[1] =~ m!^\s*$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($log[2] =~ m!^ STARTED: 02____example\.t - \d\d-[A-Z][a-z][a-z]-\d+ \d\d:\d\d:\d\d - Steffen Beyer \(.*?\)$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($log[3] =~ m!^_+$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($log[4] =~ m!^\s*$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($log[5] =~ m!^ COMMAND: '[^']+' 't.02____example\.t'$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($log[6] =~ m!^\s*$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

