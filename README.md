[![Build Status](https://travis-ci.org/skaji/Scoreboard.svg?branch=master)](https://travis-ci.org/skaji/Scoreboard)
[![AppVeyor Status](https://ci.appveyor.com/api/projects/status/github/skaji/Scoreboard?branch=master&svg=true)](https://ci.appveyor.com/project/skaji/Scoreboard)

# NAME

Scoreboard - simple scorebaord

# SYNOPSIS

    use Scoreboard;

    my $sb = Scoreboard->new(file => "./test.sb");

    my %pid;
    for (1..10) {
      my $pid = fork;
      if ($pid) {
        $pid{$pid}++;
        next;
      }

      # child
      $sb->inc("some_count");
      $sb->plus(another_count => 3);

      my $mark = $sb->mark;
      heavy_work();
      $sb->set(heavy_work_latency => $mark);
      exit;
    }

    # wait all children
    while (%pid) {
       my $pid = wait;
       delete $pid{$pid};
    }

    use Data::Dumper;
    print Dumper $sb->raw;

# DESCRIPTION

Scoreboard is a simple scorebard.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>

# COPYRIGHT AND LICENSE

Copyright 2017 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
