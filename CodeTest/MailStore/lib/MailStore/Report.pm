#!/usr/bin/perl
package MailStore::Report;

#------------------------------------------------------------
#  Module: MailStore::Report
#  Description: Display the information of the message stored
#
#  Author: Babu Prasad H P (babuprasad.perl@gmail.com)
#------------------------------------------------------------

use Moose;

#use Data::Dumper;
use Try::Tiny;
use FindBin qw($Bin);
use Storable;
use File::Spec;
use Carp;
use YAML qw(LoadFile);

# MailStore modules
use MailStore;
use MailStore::Common::Logger qw(logger);

our $VERSION = '1.0';

# Attributes
has 'storage'    => ( isa => 'Str', is => 'rw' );
has 'messageDir' => ( isa => 'Str', is => 'rw' );
has 'messageId'  => ( isa => 'Str', is => 'rw' );

#
# Get the message directory, Create it if you dont have
#
sub get_message_dir {
    my ( $self, $messageId ) = @_;
    my $dir;
    $self->{'messageId'} = $messageId;
    if ( $self->check_reachable( $self->{'storage'} ) ) {
        $dir = $self->{'storage'} . '/' . $messageId;
    }
    else {
        $dir = $Bin . '/' . $self->{'storage'} . '/' . $messageId;
    }
    return $dir;
}

#
# Get the messageId from the directory path
#
sub get_message_id {
    my $self = shift;
    my @base = File::Spec->splitpath( $self->{'messageDir'} );
    $self->{'messageId'} = pop @base;
    return;
}

#
# Printing the report on the screen
#
sub print_report {
    my ( $self, $messageDir ) = @_;
    logger()->debug('Printing Report');
    unless ( $self->check_reachable($messageDir) ) {
        croak("The directory or messageId provided is not correct, please check!! : $messageDir");
    }
    $self->{'messageDir'} = $messageDir;
    my $objHash = $self->read_serialized_data();

    #   no strict "refs";

    #
    # Need a better way to display the report
    # Note: I started using Text::Table but somehow the array objects were not displaying properly
    #       Even I tried with Perl6::Form, but it is extensive and needs time to explore
    #       For time being this is the simple report display I have :-)
    #
    print "\n\nPRINTING REPORT\n==============================\n";
    foreach my $key ( keys %{$objHash} ) {
        if ( ref( $objHash->{$key} ) eq 'ARRAY' ) {
            print "$key : @{$objHash->{$key}}\n" if $objHash->{$key}->[0];
        }
        elsif ( ref( $objHash->{$key} ) eq 'HASH' ) {
            print "\n$key\n----------------------------\n";
            foreach my $part ( keys %{ $objHash->{$key} } ) {
                print "$objHash->{$key}->{$part}\n";
            }
            print "\n";
        }
        else {
            print "$key : $objHash->{$key}\n" if $objHash->{$key};
        }
    }
    print "\n----------------------------------\n";
    return;
}

#
# Read the stored Serialized data
#
sub read_serialized_data {
    my $self = shift;
    $self->get_message_id() unless $self->{'messageId'};
    return retrieve( $self->{'messageDir'} . '/' . $self->{'messageId'} . '.srz' );
}

#
# Check if the requested directory is reachable or not
#
sub check_reachable {
    my ( $self, $folder ) = @_;
    return 1 if ( -d $folder );
    return 0;
}

#
# Prints the list of messages present in manifest file
#
sub print_message_list {
    my $self          = shift;
    my $manifest_path = $self->{'storage'} . '/manifest.yaml';
    my $tmp           = LoadFile($manifest_path);
    print "\n\tMessageIds\n\t-------------------------\n";
    map { print "\t" . $_->{'messageId'} . "\n" } @$tmp;
    print "\t-------------------------\n";
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
