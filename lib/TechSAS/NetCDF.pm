# TechSAS NetCDF Data Utilities
#
# JPRO 17/05/2018
#

package TechSAS::NetCDF;
use strict;

use File::Basename;

my $GET_VARS = '/packages/techsas/current/bin/get_vars';
my $GET_TIME = '/packages/techsas/current/bin/get_time';
my $NETCDF_DIR = 'NetCDF';

sub new {
	my ($class, $path) = @_;
	die "No path given\n" unless $path;
	
	my $self = bless {
		path     => $path  . '/' . $NETCDF_DIR,
		filename => undef,
		stream   => undef,
		record   => {
			timestamp => undef,
			vals      => undef,
		},
		vars     => undef,
		tpos     => undef,
	}, $class;

	return $self;
}

sub list_streams {
	my $self = shift;

	# NetCDF files are stored by class (e.g GPS, DEPTH)
	opendir(TD, $self->{path});
	my @classes = grep { !/^\./ && (-d "$self->{path}/$_") } readdir(TD);
	closedir(TD);

	my %streams = ();
	
	# Each directory has files of the form YYYYMMDD-HHMMSS-type-name.ext
	foreach my $c (@classes) {
		opendir(TD, "$self->{path}/$c");
		my @files = grep { !/^\./ && (!-d "$self->{path}/$c/$_") } readdir(TD);
		closedir(TD);

		foreach my $f (@files) {
			if ($f =~ /^\d{8}-\d{6}-([^-]+)-([^\.]+)\./) {
				$streams{"$c-$2-$1"} = 1; 
			}
		}
	}
		
	return (sort keys %streams);
}

sub attach {
	my ($self, $stream) = @_;
	die basename($0) . ": no stream given\n" unless defined($stream);

	my ($class, $name, $type) = (split('-', $stream));

	# Extension is class name, but can be upper or lower case
	my $file = join('-', $type, $name);

	opendir(TD, "$self->{path}/$class");
	my @files = sort grep { /^\d{8}-\d{6}-$file/ } readdir(TD);
	closedir(TD);

	die basename($0) . ": Failed to attach $stream - no files [$file]\n" unless scalar(@files);

	$self->{filename} = $files[0];
	die basename($0) . ": Failed to attach $stream - no stream [$self->{filename}]\n" if !-e "$self->{path}/$class/$self->{filename}";
	
	$self->{name}  = $stream;
	$self->{class} = $class;
	$self->{stream} = "$self->{path}/$class/$self->{filename}";

	$self->{filestart} = 		
}

sub name {
	my $self = shift;
	return unless $self->{stream};
	
	return $self->{name};
}

sub vars {
	my $self = shift;
	return unless $self->{stream};

	return $self->{vars} if $self->{vars};

	$self->{vars} = [];
	open(CMD, "$GET_VARS $self->{stream} |");
	while (<CMD>) {
		chop;
		my ($var, $unit) = (split(/\s+/, $_, 2));

		push(@{ $self->{vars} }, { name => $var, units => $unit });
	}
	close(CMD);

	return $self->{vars};
}

sub detach {
	my $self = shift;

	$self->{name} = $self->{class} = $self->{stream} = $self->{filename} = undef;
	$self->{vars} = undef;
}

# Inefficient, using a C program to get time 
sub next_record {
	my $self = shift;

	
}

# Uses C get_time to find time one file has been found
sub find_time {
	my ($self, $tstamp) = @_;

	
}

1;
