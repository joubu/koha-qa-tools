package QohA::File::XML;

use Modern::Perl;
use Moo;
use XML::LibXML;

extends 'QohA::File';

sub run_checks {
    my ($self, $cnt) = @_;
    my @r = $self->check_parse_xml();
    $self->SUPER::add_to_report('xml_valid', \@r);

    return $self->SUPER::run_checks($cnt);
}

sub check_parse_xml {
    my ($self) = @_;
    my $parser = XML::LibXML->new();
    my $abspath = $self->abspath;
    eval { $parser->parse_file($abspath); };
    return 0 unless $@;
    my @r;
    for my $line ( split '\n', $@ ) {
        next unless $line;
        next unless $line =~ /parser error/;
        $line =~ s|[^:]*:||;
        push @r, $line;
    }
    return @r;
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
