#!/bin/perl

## Configuration Manager package Version 1.001b
## (c) 1998 by Massimiliano Pala (madwolf@openca.org)
## Released under the GPL ( General Public Licence ) Terms
##
## The porpouse of this new class is the same of some other classes
## found at CPAN : being able to read and parse with little efforts
## complex ( and simple ) configuration files. This Module is oriented
## to the Apache/OpenLDAP/ecc... configuration file format.
##
## Read the DOC before using this module, and take a look at the
## Examples section if you are not familiar with accessing Lists of
## Hases.

## Env Variables
$ver = "1.001b";

## Asking Section
print "\n\nConfiguration Manager package Version $ver\n";
print "(c) 1998/1999 by Massimiliano Pala (madwolf\@openca.org)\n";
print "Released under the GPL ( General Public Licence ) Terms\n\n";

print "Enter the directory where you want to install the module\n";
print "(Defaults to /usr/local/perl) : ";

$dir = <STDIN>;
chop( $dir );
$dir = '/usr/local/perl' unless $dir;

print "\n";
print "Creating Directory $dir/OPENCA ... ";
if( mkdir( "$dir/OPENCA", 755 ) == 0 ) {
	if ( "$!" =~ /File exists/i ) {
		print "($!) ... "; 
	} else {	
		print "Error!";
		print "\n\nCreation Failed : $!\n\n";
		exit 100;
	}
}
print "Done.\n";

$files = "ConfigManager.pm";
$cmd   = "cp $files $dir/OPENCA >/dev/null 2>&1";

print "Copying $files to $dir/OPENCA ... ";
system( $cmd );

if( $? != 0 ) {
	print "Error.\n\nCopying Failed : $!\n\n";
	exit 101;
} else {
	print "Done.\n";
};

print "\n\nInstallation Successful, refer to DOC for usage instructions\n\n";
exit 0;

