package MailStore::Report;

#!/usr/bin/perl
#------------------------------------------------------------
#  Module: MailStore::Report
#  Description: Display the information of the message stored
#
#  Author: Babu Prasad H P (babuprasad.perl@gmail.com)
#------------------------------------------------------------

use Moose;

use Data::Dumper;
use Try::Tiny;
use FindBin qw($Bin);
use Storable;
use File::Spec;

# MailStore modules
use MailStore;

our $VERSION = $MailStore::VERSION;

# Attributes
has 'storage'     => (isa => 'Str', is => 'rw');
has 'messageDir'  => (isa => 'Str', is => 'rw');
has 'messageId'   => (isa => 'Str', is => 'rw');

#
# Get the message directory, Create it if you dont have
#
sub get_message_dir {
    my ($self, $messageId) = @_;
    my $dir;
    $self->{'messageId'} = $messageId;
    if($self->check_reachable($self->{'storage'})) {
        $dir = $self->{'storage'}.'/'.$messageId;
    }
    else {
        $dir = $Bin.'/'.$self->{'storage'}.'/'.$messageId;
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
    my ($self, $messageDir) = @_;
    unless($self->check_reachable($messageDir)) {
        die("The directory or messageId provided is not correct, please check!! : $messageDir");
    }
    $self->{'messageDir'} = $messageDir;
    my $objHash = $self->read_serialized_data();
    no strict "refs";

    #
    # Need a better way to display the report
    # Note: I started using Text::Table but somehow the array objects were not displaying properly
    #       Even I tried with Perl6::Form, but it is extensive and needs time to explore
    #       For time being this is the simple report display I have :-)
    #
    foreach my $key (keys %{$objHash} ) {
        if (ref($objHash->{$key}) eq 'ARRAY') {
            print "$key --> @{$objHash->{$key}}\n" if $objHash->{$key}->[0];
        }
        else {
            print "$key --> $objHash->{$key}\n" if $objHash->{$key};
        }
    }
}

#
# Read the stored Serialized data
#
sub read_serialized_data {
    my $self = shift;
    $self->get_message_id() unless $self->{'messageId'};
    return retrieve($self->{'messageDir'}.'/'.$self->{'messageId'}.'.srz');
}

#
# Check if the requested directory is reachable or not
#
sub check_reachable {
    my ($self, $folder) = @_;
    return 1 if(-d $folder);
    return 0;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
