#!/usr/bin/perl
package MailStore::Service;

#---------------------------------------------------------------
#  Module: MailStore::Service
#  Description: Main Controller of MailStore application
#               1) It instantiates Logger and Config objects
#               2) Redirects the mailextraction and storage
#                  to MailStore::Extract module
#               3) Redirects the reporting to MailStore::Report
#                  module
#
#  Author: Babu Prasad H P (babuprasad.perl@gmail.com)
#----------------------------------------------------------------

use Moose;

#use Data::Dumper;
use Try::Tiny;

# MailStore modules
use MailStore;
use MailStore::Common::Config;
use MailStore::Common::Logger qw(logger);
use MailStore::MailExtract;
use MailStore::Report;

our $VERSION = '1.0';

# config pointer
has 'config' => ( is => 'rw', isa => 'MailStore::Common::Config' );

# Attributes
has 'log'        => ( is => 'rw' );
has 'maildir'    => ( is => 'rw', default => 'maildir' );
has 'messageId'  => ( is => 'rw' );
has 'messageDir' => ( is => 'rw' );

#
# Initializes the Service object
#
sub BUILD {
    my $self = shift;
    $self->{'config'} = MailStore::Common::Config->instance();
    die("Failed to read mailstore config\n") if ( !$self->config );

    # initialize log
    $self->log;
    return $self;
}

#
# Initialize the logger if not already
#
before 'log' => sub {
    my ( $self, $log ) = @_;
    return if ($log);

    if ( !$self->{log} ) {
        $self->{log} = MailStore::Common::Logger->logger();
    }
};

#
# Run the Message extraction
#----------------------------
# It hands over the responsibility of message extraction to MailExtract module
#
sub run {
    my $self = shift;

    try {
        # Command line option gets the precedence
        #
        logger()->info('Starting Service');
        my $source_path  = $self->{'maildir'} || $self->{config}->getValue('maildir');
        my $storage_path = $self->{config}->getValue('storage_path');
        my $extract      = MailStore::MailExtract->new(
            source  => $source_path,
            storage => $storage_path
        );
        logger()->info('Service ended successfully');
        logger()->info( '---------------------------------------------------------' . "\n\n" );
    }
    catch {
        logger()->error( 'Error occured in run : ' . $! .. "\n\n" );
    };
    return;
}

# This is like saying
# "I give you directory and you give me message details"
#
sub get_dir_data {
    my $self   = shift;
    my $report = MailStore::Report->new();
    $report->print_report( $self->{'messageDir'} );
    return 1;
}

# On the similar tone
# "I give you messageId and you give me message details"
#
sub get_message_data {
    my $self         = shift;
    my $storage_path = $self->{config}->getValue('storage_path');
    my $report       = MailStore::Report->new( storage => $storage_path );
    my $messageDir   = $report->get_message_dir( $self->{'messageId'} );
    $report->print_report($messageDir);
    return 1;
}

#
# Gets the list of message's messageIds taken from stored manifest.yaml file
#
sub get_message_list {
    my $self         = shift;
    my $storage_path = $self->{config}->getValue('storage_path');
    my $report       = MailStore::Report->new( storage => $storage_path );
    $report->print_message_list();
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
