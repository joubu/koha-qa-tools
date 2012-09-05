use Modern::Perl;
use Test::More;

use File::chdir;
use Cwd qw/getcwd/;
use Git::Repository;
use QohA::Git;
use QohA::Files;


my $num_of_commits = 2;
my $v = 1;
my $git_repo = 't/git_repo_tmp';
my $cwd_bak = $CWD;
die "You have to be at the root of the koha-qa-tools project" unless $cwd_bak =~ /koha-qa-tools$/;
my $dir_patch_path = 't/data';

eval {
    system( qq{ rm -Rf $git_repo } );
    Git::Repository->run( init => $git_repo );
    my $git = Git::Repository->new( work_tree => $git_repo );
    is( ref $git, 'Git::Repository', "Is a Git::Repository object");
    opendir( my $dir_patch, $dir_patch_path );
    my $i = 1;
    my @dirs = `ls -1 $dir_patch_path`;
    for my $dir ( @dirs ) {
        chomp $dir;
        next if $dir =~ '^\.';
        system( qq{cp -ra $dir_patch_path/$dir/* $git_repo} );
        my $add = $git->run( add => '.' );
        is( $add, '', "return of the add command for add n°$i" );
        my $commit = $git->run( commit => '-m', "commit n°$i" );
        is( $commit =~ m| commit n°$i|, 1, "return of the commit command for add n°$i" );
        $i++;
    }

    $CWD = $git_repo;
    my $qoha_git = QohA::Git->new();
    my $modified_files = QohA::Files->new( { files => $qoha_git->log($num_of_commits) } );


    $qoha_git->delete_branch( 'qa-prev-commit_t' );
    $qoha_git->create_and_change_branch( 'qa-prev-commit_t' );
    $qoha_git->reset_hard_prev( $num_of_commits );

    my @files = $modified_files->filter( qw< perl tt xml yaml > );
    for my $f ( @files ) {
        $f->run_checks();
    }

    $qoha_git->change_branch('master');
    $qoha_git->delete_branch( 'qa-current-commit_t' );
    $qoha_git->create_and_change_branch( 'qa-current-commit_t' );
    for my $f ( @files ) {
        $f->run_checks($num_of_commits);
    }

    my ($perl_fail_compil) = grep {$_->path eq qq{perl/i_fail_compil.pl}} @files;
    is( ref $perl_fail_compil, qq{QohA::File::Perl}, "i_fail_compil.pl found" );
    my ($fail_compil_before, $fail_compil_after) = @{ $perl_fail_compil->report->tasks->{valid} };
    is( $fail_compil_before, 1, "fail_compil passed compil before" );
    is( scalar @$fail_compil_after, 1, "fail_compil has 1 error for compil now");
    is( @$fail_compil_after[0] =~ m{Can't locate Foo/Bar.pm}, 1, qq{the compil error for fail_compil is "can't locate Foo/Bar.pm} );

    my ($perl_fail_critic) = grep {$_->path eq qq{perl/i_fail_critic.pl}} @files;
    is( ref $perl_fail_critic, qq{QohA::File::Perl}, "i_fail_critic.pl found" );
    my ($fail_critic_before, $fail_critic_after) = @{ $perl_fail_critic->report->tasks->{valid} };
    is( $fail_critic_before, 1, "fail_critic passed valid before");
    is( $fail_critic_after, 1, "fail_critic passes valid now");
    ($fail_critic_before, $fail_critic_after) = @{ $perl_fail_critic->report->tasks->{critic} };
    is($fail_critic_before, 0, "fail_critic passes critic before (file did not exist)");
    is( @$fail_critic_after[0] =~ m{^Bareword file handle.*PBP.$}, 1, qq{the perl critic error for fail_compil is "'Bareword file handle opened[...]See pages 202,204 of PBP.'"} );

    my ($perl_ok) = grep {$_->path eq qq{perl/i_m_ok.pl}} @files;
    is( ref $perl_ok, qq{QohA::File::Perl}, "i_m_ok.pl found" );


    # Check output result for verbosity = 0 or 1
    # Verbosity = 2 return too many specifics errors to test
    my $RED = "\e[1;31m";
    my $GREEN = "\e[1;32m";
    my $END = "\e[0m";
    our $STATUS_KO = "${RED}FAIL${END}";
    our $STATUS_OK = "${GREEN}OK${END}";
    my $r_v0_expected = <<EOL;
* perl/i_fail_compil.pl                                                    $STATUS_KO
* perl/i_fail_critic.pl                                                    $STATUS_KO
* perl/i_m_ok.pl                                                           $STATUS_OK
* i_fail_yaml.yaml                                                         $STATUS_KO
EOL
    my $r_v1_expected = <<EOL;
* perl/i_fail_compil.pl                                                    $STATUS_KO
	forbidden patterns          $STATUS_OK
	valid                       $STATUS_KO
	critic                      $STATUS_OK
* perl/i_fail_critic.pl                                                    $STATUS_KO
	forbidden patterns          $STATUS_OK
	valid                       $STATUS_OK
	critic                      $STATUS_KO
* perl/i_m_ok.pl                                                           $STATUS_OK
	forbidden patterns          $STATUS_OK
	valid                       $STATUS_OK
	critic                      $STATUS_OK
* i_fail_yaml.yaml                                                         $STATUS_KO
	yaml_valid                  $STATUS_KO
EOL

    my ( $r_v0, $r_v1 );
    for my $f ( @files ) {
        $r_v0 .= $f->report->to_string({verbosity => 0})."\n";
        $r_v1 .= $f->report->to_string({verbosity => 1})."\n";
    }
    is( $r_v0, $r_v0_expected, "Check verbosity output (0)");
    is( $r_v1, $r_v1_expected, "Check verbosity output (1)");
};
if ($@) {
    warn  "\n\nAn error occured : $@";
}

$CWD = $cwd_bak;
system( qq{ rm -Rf $git_repo } );

done_testing;