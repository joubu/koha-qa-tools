package QohA::File::Template;

use Modern::Perl;
use Moo;

extends 'QohA::File';

use IPC::Cmd qw[can_run run];
use File::Spec;

use QohA::Report;
use C4::TTParser;
use Template;

has 'pass' => (
    is => 'rw',
    default => sub{1},
);

has 'report' => (
    is => 'rw',
    default => sub {
        QohA::Report->new( {type => 'template'} );
    },
);

sub run_checks {
    my ($self, $cnt) = @_;
    my $r;
    $r = $self->check_tt_valid();
    $self->SUPER::add_to_report('tt_valid', $r);

    $r = $self->check_valid_template();
    $self->SUPER::add_to_report('valid_template', $r);

    if ( $self->pass == 1 ) {
        $self->SUPER::add_to_report('forbidden patterns', '');
    } else {
        $r = $self->check_forbidden_patterns($cnt);
        $self->SUPER::add_to_report('forbidden patterns', $r);
    }

    $r = $self->check_spelling();
    $self->SUPER::add_to_report('spelling', $r);

    $self->pass($self->pass + 1);
}

sub check_tt_valid {
    my ($self) = @_;
    return q{} unless -e $self->path;
    my $parser = C4::TTParser->new;
    my $filename = $self->abspath;
    $parser->build_tokens( $filename );
    my @lines;
    my @files;
    while ( my $token = $parser->next_token ) {
        my $attr = $token->{_attr};
        next unless $attr;
        push @lines, $token->{_lc} if $attr->{'[%'};
    }
    return @lines
        ? "lines " . join ', ', @lines
        : q{};
}

sub check_valid_template {
    my ($self) = @_;
    return q{} unless -e $self->path;
    my @errors;

    my $template_dir;
    my $include_dir;

    my $tmpl_type =
      $self->path =~ /opac-tmpl/
      ? 'opac'
      : 'intranet';
    my $theme = $tmpl_type eq 'intranet' ? 'prog' : 'bootstrap';
    $template_dir =
      File::Spec->rel2abs("koha-tmpl/${tmpl_type}-tmpl/prog/en/modules");
    $include_dir =
      File::Spec->rel2abs("koha-tmpl/${tmpl_type}-tmpl/$theme/en/includes");

    my $tt = Template->new(
        {
            ABSOLUTE     => 1,
            INCLUDE_PATH => $include_dir,
            PLUGIN_BASE  => 'Koha::Template::Plugin',
        }
    );

    my $vars;
    my $output;
    my $absf = File::Spec->rel2abs($self->path);

    my $ok = $tt->process( $absf, $vars, \$output );
    unless ($ok) {
        my $z = $tt->error();

        push @errors, $z->info();
    }

    return "@errors";
}

sub check_forbidden_patterns {
    my ($self, $cnt) = @_;

    my @forbidden_patterns = (
        {pattern => qr{console.log} , error => "console.log"},
        {pattern => qr{_\('.*'\)}   , error => "simple-quote string"},
        {pattern => qr{<<<<<<<}     , error => "merge marker (<<<<<<<)"}, # git merge non terminated
        {pattern => qr{>>>>>>>}     , error => "merge marker (>>>>>>>)"},
        {pattern => qr{=======}     , error => "merge marker (=======)"},
        {pattern => qr{\t}          , error => "tab char"},
        {pattern => qr{ $}          , error => "trailing space char"},
        {pattern => qr{intranet-tmpl},error => "intranet-tmpl should certainly replaced with [% interface %]"},
        {pattern => qr{opac-tmpl}   , error => "opac-tmpl should certainly replaced with [% interface %]"},
        {pattern => qr{jquery.dataTables.min.js}, error => "To include datatables files, please use the include file (see bug 10868)"},
        {pattern => qr{\[% USE ?KohaAuthorisedValues ?%\]}, error => "KohaAuthorisedValues plugin is deprecated (see bug 10626)"},
        {pattern => qr{\[% USE ?KohaBranchName ?%\]}, error => "KohaBranchName plugin is deprecated (see bug 10626)"},
    );

    my $errors = $self->SUPER::check_forbidden_patterns($cnt, \@forbidden_patterns);
    return q{} if $errors == 1;
    return $errors;
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
