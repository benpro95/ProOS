#!/usr/bin/perl -X

use strict;
use OPC;

my $num_leds = 512;
my $client = new OPC('127.0.0.1:7890');
$client->can_connect();

my $pixels = [];
	
# Initialize an empty pixel array
push @$pixels, [0,0,0] while scalar(@$pixels) < $num_leds;

# Send this row of pixels to the server
$client->put_pixels(0,$pixels);
$client->put_pixels(0,$pixels);
