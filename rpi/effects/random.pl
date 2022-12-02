#!/usr/bin/perl -X

use strict;
use OPC;

my $num_leds = 480;
my $client = new OPC('127.0.0.1:7890');
$client->can_connect();

while(1){
	my $pixels = [];
	
	# Initialize an empty pixel array
	push @$pixels, [int(rand(256)),int(rand(256)),int(rand(256))] while scalar(@$pixels) < $num_leds;

	# Send this row of pixels to the server
	$client->put_pixels(0,$pixels);

	sleep 1;
}

print "Done\n";