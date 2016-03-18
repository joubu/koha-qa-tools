package QohA::File::Specific::OpacCss;

use Modern::Perl;
use Moo;
use IPC::Cmd qw[run];
use File::Basename;
use File::Temp qw[tempfile];
extends 'QohA::File';

sub run_checks {
    my ($self, $cnt) = @_;
    my @r = $self->check_css_less_sync();
    $self->SUPER::add_to_report('css_and_less_in_sync', \@r);

    return $self->SUPER::run_checks($cnt);
}

sub check_css_less_sync {
    my ($self) = @_;
    return 0 unless -e $self->path;

    # Don't check on first pass
    return 1 if $self->pass == 1;
    open ( my $fh, $self->path )
        or die "I cannot open $self->path ($!)";

    my ( $tmp_fh, $tmp_filename ) = File::Temp::tempfile( UNLINK => 1, TMPDIR => 1, SUFFIX => 'css');
    my $dir = dirname( $self->abspath );
    my $cmd =
          q{lessc --compress }
        . $dir . q{/../../bootstrap/less/opac.less > }
        . $tmp_filename . q{;}
        . q{diff } . $dir . q{/../../bootstrap/css/opac.css }
        . $tmp_filename
        . q{ | wc -l}
    ;
    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
        run( command => $cmd, verbose => 0 );

    my $number_of_lines = $full_buf->[0];
    chomp $number_of_lines;
    if ( $success and $number_of_lines eq '0') {
        return 1;
    }

    return ( "opac.css and opac.less are not in sync, use lessc --compress");
}

1;

=head1 AUTHOR
Jonathan Druart <jonathan.druart@bugs.koha-community.org>

=head1 COPYRIGHT AND LICENSE

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007
=cut
