package Scoreboard;
use strict;
use warnings;

use Fcntl qw(:flock :DEFAULT);
use IO::Handle;
use Storable ();
use Time::HiRes ();

our $VERSION = '0.001';

# perl -MList::Util=uniq -E 'say for uniq map { int $_ } map { 1.103 ** $_ } 1..114'
my @HISTOGRAM = qw(
    0
    1
    2
    3
    4
    5
    6
    7
    8
    9
    10
    11
    12
    14
    15
    17
    18
    20
    23
    25
    28
    30
    34
    37
    41
    45
    50
    55
    61
    67
    74
    82
    90
    100
    110
    121
    134
    148
    163
    180
    199
    219
    242
    267
    294
    325
    358
    395
    436
    481
    530
    585
    645
    712
    785
    866
    955
    1054
    1162
    1282
    1414
    1560
    1720
    1898
    2093
    2309
    2547
    2809
    3098
    3417
    3770
    4158
    4586
    5059
    5580
    6154
    6788
    7488
    8259
    9110
    10048
    11083
    12225
    13484
    14873
    16404
    18094
    19958
    22014
    24281
    26782
    29541
    32583
    35940
    39641
    43725
    48228
    53196
    58675
    64719
);


sub _tick {
    my $now = time;
    my $wip = $now - ($now % 300);
    ($wip - 300, $wip);
}

sub _histogram_index {
    my $latency = shift;
    for my $i (0..99) {
        if ($latency < $HISTOGRAM[$i]) {
            return $i;
        }
    }
    99;
}

sub new {
    my ($class, %args) = @_;
    my $self = bless \%args, $class;
    $self->_open;
    $self;
}

sub _open {
    my $self = shift;
    if (!$self->{fh} or $self->{owner} != $$) {
        if (my $fh = $self->{fh}) {
            close $fh;
            undef $fh;
        }
        my $mode = $self->{readonly} ? Fcntl::O_RDONLY() : Fcntl::O_RDWR()|Fcntl::O_CREAT();
        sysopen my $fh, $self->{file}, $mode or die "$self->{file}: $!";
        $self->{fh} = $fh;
        $self->{owner} = $$;
    }
    $self->{fh};
}

sub _update {
    my ($self, $sub) = @_;
    my $fh = $self->_open;
    flock $fh, Fcntl::LOCK_EX() or die "flock $self->{file}: $!";
    sysseek $fh, 0, 0;
    sysread $fh, my $content, (-s $fh);
    my ($done, $wip) = _tick;
    my $hash = length $content ? Storable::thaw($content) : +{};
    my @delete = grep { $_ != $done && $_ != $wip } keys %$hash;
    delete $hash->{$_} for @delete;
    $hash->{$wip} ||= +{ count => {}, latency => {} };
    $sub->($hash->{$wip});
    truncate $fh, 0;
    sysseek $fh, 0, 0;
    syswrite $fh, Storable::freeze($hash);
    flock $fh, Fcntl::LOCK_UN();
    1;
}

sub raw {
    my $self = shift;
    my $fh = $self->_open;
    flock $fh, Fcntl::LOCK_SH() or die "flock $self->{file}: $!";
    sysseek $fh, 0, 0;
    sysread $fh, my $content, (-s $fh);
    flock $fh, Fcntl::LOCK_UN();
    length $content ? Storable::thaw($content) : undef;
}

sub inc {
    my ($self, $name) = @_;
    defined $name or do { warn "Scoreboard->inc requires defined name"; return };
    $self->_update(sub {
        my $data = shift;
        $data->{count}{$name}++;
    });
}

sub plus {
    my ($self, $name, $count) = @_;
    defined $name or do { warn "Scoreboard->inc requires defined name"; return };
    $self->_update(sub {
        my $data = shift;
        $data->{count}{$name} += $count;
    });
}

sub mark {
    Time::HiRes::time();
}

sub set {
    my ($self, $name, $mark) = @_;
    defined $name or do { warn "Scoreboard->inc requires defined name"; return };
    my $latency = int( ( Time::HiRes::time() - $mark ) * 1000 );
    return if $latency < 0;

    $self->_update(sub {
        my $data = shift;
        $data->{latency}{histgram}{$name} ||= [ (0) x 100 ];
        $data->{latency}{histgram}{$name}[ _histogram_index $latency ]++;
        $data->{latency}{count}{$name}++;
        $data->{latency}{sum}{$name} += $latency;
    });
}

1;
__END__

=encoding utf-8

=head1 NAME

Scoreboard - simple scorebaord

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Scoreboard is a simple scorebard.

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
