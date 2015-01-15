package QohA::Files;

use Moo;
use Modern::Perl;
use List::MoreUtils qw(uniq);

use QohA::File::XML;
use QohA::File::Perl;
use QohA::File::Template;
use QohA::File::YAML;
use QohA::File::Specific::Sysprefs;
use QohA::File::Specific::Kohastructure;

has 'files' => (
    is => 'rw',
);

sub BUILD {
    my ( $self, $param ) = @_;
    my @files = @{$param->{files}};
    @files = uniq @files;
    $self->files([]);
    for my $file ( @files ) {
        push @{ $self->files }, QohA::File::XML->new(path => $file)
            if $file =~ qr/\.xml$|\.xsl$|\.xslt$/i;
        push @{ $self->files }, QohA::File::Perl->new(path => $file)
            if $file =~ qr/\.pl$|\.pm$|\.t$/i;
        push @{ $self->files }, QohA::File::Template->new(path => $file)
            if $file =~ qr/\.tt$|\.inc$/i;
        push @{ $self->files }, QohA::File::YAML->new(path => $file)
            if $file =~ qr/\.yml$|\.yaml$/i;
        push @{ $self->files }, QohA::File::Specific::Sysprefs->new(path => $file)
            if $file =~ qr/sysprefs\.sql$/;
        push @{ $self->files }, QohA::File::Specific::Kohastructure->new(path => $file)
            if $file =~ qr/kohastructure\.sql$/;
    }
}

sub filter {
    my ($self, $params) = @_;
    my $file_types = $params->{extension} // [];
    my $file_names = $params->{name} // [];

    die "QohA::Files::filter > Bad call: extension and name params cannot be filled together"
        if scalar( @$file_types ) and scalar( @$file_names );
    my @wanted_files;

    for my $type ( @$file_types ) {
        for my $f ( @{$self->files} ) {
            if ( $type =~ /perl/ ) {
                push @wanted_files, $f
                  if ref $f eq 'QohA::File::Perl';
            }
            elsif ( $type =~ /xml/ ) {
                push @wanted_files, $f
                  if ref $f eq 'QohA::File::XML';
            }
            elsif ( $type =~ /tt/ ) {
                push @wanted_files, $f
                  if ref $f eq 'QohA::File::Template';
            }
            elsif ( $type =~ /yaml/ ) {
                push @wanted_files, $f
                  if ref $f eq 'QohA::File::YAML';
            }
        }
    }

    if ( @$file_names ) {
        for my $f ( @{$self->files} ) {
            push @wanted_files, $f
                if grep { $_ eq $f->filename } @$file_names;
        }
    }

    return @wanted_files;
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
