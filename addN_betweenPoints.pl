#!/usr/bin/perl -w

# addN_betweenPoints.pl
#    utility for adding N points between the existing points in 
#	a FitnessTrek path database table
#

use English;
use DBI;

unless ($#ARGV == 3 ){
	printf STDERR "usage: args: N dbfile srcTbl destTbl\n";
	exit 1;
}
$new_points = ($ARGV[0]);
$dbfile = ($ARGV[1]);
$srcTbl = ($ARGV[2]);
$destTbl = ($ARGV[3]);

# debug stuff
printf STDERR "N=$new_points  dbfile=$dbfile  srcTbl=$srcTbl destTbl=$destTbl\n";

#@driver_names = DBI->available_drivers();
#print "drivers available:\n";
#foreach my $dn (@driver_names){
#	print "$dn\n";
#}

# open db handle
$dbh = DBI->connect("dbi:SQLite:$dbfile","","");

$sth = $dbh->prepare("SELECT * FROM $srcTbl ORDER BY pointNumber");
$sth->execute;
@src_row=$sth->fetchrow_array();

$dest_index=1;
$last_latitude = $src_row[1];
$last_longitude = $src_row[2];
$dist_incr = 0.0;

# create the new table (statement never true, so it use table def w/o content
$q="CREATE TABLE $destTbl AS SELECT * FROM $srcTbl WHERE pointNumber < 0";
print "q=$q\n";
$dbh->do($q);

# add first row
$q="INSERT INTO $destTbl VALUES(".$dest_index++.",$last_latitude,$last_longitude,$dist_incr,\'$src_row[4]\',\'$src_row[5]\')";
print "q=$q\n";
$dbh->do($q);

# rest of rows
PNT: while (@src_row=$sth->fetchrow_array()){
	# check for discontinuities
	if ( abs($src_row[2]-$last_longitude) > 200 ){
		print "skipping edge of the world...\n";
		# write out the edge point:
		$q="INSERT INTO $destTbl VALUES(".$dest_index++.",$src_row[1],$src_row[2],$src_row[3],\'$src_row[4]\',\'$src_row[5]\')";
		print "edge point: q=$q\n";
		$dbh->do($q);

		$last_latitude = $src_row[1];
		$last_longitude = $src_row[2];
		next PNT;
	}
	$latitude_incr = ($src_row[1]-$last_latitude)/($new_points+1);
	print "latitude increment= $latitude_incr\n";
	$longitude_incr = ($src_row[2]-$last_longitude)/($new_points+1);
	#$r_noise = rand(0.001)-0.0005;
	print "longitude increment= $longitude_incr\n";
	#$longitude_incr += $r_noise;
	#print "longitude increment(with noise)= $longitude_incr\n";
	$dist_incr = $src_row[3]/($new_points+1);
	print "dist increment = $dist_incr\n";

	for ($i=1; $i<=$new_points; $i++){
		$q="INSERT INTO $destTbl VALUES(".$dest_index++.",".($last_latitude+($latitude_incr*$i)+rand(0.001)-0.0005).",".($last_longitude+($longitude_incr*$i)+rand(0.001)-0.0005).",$dist_incr,\'\',\'\')";
		print "q=$q\n";
		$dbh->do($q);
	}
	$q="INSERT INTO $destTbl VALUES(".$dest_index++.",$src_row[1],$src_row[2],$dist_incr,\'$src_row[4]\',\'$src_row[5]\')";
	print "q=$q\n";
	$dbh->do($q);

	$last_latitude = $src_row[1];
	$last_longitude = $src_row[2]
}
$sth->finish();
$dbh->disconnect();















