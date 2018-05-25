# TechSAS Data Utilities
#
# JPRO 17/05/2018
#

package TechSAS;
use strict;

use File::Basename;

use lib '/packages/techsas/current/lib';
use TechSAS::NMEA;
use TechSAS::NetCDF;

my $TECHSAS_PATH = "/data/cruise/dy/current/TechSAS";

sub new {
	my $class = shift;

	my $self = bless {
		name   => undef,
		stream => undef,
		record => undef,
		vars   => undef,
		path   => $TECHSAS_PATH,
		nmea   => undef,
		netcdf => undef,
	}, $class;

	$self->{netcdf} = TechSAS::NetCDF->new($self->{path});
	
	return $self;
}

sub list_streams {
	my $self = shift;

	return $self->{netcdf}->list_streams();
}

sub name {
	my $self = shift;
	
	return $self->{netcdf}->name();
}

sub vars {
	my $self = shift;

	return $self->{netcdf}->vars();
}

sub attach {
	my ($self, $stream) = @_;

	return $self->{netcdf}->attach($stream);
}

sub detach {
	my $self = shift;

	return if !$self->{stream};
	undef $self->{stream};

	delete $self->{record};
	$self->{name} = undef;
	$self->{vars} = undef;
}

sub next_record {
	my $self = shift;

	return undef;
}

sub last_record {
	my $self = shift;

	return undef;
}

1;
