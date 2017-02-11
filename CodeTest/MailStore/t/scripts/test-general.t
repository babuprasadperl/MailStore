#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
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

local *STDOUT = undef;
open STDOUT, ">>", '/dev/null' or croak( 'Could not redirect to /dev/null' . $! );
$report->print_report(
    $report->get_message_dir('20021210110736.GA32736@deep-dark-truthful-mirror.pad') );
close STDOUT;
pass("Reports are working fine");

done_testing();
