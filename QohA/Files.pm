package QohA::Files;

use Moo;
use Modern::Perl;
use List::MoreUtils qw(uniq);

use QohA::File;
use QohA::File::XML;
use QohA::File::Perl;
use QohA::File::Template;
use QohA::File::YAML;
use QohA::File::Specific::Sysprefs;
use QohA::File::Specific::Kohastructure;
use QohA::File::Specific::OpacCss;

has 'files' => (
    is => 'rw',
);

sub BUILD {
    my ( $self, $param ) = @_;
    my @files = @{$param->{files}};
    $self->files([]);
    for my $f ( @files ) {
        my $filepath = $f->{filepath};
        my $file;
        if ( $filepath =~ qr/\.xml$|\.xsl$|\.xslt$/i ) {
            $file = QohA::File::XML->new(path => $filepath);
        } elsif ( $filepath =~ qr/\.pl$|\.pm$|\.t$|svc|unapi$/i ) {
            $file = QohA::File::Perl->new(path => $filepath);
        } elsif ( $filepath =~ qr/\.tt$|\.inc$/i ) {
            $file = QohA::File::Template->new(path => $filepath);
        } elsif ( $filepath =~ qr/\.yml$|\.yaml$/i ) {
            $file = QohA::File::YAML->new(path => $filepath);
        } elsif ( $filepath =~ qr/sysprefs\.sql$/ ) {
            $file = QohA::File::Specific::Sysprefs->new(path => $filepath);
        } elsif ( $filepath =~ qr/kohastructure\.sql$/ ) {
            $file = QohA::File::Specific::Kohastructure->new(path => $filepath);
        } elsif ( $filepath =~ qr/opac\.css$|opac\.less$/ ) {
            $file = QohA::File::Specific::OpacCss->new(path => $filepath);
        } elsif ( $f->{statuses} =~ m|A| and $f->{statuses} =~ m|D| ) {
            $file = QohA::File->new(path => $filepath);
        }
        next unless $file;
        $file->git_statuses( $f->{statuses} );
        push @{ $self->files}, $file;
    }
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
