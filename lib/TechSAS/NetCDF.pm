# TechSAS NetCDF Data Utilities
#
# JPRO 17/05/2018
#

package TechSAS::NetCDF;
use strict;

use File::Basename;
use Time::Local;
use POSIX;

my $GET_VARS   = '/packages/techsas/current/bin/get_vars';
my $GET_TIME   = '/packages/techsas/current/bin/get_time';
my $NETCDF_DIR = 'NetCDF';
my $DAYLEN     = 86400;	 # Length of day in seconds
my $MAXDIFF    = 60; # Data can be no more than 1 minute old

sub new {
    my ($class, $path) = @_;
    die "No path given\n" unless $path;
    
    my $self = bless {
	path	 => $path  . '/' . $NETCDF_DIR,
	filename => undef,
	stream	 => undef,
	record	 => {
	    timestamp => undef,
	    vals	  => undef,
	},
	vars	 => undef,
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
    
    $self->{name} = $stream;
    $self->_find_oldest_file();
    die basename($0) . ": Failed to attached $stream - no file\n" unless $self->{filename};
    
    $self->_load_file();
}

sub _extract_name {
    my $self = shift;
    return unless $self->{name};

    # Name can contain '-'
    my @fs = split('-', $self->{name});

    return ($fs[0], join('-', @fs[1..$#fs-1]), $fs[$#fs]);
}

sub _find_oldest_file {
    my $self = shift;
    return unless $self->{name};
    
    my ($class, $name, $type) = $self->_extract_name();
    
    # Extension is class name, but can be upper or lower case
    my $file = join('-', $type, $name);
    
    opendir(TD, "$self->{path}/$class");
    my @files = sort grep { /^\d{8}-\d{6}-$file/ } readdir(TD);
    closedir(TD);
    
    die basename($0) . ": Failed to attach $self->{name} - no files [$file]\n" unless scalar(@files);
    
    $self->{filename} = $files[0];
    die basename($0) . ": Failed to attach $self->{name} - no stream [$self->{filename}]\n" if !-e "$self->{path}/$class/$self->{filename}";
    
    $self->{class} = $class;
}

# Find a file that contains a given timestamp
sub _find_file {
    my ($self, $tstamp) = @_;
    
    my ($class, $name, $type) = $self->_extract_name();
    
    # Extension is class name, but can be upper or lower case
    my $file = join('-', $type, $name);
    
    # Get list of files - backwards so newest file is latest
    opendir(TD, "$self->{path}/$self->{class}");
    my @files = reverse sort grep { /^\d{8}-\d{6}-$file/ } readdir(TD);
    closedir(TD);
    
    $self->{filename} = undef;
    return unless scalar(@files);
    
    # Search through files and get start/end tstamp of each to find file
    foreach my $f (@files) {
	my $start_time = $self->_start_time($f);
	
	# print STDERR "Comparing [$f], $start_time with $tstamp\n";
	
	if ($tstamp >= $start_time) {
	    # print STDERR "time is in file [$f]\n";
	    $self->{filename} = $f;
	    last;
	}
    }
	
    die basename($0) . ": Failed to attach $self->{name} - no stream [$self->{filename}]\n" if !-e "$self->{path}/$class/$self->{filename}";
}

sub _load_file {
    my $self = shift;
    return unless $self->{filename};
    
    $self->{stream} = "$self->{path}/$self->{class}/$self->{filename}";
    
    $self->{file_start} = $self->_start_time($self->{filename});
}

sub _start_time {
    my ($self, $filename) = @_;
    
    if ($filename =~ /^(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})/) {
	my ($year, $month, $day, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
	
		return timegm($sec, $min, $hour, $day, $month - 1, $year - 1900);
    }
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
    $self->{vars} = $self->{file_start} = undef;
    
    $self->{record} = undef;
}

# Inefficient, using a C program to get time 
sub next_record {
    my $self = shift;   
}

# Uses C get_time to find time one file has been found
sub find_time {
    my ($self, $tstamp) = @_;
    return unless $self->{stream};
    
    # print STDERR "Looking for $tstamp, current file starts at " . $self->{file_start} . "\n";
    
    # First find oldest file to check if time is before start of data
    $self->_find_oldest_file();
    $self->_load_file();
    
    if ($tstamp < $self->{file_start}) {
	# At start of file
	# print STDERR "Before start of first file, returning\n";
	return;
    }
    
    # Find out if we need to move file
    if ($tstamp >= $self->{file_start} + $DAYLEN) {
	# print STDERR "New file needed\n";
	$self->_find_file($tstamp);
	
	# return if we didn't find a time
	return unless $self->{filename};
	
	$self->_load_file();
    }
    
    # Time is current this file
    #	print STDERR "Time is in current file\n";
    
    # Use C routine to extract data from file
    my $cmd = "$GET_TIME $self->{stream} $tstamp $MAXDIFF";
    # print STDERR "Running [$cmd]\n";
    
    my @vals = ();
    open(CMD, "$cmd |");
    while (<CMD>) {
	chop;
	push(@vals, $_);
    }
    close(CMD);
    
    # Output is tstamp, then 1 val per line - check against vals
    $self->vars();
    
    if (scalar(@vals) != (scalar(@{ $self->{vars} }) + 1)) {
	#print STDERR "Only read " . scalar(@vals) . " instead of " . (scalar(@{ $self->{vars}}) + 1) . "\n";

	# Try search all day files if we haven't found it in the right file
	return $self->_find_time_day_files($tstamp);
	return undef;
    }
    
    $self->{record}->{timestamp} = shift @vals;
    $self->{record}->{vals} = \@vals;
    
    return $self->{record};
}

# Find all files for a given day
# Search for tstamp in each one - sometimes techsas saves times in wrong file
sub _find_time_day_files {
    my ($self, $tstamp) = @_;
    return unless $self->{name} && defined($tstamp);

    my $date = POSIX::strftime("%Y%m%d", gmtime($tstamp));
    
    my ($class, $name, $type) = $self->_extract_name();
    
    # Extension is class name, but can be upper or lower case
    my $file = join('-', $type, $name);
    
    opendir(TD, "$self->{path}/$class");
    my @files = sort grep { /^$date-\d{6}-$file/ } readdir(TD);
    closedir(TD);

    die basename($0) . ": Failed to attach $self->{name} - no files [$file]\n" unless scalar(@files);
    
    $self->{class} = $class;

    foreach my $f (@files) {
	# print STDERR "Checking in [$f]\n";
	$self->{filename} = $f;
	$self->_load_file();
	
	die basename($0) . ": Failed to attach $self->{name} - no stream [$self->{filename}]\n" if
	    !-e "$self->{path}/$class/$self->{filename}";

	# Use C routine to extract data from file
	my $cmd = "$GET_TIME $self->{stream} $tstamp $MAXDIFF";
	# print STDERR "Running [$cmd]\n";
	
	my @vals = ();
	open(CMD, "$cmd |");
	while (<CMD>) {
	    chop;
	    push(@vals, $_);
	}
	close(CMD);
	
	# Output is tstamp, then 1 val per line - check against vals
	$self->vars();
	
	if (scalar(@vals) != (scalar(@{ $self->{vars} }) + 1)) {
	    #print STDERR "Only read " . scalar(@vals) . " instead of " . (scalar(@{ $self->{vars}}) + 1) . "\n";
	    next;
	}

	# We found it 
	$self->{record}->{timestamp} = shift @vals;
	$self->{record}->{vals} = \@vals;

	return $self->{record};
    }

    return undef;
}

1;
