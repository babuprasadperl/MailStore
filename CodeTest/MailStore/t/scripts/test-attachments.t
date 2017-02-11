#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

BEGIN {
    push @INC, "$Bin/../../lib";
}

use_ok('MailStore::MailExtract');
use_ok('MailStore::Common::Config');

#my $extract = MailStore::MailExtract->new(
#    source  => "$Bin/../data/input/",
#    storage => "../data/output/"
#);

my $mgr = Mail::Box::Manager->new;
my $folder = $mgr->open( folder => "$Bin/../data/input/" ) or die "Can't read mail\n";
is $folder->messages, 1, "Found 1 messages";

{
    my $msg = $folder->message(0);
    isa_ok $msg => "Mail::Message";
    ok $msg->isMultipart, "Message has attachments";

}

$folder->close( write => 'NEVER' );
done_testing();
