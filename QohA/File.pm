package QohA::File;

use Modern::Perl;
use Moo;
use File::Basename;
use Cwd 'abs_path';
use IPC::Cmd qw( run );
use QohA::Report;

has 'path' => (
    is => 'ro',
    required => 1,
);
has 'filename' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_filename',
);
has 'abspath' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_abspath',
);
has 'new_file' => (
    is => 'rw',
    default => sub {0},
);
has 'pass' => (
    is => 'rw',
    default => sub{0},
);
has 'report' => (
    is => 'rw',
    default => sub {
        QohA::Report->new();
    },
);
has 'git_statuses' => (
    is => 'rw',
);

sub _build_filename {
    my ($self) = @_;
    return basename( $self->path );
}

sub _build_abspath {
    my ($self) = @_;
    my $abs_path = abs_path( $self->path );
    return $abs_path;
}

sub run_checks {
    my ($self, $cnt) = @_;

    my $r;

    # Check git manipulations
    $r = $self->check_git_manipulation();
    $self->add_to_report('git manipulation', $r);

    $self->pass($self->pass + 1);
}

sub check_forbidden_patterns {
    my ($self, $cnt, $patterns) = @_;

    return 0 unless -e $self->path;

    # For the first pass, I don't want to launch any test.
    return 1 if $self->pass == 0;

    my $git = QohA::Git->new();
    my $diff_log = $git->diff_log($cnt, $self->path);
    my @forbidden_patterns = @$patterns;
    my @errors;
    my $line_number = 1;
    for my $line ( @$diff_log ) {
        if ( $line =~ m|^@@ -\d+,{0,1}\d* \+(\d+),\d+ @@| ) {
            $line_number = $1;
            next;
        }
        next if $line =~ m|^-|;
        $line_number++ and next unless $line =~ m|^\+|;
        for my $fp ( @forbidden_patterns ) {
            next
                if $line =~ /^\+\+\+ /;
            push @errors, "forbidden pattern: " . $fp->{error} . " (line $line_number)"
                if $line =~ /^\+.*$fp->{pattern}/;
        }
        $line_number++;
    }

    return @errors
        ? \@errors
        : 1;
}

sub check_spelling {
    my ($self) = @_;

    my $cmd = q{codespell -d } . $self->path;
    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) = run( command => $cmd, verbose => 0 );

    return 0 unless @$full_buf;

    my @exceptions = (
        qr{isnt\(},
    );
    # Encapsulate the potential errors
    my @errors;
    my @lines = split /\n/, $full_buf->[0];
    for my $line (@lines) {
        chomp $line;

        # Remove filepath and line numbers
        # my/file/path:xxx: indentifier  ==> identifier
        my $re = q|^| . $self->path . q|:(\d+):|;
        if ( $line =~ $re ) {
            my $line_number = $1;
            my $p = $self->path;
            my $guilty_line = `sed -n '${line_number}p' $p`;
            my $is_an_exception;
            for my $e ( @exceptions ) {
                if ( $guilty_line =~ $e ) {
                    $is_an_exception = 1;
                    last;
                }
            }
            unless ( $is_an_exception ) {
                $line =~ s|$re||;
                push @errors, $line;
            }
        }
    }

    return @errors
      ? \@errors
      : 1;
}

sub check_git_manipulation {
    my ($self) = @_;

    return 1 if $self->pass == 0;

    my @errors;

    if ( $self->{git_statuses} =~ m|A| and $self->{git_statuses} =~ m|D| ) {
        push @errors, "The file has been added and deleted in the same patchset";
    }

    return @errors
      ? \@errors
      : 1;
}

sub add_to_report {
    my ($self, $name, $error) = @_;
    $self->report->add(
        {
            file => $self,
            name => $name,
            error => ( defined $error ? $error : '' ),
        }
    );
}

1;

__END__

=pod

=head1 NAME

QohA::File - common interface for a file in QohA

=head1 DESCRIPTION

This module is a wrapper that provide some common informations for a file.

=head1 AUTHORS
Mason James <mtj at kohaaloha.com>
Jonathan Druart <jonathan.druart@biblibre.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by KohaAloha and BibLibre

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007
=cut
