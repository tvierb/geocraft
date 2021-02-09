
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

sub new
{
	my( $class, $height_dir, $tmp_dir, $correction ) = @_;

	my $self = bless { 
		height_dir => $height_dir,
		tmp_dir => $tmp_dir,
		correction => $correction,
		dots => {},
	}, $class;

}

sub ll
{
	my( $self, $model, $lat, $lon ) = @_;

	my ($zone, $east, $north) = latlon_to_utm( 23, $lat, $lon );
	$east = round($east);   # aka Rechtswert
	$north = round($north); # aka Hochwert
	print "lat=$lat, lon=$lon -> z $zone, east=$east, north=$north\n";
	print "Key: " . $self->get_dgm1_key( $zone, $east, $north ) . "\n";
	return 60;
}

# Generate internal key AND filename where to find elevation data for $zone,$east,$north
sub get_dgm1_key
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

1;
