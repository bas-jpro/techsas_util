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

# Return list of positions in @vals for each variable given
sub get_vars_pos {
	my ($self, @varnames) = @_;

	my $vars = $self->{netcdf}->vars();
	
	my %var_lookup;
	my $i = 0;
	foreach (@$vars) {
		$var_lookup{$_->{name}} = $i;
		$i++;
	}

	my @ps;
	foreach (@varnames) {
		die basename($0) . ": $self->{name} attach failure, mismatch [$_]\n" if !defined($var_lookup{$_});

		push(@ps, $var_lookup{$_});
	}

	return @ps;
}

sub attach {
	my ($self, $stream) = @_;

	return $self->{netcdf}->attach($stream);
}

sub detach {
	my $self = shift;

	return $self->{netcdf}->detach();
}

sub next_record {
	my $self = shift;

	return undef;
}

sub last_record {
	my $self = shift;

	return undef;
}

sub find_time {
	my ($self, $tstamp) = @_;

	return $self->{netcdf}->find_time($tstamp);
}


1;
