#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;

BEGIN {
    #
    # To include lib path
    #
    push @INC, "$Bin/../../lib";
    #
    # Including the modules
    #
    use_ok('MailStore');
    use_ok('MailStore::Common::Config');
    use_ok('MailStore::Common::Logger');
    use_ok('MailStore::Common::Instance');
    use_ok('MailStore::Service');
    use_ok('MailStore::MailExtract');
    use_ok('MailStore::Report');
    use_ok('MailStore::Storage');
}

# Now check the object creation of each module and ensure its doing fine.
my $config = MailStore::Common::Config->instance();
isa_ok( $config, 'MailStore::Common::Config' );

my $obj1 = MailStore::Common::Logger->instance();
isa_ok( $obj1, 'MailStore::Common::Logger' );

$obj1 = MailStore::Service->new();
isa_ok( $obj1, 'MailStore::Service' );

$obj1 = MailStore::Report->new( storage => '../data' );
isa_ok( $obj1, 'MailStore::Report' );

$obj1 = MailStore::Storage->new( storage => '../data' );
isa_ok( $obj1, 'MailStore::Storage' );

# Testing done
done_testing();
