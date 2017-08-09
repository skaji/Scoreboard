#!/usr/bin/env perl
use strict;
use warnings;
use lib "lib", "../lib";
use Scoreboard;

my $sb = Scoreboard->new(file => "test.sb");

$sb->inc("hoge") for 1..100;
$sb->plus("baz", 3) for 1..20;

for (1..30) {
    my $mark = $sb->mark;
    Time::HiRes::sleep(0.001 * $_);
    $sb->set(some_work => $mark);
}

use DDP;
p $sb->raw;
