package QohA::Git;

use Modern::Perl;
use Smart::Comments  -ENV;

use Moo;

has 'branchname' => (
    is => 'rw',
    default => sub{ get_current_branch() },
);

# this sub returns all modified files, for testing on
sub log {
    my ($self, $cnt) = @_;

    my @r = qx{git log --oneline --name-status -$cnt};
    my $files = {};

    foreach my $rr ( @r ) {
        chomp $rr;
        my @cols = split '\t', $rr ;

        # ignore lines that are commit shas, not filename
        next if not defined $cols[1];
        $files->{$cols[1]} .= $cols[0];
    }

    return [ map { { filepath => $_, statuses => $files->{$_} } } keys %$files ];
}

sub diff_log {
    my ($self, $cnt, $file) = @_; # $file is optionnal
    my $cmd = $cnt
        ? qq{git diff HEAD~$cnt..}
        : q{git diff HEAD};
    $cmd .= qq{ $file} if $file;
    my @r = qx/$cmd/;
    chomp for @r;
    return \@r;
}

sub log_as_string {
    my ($cnt) = @_;

    my @logs = qx{git log --oneline --numstat -$cnt};

    my $r;
    my ( $cc, $cdesc ) = get_prev_commit($cnt);

    chomp $cdesc;
    $cdesc = substr $cdesc, 0, 37;
    $r .= "testing $cnt commit(s) (applied to $cc '$cdesc')\n";

=c
    # there is no need for this display code,
    # the filenames are displayed elsewhere...

    my $i = 0;
    foreach my $l (@logs) {
        chomp $l;

        my @a = split '\t', $l;
        my ( $sha, $diff, $action, $filename, $desc );

        if ( $a[0] =~ /^\w{7} / and not defined $a[2] ) {
            $desc = $a[0];
            $desc = substr $desc, 0, 77;
            $r .= "\n $desc\n";
        }
        else {
            $diff     = $a[0];
            $filename = $a[2];
#            $r .= " - $filename\n" if $filename;
        }
        $i++;
    }
=cut

    return "$r\n";
}

sub create_and_change_branch {
    my ($self, $branchname) = @_;
    qx|git checkout -b $branchname 2> /dev/null|;
}

sub change_branch {
    my ($self, $branchname) = @_;
    qx|git checkout $branchname 2> /dev/null|;
}

sub delete_branch {
    my ($self, $branchname) = @_;
    qx|git branch -D $branchname 2> /dev/null|;
}

sub reset_hard_prev {
    my ($self, $cnt) = @_;
    qx|git reset --hard HEAD~$cnt 2> /dev/null|;
}

#FIXME There is no a simple way to get the current branch
sub get_current_branch {
    my $br = qx/git branch|grep '*'/;
    $br =~ s/\* //g;
    chomp $br;
    return $br;
}

sub get_prev_commit {
    my ($cnt) = @_;
    my $c =
      qx{git log --abbrev-commit --format=oneline -n 1 HEAD~$cnt};

    my $cc = substr $c , 0, 7;
    my $cdesc = substr $c , 8;

    return $cc, $cdesc;

}

1;

=head1 AUTHOR
Mason James <mtj at kohaaloha.com>
Jonathan Druart <jonathan.druart@biblibre.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by KohaAloha

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007
=cut
