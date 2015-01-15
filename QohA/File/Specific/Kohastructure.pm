package QohA::File::Specific::Kohastructure;

use Modern::Perl;
use Moo;
use QohA::Report;
extends 'QohA::File';

has 'report' => (
    is => 'rw',
    default => sub {
        QohA::Report->new( {type => 'specific'} );
    },
);

sub run_checks {
    my ($self) = @_;
    my @r = $self->check_charset_collate();
    $self->SUPER::add_to_report('charset_collate', \@r);
}

sub check_charset_collate {
    my ($self) = @_;
    return 0 unless -e $self->path;

    open( my $fh, $self->path )
      or die "I cannot open $self->path ($!)";

    my @bad_charset_collate;
    my $current_table;
    while ( my $line = <$fh> ) {
        if ( $line =~
            m|CREATE\s+TABLE\s+(IF NOT EXISTS)?\s*`?([^` \(]*)`?\s*\(\s*$| )
        {
            $current_table = $2;
        }
        next unless $line =~ m|CHARSET=utf8|;
        next if $line =~ m|utf8_unicode_ci|;
        push @bad_charset_collate, $current_table;
    }
    close $fh;
    return 1 unless @bad_charset_collate;
    my @errors;
    push @errors,
      "The table $_ does not have the current charset collate (see bug 11944)"
      for @bad_charset_collate;
    return @errors;
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
