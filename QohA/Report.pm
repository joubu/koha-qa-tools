package QohA::Report;

use Modern::Perl;
use Moo;
use List::Compare;

has 'file' => (
    is => 'rw',
);
has 'tasks' => (
    is => 'rw',
    default => sub {return {}},
);

# Global vars
our $RED    = "\e[1;31m";
our $GREEN  = "\e[1;32m";
our $ORANGE = "\e[1;33m";
our $END    = "\e[0m";

sub add {
    my ($self, $param) = @_;
    my $file = $param->{file};
    $self->file($file);
    my $name = $param->{name};
    my $error = $param->{error};

    push @{ $self->tasks->{$name} },
        defined $error ? $error : 1;
}

sub to_string {
    my ($self, $params) = @_;
    my $verbosity = $params->{verbosity} // 0;
    my $color     = $params->{color} // 1;
    my $task_name = $params->{name};
    my $skip      = $params->{skip} // [];

    my $STATUS_KO = $color
        ? "${RED}FAIL${END}"
        : "FAIL";
    my $STATUS_OK = $color
        ? "${GREEN}OK${END}"
        : "OK";
    my $STATUS_SKIPPED = $color
        ? "${ORANGE}SKIP${END}"
        : "SKIP";

    my $tasks = $self->tasks;
    if ( defined $task_name ) {
        $tasks = { $task_name => $tasks->{$task_name} }
    }

    my ( $v1, $v2 );
    my $errors_cpt = 0;
    my ($status, $v1_status);


    for my $name ( sort keys %$tasks ) {
        if ( grep {/^$name$/} @$skip ) {
            $v1 .= "\n   " . $STATUS_SKIPPED ."\t  $name";
            next;
        }
        my $results = $tasks->{$name};
        my @diff = $self->diff($results);

        my $task_status = $STATUS_OK;
        my @diff_ko;
        if ( @diff ) {
            for my $d ( @diff ) {
                next unless $d;  # if $d eq "" FIXME
                next if $d =~ /^\d$/ and $d == 1; # We have to bring consistency for the returns of the check* routine
                push @diff_ko, $d;
            }
            if ( @diff_ko ) {
                $errors_cpt++;
                $task_status = $STATUS_KO;
            }
        }
        $v1 .= "\n   " . $task_status ."\t  $name";
        if ( $verbosity >= 2 ) {
            $v1 .= "\n\t\t$_" for @diff;
        }
    }
    $v1 .= "\n"; # add a pretty \n between files

    $status = $errors_cpt
        ? $STATUS_KO
        : $STATUS_OK;
    my $s = " $status\t" .  $self->file->path;
    $s .= $v1 if $verbosity >= 1;

    return $s;
}

sub diff {
    my ($self, $errors) = @_;
    my ($before, $current) = @$errors;

    unless ( ref $current or ref $before ) {
        if ( "$current" eq "$before" ) {
            return;
        }
        return ($current);
    }

    $current = [$current] unless ref $current;
    $before  = [$before]  unless ref $before;

    # count the number of occurrence of each error
    my ( %nb_occ_current, %nb_occ_before );
    $nb_occ_current{$_} += 1 for @$current;
    $nb_occ_before{$_} += 1 for @$before;

    # If the error did not exist before
    # or if this error occurs more than before
    # it is a regression
    my @errors;
    while ( my ( $err, $nb ) = each %nb_occ_current ) {
        push @errors, $err
            if not defined $nb_occ_before{$err}
                or $nb_occ_current{$err} > $nb_occ_before{$err};
    }
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
