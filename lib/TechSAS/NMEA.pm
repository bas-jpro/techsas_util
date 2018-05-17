# TechSAS NMEA Data Utilities
#
# JPRO 17/05/2018
#

package TechSAS::NMEA;
use strict;

my $NMEA_DIR = 'NMEA';

sub new {
	my ($class, $path) = @_;
	die "No path given\n" unless $path;
	
	my $self = bless {
		path => $path  . '/' . $NMEA_DIR,
	}, $class;

	return $self;
}

sub list_streams {
	my $self = shift;

	opendir(TD, $self->{path});
	my @streams = grep { !/^\./ && (-d $self->{path} . "/$_") } readdir(TD);
	closedir(TD);
	
	return @streams;
}

1;
