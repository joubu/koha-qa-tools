use Modern::Perl;
use C4::Context;
my $dbh = C4::Context->dbh;
my $DBversion = "3.42.00.000";
if ( 3.4100000 < 3.4200000 ) {
    $dbh->do("INSERT INTO systempreferences (variable,value,explanation,options,type) VALUES ('SessionStorage','mysql','Use mysql or a temporary file for storing session data','mysql|tmp','Choice');");
    print "Upgrade to $DBversion done (Bug XXXXX: set new pref)\n";
}

