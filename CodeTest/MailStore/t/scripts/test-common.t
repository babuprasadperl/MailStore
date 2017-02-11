#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

BEGIN {
    push @INC, "$Bin/../../lib";
}

use_ok('MailStore::Common::Config');
use_ok('MailStore::Common::Logger');
use_ok('MailStore::Common::Instance');

my $config = MailStore::Common::Config->instance();
isa_ok( $config, 'MailStore::Common::Config' );

ok( $config->getValue('maildir') eq '../../MailDir',      'Message source path' );
ok( $config->getValue('storage_path') eq '../../Storage', 'Message target path' );
ok( $config->getValue('store_format') eq ':utf8',         'Save format' );
ok( $config->getValue('store_permission') eq '0600',      'Save message files with permissions' );
ok( $config->getValue('save_html') eq 'body.html', 'Save message with content-type : text/html' );
ok( $config->getValue('save_text') eq 'body.txt',  'Save message with content-type : text/plain' );

my $log = MailStore::Common::Logger->instance();
isa_ok( $log, 'MailStore::Common::Logger' );
ok( defined $log->{log_conf} == 1,                            'log file' );
ok( MailStore::Common::Logger::logger()->info('hello'), 'logging data' );

# Testing completed
done_testing();
