#!perl

use Test::More tests => 7;

use strict; use warnings;
use TV::ProgrammesSchedules::STAR;

my ($star, $listings);

eval { $star = TV::ProgrammesSchedules::STAR->new(yyyy => 2011, mm => 4, dd => 12); };
like($@, qr/ERROR: Input param has to be a ref to HASH./);

eval { $star = TV::ProgrammesSchedules::STAR->new({yyyy => 2011, mm => 4}); };
like($@, qr/ERROR: Invalid number of keys found in the input hash./);

eval { $star = TV::ProgrammesSchedules::STAR->new({yyyy => -2011, mm => 4, dd => 12}); };
like($@, qr/ERROR: Invalid year \[\-2011\]./);

eval { $star = TV::ProgrammesSchedules::STAR->new({yyyy => 2011, mm => 13, dd => 12}); };
like($@, qr/ERROR: Invalid month \[13\]./);

eval { $star = TV::ProgrammesSchedules::STAR->new({yyyy => 2011, mm => 4, dd => 32}); };
like($@, qr/ERROR: Invalid day \[32\]./);

eval { $star = TV::ProgrammesSchedules::STAR->new(); $listings = $star->get_listings('star'); };
like($@, qr/ERROR: Invalid channel \[star\]./);

eval { $star = TV::ProgrammesSchedules::STAR->new(); $listings = $star->get_listings(); };
like($@, qr/ERROR: Channel undefined./);