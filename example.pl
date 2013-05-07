#!/usr/bin/perl
use strict;
use Data::Dumper;
BEGIN {
	push(@INC, "lib/");
}

use BTCE;


# if key and secret are undef, we will try to read
# ~/.btce.secret
my $btce = BTCE->new(key=>undef, secret=>undef);
$btce->enable_debug(1);


print Data::Dumper::Dumper($btce);


print Data::Dumper::Dumper $btce->trade_history(count=>30, order=>'ASC')
