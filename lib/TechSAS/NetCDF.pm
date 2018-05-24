# TechSAS NetCDF Data Utilities
#
# JPRO 17/05/2018
#

package TechSAS::NetCDF;
use strict;

use File::Basename;

my $NETCDF_DIR = 'NetCDF';

sub new {
	my ($class, $path) = @_;
	die "No path given\n" unless $path;
	
	my $self = bless {
		path     => $path  . '/' . $NETCDF_DIR,
		filename => undef,
		stream   => undef,
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
	
	$self->{name}   = $stream;
#	$self->{stream} = new IO::File "$self->{path}/$class/$self->{filename}", O_RDONLY ;
#
#	if (!$self->{stream}) {
#		die basename($0). ": Failed to attach $stream\n";
#	}
#
#	$self->{stream}->blocking(0);	
}

1;
