use Modern::Perl;
use Test::More tests => 37;

use File::chdir;
use Git::Repository;
use QohA::Git;
use QohA::Files;


my $num_of_commits = 4;
my $v = 1;
my $git_repo = 't/git_repo_tmp';
my $cwd_bak = $CWD;
my $git_top_level = `git rev-parse --show-toplevel`;
chomp $git_top_level;
die "You have to be at the root of the koha-qa-tools project"
    if $cwd_bak ne $git_top_level;
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

    my @files = (
        $modified_files->filter( { extension => [ qw< perl tt xml yaml > ] } ),
        $modified_files->filter( { name => [ qw< sysprefs.sql > ] } ),
        $modified_files->filter( { name => [ qw< kohastructure.sql > ] } ),
    );
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
    is( $fail_compil_before, 0, "fail_compil passed compil before" );
    is( scalar @$fail_compil_after, 1, "fail_compil has 1 error for compil now");
    is( @$fail_compil_after[0] =~ m{Can't locate Foo/Bar.pm}, 1, qq{the compil error for fail_compil is "can't locate Foo/Bar.pm} );

    my ($perl_fail_critic) = grep {$_->path eq qq{perl/i_fail_critic.pl}} @files;
    is( ref $perl_fail_critic, qq{QohA::File::Perl}, "i_fail_critic.pl found" );
    my ($fail_critic_before, $fail_critic_after) = @{ $perl_fail_critic->report->tasks->{valid} };
    is( $fail_critic_before, 0, "fail_critic passed valid before");
    is( $fail_critic_after, 0, "fail_critic passes valid now");
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
 $STATUS_KO	perl/i_fail_license.pl
 $STATUS_KO	perl/i_fail_spelling.pl
 $STATUS_KO	perl/i_fail_template_name.pl
 $STATUS_KO	perl/i_fail_unused_declared_variables.pl
 $STATUS_KO	perl/updatedatabase.pl
 $STATUS_KO	perl/i_fail_patterns.pl
 $STATUS_KO	perl/i_fail_compil.pl
 $STATUS_KO	perl/i_fail_critic.pl
 $STATUS_OK	perl/i_m_ok.pl
 $STATUS_KO	tmpl/i_fail_patterns_theme.tt
 $STATUS_KO	tmpl/i_fail_patterns_tt_plugins.tt
 $STATUS_KO	tmpl/i_fail_patterns.tt
 $STATUS_KO	tmpl/i_fail_tt_valid.tt
 $STATUS_KO	tmpl/i_fail_valid_template.tt
 $STATUS_OK	tmpl/i_will_be_correct_tt_valid.tt
 $STATUS_KO	i_fail_yaml.yaml
 $STATUS_KO	sql/sysprefs.sql
 $STATUS_KO	sql/kohastructure.sql
EOL
    my $r_v1_expected = <<EOL;
 $STATUS_KO	perl/i_fail_license.pl
   $STATUS_OK	  critic
   $STATUS_KO	  forbidden patterns
   $STATUS_OK	  pod
   $STATUS_OK	  spelling
   $STATUS_OK	  valid

 $STATUS_KO	perl/i_fail_spelling.pl
   $STATUS_OK	  critic
   $STATUS_OK	  forbidden patterns
   $STATUS_OK	  pod
   $STATUS_KO	  spelling
   $STATUS_OK	  valid

 $STATUS_KO	perl/i_fail_template_name.pl
   $STATUS_OK	  critic
   $STATUS_KO	  forbidden patterns
   $STATUS_OK	  pod
   $STATUS_OK	  spelling
   $STATUS_OK	  valid

 $STATUS_KO	perl/i_fail_unused_declared_variables.pl
   $STATUS_KO	  critic
   $STATUS_OK	  forbidden patterns
   $STATUS_OK	  pod
   $STATUS_OK	  spelling
   $STATUS_OK	  valid

 $STATUS_KO	perl/updatedatabase.pl
   $STATUS_OK	  critic
   $STATUS_KO	  forbidden patterns
   $STATUS_OK	  pod
   $STATUS_OK	  spelling
   $STATUS_OK	  valid

 $STATUS_KO	perl/i_fail_patterns.pl
   $STATUS_OK	  critic
   $STATUS_KO	  forbidden patterns
   $STATUS_OK	  pod
   $STATUS_OK	  spelling
   $STATUS_KO	  valid

 $STATUS_KO	perl/i_fail_compil.pl
   $STATUS_OK	  critic
   $STATUS_OK	  forbidden patterns
   $STATUS_OK	  pod
   $STATUS_OK	  spelling
   $STATUS_KO	  valid

 $STATUS_KO	perl/i_fail_critic.pl
   $STATUS_KO	  critic
   $STATUS_OK	  forbidden patterns
   $STATUS_OK	  pod
   $STATUS_OK	  spelling
   $STATUS_OK	  valid

 $STATUS_OK	perl/i_m_ok.pl
   $STATUS_OK	  critic
   $STATUS_OK	  forbidden patterns
   $STATUS_OK	  pod
   $STATUS_OK	  spelling
   $STATUS_OK	  valid

 $STATUS_KO	tmpl/i_fail_patterns_theme.tt
   $STATUS_KO	  forbidden patterns
   $STATUS_OK	  spelling
   $STATUS_OK	  tt_valid
   $STATUS_OK	  valid_template

 $STATUS_KO	tmpl/i_fail_patterns_tt_plugins.tt
   $STATUS_KO	  forbidden patterns
   $STATUS_OK	  spelling
   $STATUS_OK	  tt_valid
   $STATUS_KO	  valid_template

 $STATUS_KO	tmpl/i_fail_patterns.tt
   $STATUS_KO	  forbidden patterns
   $STATUS_OK	  spelling
   $STATUS_OK	  tt_valid
   $STATUS_OK	  valid_template

 $STATUS_KO	tmpl/i_fail_tt_valid.tt
   $STATUS_OK	  forbidden patterns
   $STATUS_OK	  spelling
   $STATUS_KO	  tt_valid
   $STATUS_OK	  valid_template

 $STATUS_KO	tmpl/i_fail_valid_template.tt
   $STATUS_OK	  forbidden patterns
   $STATUS_OK	  spelling
   $STATUS_OK	  tt_valid
   $STATUS_KO	  valid_template

 $STATUS_OK	tmpl/i_will_be_correct_tt_valid.tt
   $STATUS_OK	  forbidden patterns
   $STATUS_OK	  spelling
   $STATUS_OK	  tt_valid
   $STATUS_OK	  valid_template

 $STATUS_KO	i_fail_yaml.yaml
   $STATUS_KO	  yaml_valid

 $STATUS_KO	sql/sysprefs.sql
   $STATUS_KO	  sysprefs_order

 $STATUS_KO	sql/kohastructure.sql
   $STATUS_KO	  charset_collate

EOL

    my ( $r_v0, $r_v1 );
    for my $f ( @files ) {
        $r_v0 .= $f->report->to_string({verbosity => 0})."\n";
        $r_v1 .= $f->report->to_string({verbosity => 1})."\n";
    }
    is( $r_v0, $r_v0_expected, "Check verbosity output (0)");
    is( $r_v1, $r_v1_expected, "Check verbosity output (1)");


    test_report( {one => 0,                 two => [],                      name => 1,  status => q{OK}} );
    test_report( {one => [],                two => [],                      name => 2,  status => q{OK}} );
    test_report( {one => 0,                 two => ['foo'],                 name => 3,  status => q{FAIL}} );
    test_report( {one => ['foo'],           two => 0,                       name => 4,  status => q{OK}} );
    test_report( {one => ['foo'],           two => 1,                       name => 5,  status => q{OK}} );
    test_report( {one => ['foo'],           two => q{},                     name => 6,  status => q{OK}} );
    test_report( {one => 1,                 two => ['foo'],                 name => 7,  status => q{FAIL}} );
    test_report( {one => [],                two => ['foo'],                 name => 8,  status => q{FAIL}} );
    test_report( {one => ['foo'],           two => ['foo'],                 name => 9,  status => q{OK}} );
    test_report( {one => ['foo', 'bar'],    two => ['foo'],                 name => 10, status => q{OK}} );
    test_report( {one => ['foo'],           two => ['bar'],                 name => 11, status => q{FAIL}} );
    test_report( {one => ['foo'],           two => ['foo', 'bar'],          name => 12, status => q{FAIL}} );
    test_report( {one => ['foo', 'foo'],    two => ['foo', 'foo', 'foo'],   name => 13, status => q{FAIL}} );
    test_report( {one => ['foo', 'foo'],    two => ['foo', 'bar', 'foo'],   name => 14, status => q{FAIL}} );

};
if ($@) {
    warn  "\n\nAn error occured : $@";
}

$CWD = $cwd_bak;
system( qq{ rm -Rf $git_repo } );

sub test_report {
    my ($param) = @_;
    my $test_file = QohA::File::Perl->new(path => 'qa-test');
    $test_file->add_to_report($param->{name}, $param->{one});
    $test_file->add_to_report($param->{name}, $param->{two});
    is( $test_file->report->to_string({verbosity => 0, name => $param->{name}}) =~ m|$param->{status}|, 1 , "test report $param->{name}");
}
