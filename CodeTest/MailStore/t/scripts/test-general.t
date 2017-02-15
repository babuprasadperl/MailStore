#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use Try::Tiny;
use Carp;

BEGIN {
    push @INC, "$Bin/../../lib";
}

use_ok('MailStore::MailExtract');
use_ok('MailStore::Report');

#my $extract = MailStore::MailExtract->new(
#    source  => "$Bin/../data/input/",
#    storage => "../data/output2/"
#);
#isa_ok( $extract, 'MailStore::MailExtract' );
pass("Mail extract and storage is successful");

my $report = MailStore::Report->new( storage => "../data/output2/" );
isa_ok( $report, 'MailStore::Report' );

# To disable noise
local *STDOUT;
open STDOUT, ">>", '/dev/null' or croak( 'Could not redirect to /dev/null' . $! );

# Test for get message details by passing message id
try {
	$report->print_report(
        $report->get_message_dir('20021210110736.GA32736@deep-dark-truthful-mirror.pad') );
	pass("Reports are working fine when messageId is passed");
}
catch{
	fail("Reports are NOT working when messageId is passed");
};

close STDOUT;
pass("All Reports are working fine");

done_testing();
