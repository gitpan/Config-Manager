## Configuration Manager package Version 1.001b
## (c) 1998 by Massimiliano Pala
##     All Rights Reserved
##
## Porpouse : build a class to manage Configuration in prg
##	      that need configurations without having to
##	      access directly to it and make a config
##	      standard; if the format will change the old
##	      CGI are still up-to-date.
##
## Project Status:
##
##      Started		: 08 December 1998
##      Last Modified	: 03 February 1999

package OPENCA::ConfigManager;
require 5.001;

## Define Error Messages for the Configuration Manager Errors
my $cgiManager  = 'Massimiliano Pala <madwolf@comune.modena.it>';
my $configDim   = 0;

my @configLines = ();
my @configDB    = ();
my @errorCodes  = { '100', 'Configuration File Not Found',
		    '101', 'Keyword error.'}; 

## Create an instance of the Class
sub new {
	my $self = {};
	bless $self;

	$fileName = $keys[1];
	if( "$fileName" ne "" ) {
		$self->loadCfg ( $fileName );
	}

	return $self;
}

## Configuration Manager Functions
sub loadCfg {
	my $self = shift;
	my $ret = 0;
	my @keys; 
	@keys = @_;

	$fileName = $keys[0];

	open( FD, "$fileName" ) || return 100;
	while( $temp = <FD> ) {
		@configLines = ( @configLines, $temp );
	}
	close(FD);

	$ret = $self->parsecfg( @configLines );
	return $ret;
}

## Parsing Function
sub parsecfg {
	my $self = shift;
	my @keys;
	my $num = -1;
	@keys = @_;

	@configDB = ();
	
	foreach $line (@keys) {
		my $paramName;
		my %par;
		my @values;

		## Take count of Config Line Number
		$num++;

		## Trial line and discard Comments
		chop($line);
		next if ($line =~ /\#.*/)||($line eq "")||($line =~ /HASH.*/);
		$line =~ s/#.*//;
		$line =~ s/[\s]*//;

		## Get the Parameter Name
		( $paramName ) = 
			( $line =~ /([\S]+).*/ );

		## Erase the parameter Name from the Line
		$line =~ s/$paramName// ;

		@values = ();

		## Start displacing command
		while ( length($line) > 0 ) {
			my $param = "";


			## Delete remaining Spaces
			$line =~ s/[\s]*//;

			if ( $line =~ /^[\s]*\"/ ) {
				( $param ) = ( $line =~ /[\s]*\"([^\"]*)/ );
			} else {
				( $param ) = ( $line =~ /[\s]*([\S]+)*/ );
			};

			@values = ( @values, $param );

			$line =~ s/$param//;
			$line =~ s/""//;

		}

		## Get the parameter set up
		$par = { NAME=>$paramName,
		 	 LINE_NUMBER=>$num,
		 	 VALUES=>[ @values ] };

		push @configDB, $par;
	}

	return @configDB;
}

## Get Single Parameter
sub getParam {
	my $self = shift;
	my %ret = {};
	my @keys;
	my @par = ();
	@keys = @_;

	return $self->getNextParam( NAME=>$keys[0],
		LINE_NUMBER=>-1 );
};

## Get next Parameter	 
sub getNextParam {
	my $self = shift;
        my %k = @_;
	my %par = {};
	
	return unless ( $#_ > 0 );

	foreach $par ( @configDB ) {
		my $tmp = $par->{NAME};
		$tmp =~ s/^$k{NAME}//i;

		if ( ( "$tmp" eq "" ) &&
				( $par->{LINE_NUMBER} > $k{LINE_NUMBER})  ) {
			return $par;
		};
	};

	return;
}


___END___;
