package QohA::File::Specific::Sysprefs;

use Modern::Perl;
use Moo;
extends 'QohA::File';

sub run_checks {
    my ($self, $cnt) = @_;
    my @r = $self->check_sysprefs_order();
    $self->SUPER::add_to_report('sysprefs_order', \@r);

    return $self->SUPER::run_checks($cnt);
}

sub check_sysprefs_order {
    my ($self) = @_;
    return 0 unless -e $self->path;

    open ( my $fh, $self->path )
        or die "I cannot open $self->path ($!)";
    my @sysprefs;
    while ( my $line = <$fh> ) {
        next if $line =~ m|^INSERT INTO|;
        if ( $line =~ m|^\('([^']*)'| ) {
            my $prefname = $1;
            push @sysprefs, $prefname;
        }
    }
    my @sorted = sort {
        $b =~ s/_/ZZZ/g; # mysql sorts underscore last
        lc $a cmp lc $b
    } @sysprefs;
    my $bad_placed;
    for my $i ( 0 .. $#sorted ) {
        if ( $sorted[$i] ne $sysprefs[$i] ) {
            $bad_placed = $sorted[$i];
            last;
        }
    }
    close $fh;
    return 1 unless $bad_placed;
    return ( "Not blocker: Sysprefs $bad_placed is bad placed (see bug 10610)" );
}

1;

=head1 AUTHOR
Mason James <mtj at kohaaloha.com>
Jonathan Druart <jonathan.druart@biblibre.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by KohaAloha and BibLibre

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007
=cut
