
package Elevation::Dgm1;

# this was programmed 2021 by tjabo vierbuecher, licence: GPL v3

# Base:
# https://rapidlasso.com/2017/01/03/first-open-lidar-in-germany/
# https://www.opengeodata.nrw.de/produkte/geobasis/hm/3dm_l_las/3dm_l_las_paketiert/

#    https://www.opengeodata.nrw.de/produkte/geobasis/hm/dgm1_xyz/
#    Gemeinden: https://www.opengeodata.nrw.de/produkte/geobasis/hm/dgm1_xyz/dgm1_xyz_paketiert/
#    Einzelkacheln: https://www.opengeodata.nrw.de/produkte/geobasis/hm/dgm1_xyz/dgm1_xyz/

# Files like 
#   dgm1_32430_5634_2_nw.xyz
#   dgm1_32430_5636_2_nw.xyz

# OSM-Karte mit UTM: https://www.netzwolf.info/ol2/utmgrid.html

use parent 'Elevation';

use strict;
use warnings;
use Math::Round;
use Geo::Coordinates::UTM qw(latlon_to_utm);
use Data::Dumper;

sub new
{
	my( $class, $height_dir, $tmp_dir, $correction ) = @_;

	my $self = bless { 
		height_dir => $height_dir,
		tmp_dir => $tmp_dir,
		correction => $correction,
		elevations => {},
		loaded_files => {},
		tests => 0,
	}, $class;

}

sub ll
{
	my( $self, $model, $lat, $lon ) = @_;

# 	if ($self->{ tests } == 0)
# 	{
# 		$self->{ tests } = 1;
# 		$self->load_dgm1_file( "dgm1_test.xyz" );
# 		print Dumper( $self->{ elevations } );
# 	}

	my ($zone, $east, $north) = latlon_to_utm( 23, $lat, $lon );
	$east = round($east);   # aka Rechtswert
	$north = round($north); # aka Hochwert
	# print "lat=$lat, lon=$lon -> z $zone, east=$east, north=$north\n";

	# read dgm1 file if data not present:
	my $dgm1file = $self->get_dgm1_filename( $zone, $east, $north );
	if (! $self->{ loaded_files }->{ $dgm1file } )
	{
		$self->load_dgm1_file( $dgm1file ) or die("cannot load dgm1 data from '$dgm1file'\n");
	}

	# get elevation of dot:
	# TODO: map height into minheight and maxheight of area, needs more options?
	my $minheight = 220; # m
	my $maxheight = 492; # m

	my $dotkey = $self->get_dotkey( $zone, $east, $north );
	my $elev = $self->{ elevations }->{ $dotkey };
	if (defined($elev) and ($elev >= $minheight) && ($elev <= $maxheight))
	{
		my $xelev = 60 + (90 * ($elev - $minheight) / ($maxheight - $minheight));
		$xelev = round($xelev);
		# print "elev=$elev, xelev=$xelev\n";
		$xelev = 250 if $xelev > 250;
		$xelev = 0 if $xelev < 0;
		$elev = $xelev;
	}
	else {
		$elev = 60; # default
		print "no elev, using 60\n";
		print "at: lat=$lat, lon=$lon -> z $zone, east=$east, north=$north\n";
	}

	return $elev;
}

# Generate internal key AND filename where to find elevation data for $zone,$east,$north
sub get_dgm1_filename
{
	my ($self, $zone, $east, $north) = @_;
	if ($zone =~ /^([0-9]+)/) {
		$zone = $1;
	}
	$east = round($east);  # east=430270.977453409 ->  430271
	$east = int($east / 1000);# -> 430
	$east-- if ($east % 2); # not even? -> 430 in this case

	$north = round($north); # north=5635730.91656943 -> 5635731
	$north = int($north / 1000);  # -> 5635
	$north-- if ($north % 2); # -> 5634

	return "dgm1_" . $zone . $east . "_" . $north . "_2_nw.xyz";
}

sub get_dotkey
{
	my ($self, $zone, $east, $north) = @_;
	if ($zone =~ /^([0-9]+)/) {
		$zone = $1;
	}

	return $zone . round($east) . "_" . round($north);
}

# Load dgm1...xyz file into $self->elevation
sub load_dgm1_file
{
	my ($self, $filename) = @_;
	print "Loading $filename ... ";
	return unless -e $filename;
	open(my $fh, "<", $filename);
	if (! $fh) {
		print "File missing: $filename\n";
		exit(1);
	}
	while (my $line = <$fh>)
	{
		chomp($line);
		my @parts = split(/ +/, $line);
		my $dotkey = round( $parts[0] ) . "_" . round( $parts[1] );
		$self->{ elevations }->{ $dotkey } = $parts[2]; # float
	}
	close($fh);
	$self->{ loaded_files }->{ $filename } = 1;
	print "done\n";
	return 1;
}

1;
