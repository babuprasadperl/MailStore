#!/usr/bin/perl
package MailStore::MailExtract;

#-------------------------------------------------------
#  Module: MailStore::MailExtract
#  Description: Extracts all the messages from maildir
#
#  Author: Babu Prasad H P (babuprasad.perl@gmail.com)
#--------------------------------------------------------

use Moose;
use Data::Dumper;
use Mail::Box::Manager;
use Mail::Message::Body;
use YAML::Dumper;
use FindBin qw($Bin);
use File::Slurp;

# MailStore modules
use MailStore;
use MailStore::Storage;
use MailStore::Common::Logger qw(logger);

our $VERSION = '1.0';

# config pointer
has 'source'  => ( is => 'rw', isa => 'Str', required => 1 );
has 'storage' => ( is => 'rw', isa => 'Str', required => 1 );
has 'manifest' => ( is => 'rw', isa => 'HashRef' );

#
# Runs during object creation
#
sub BUILD {
    my $self = shift;
    $self->init();
    logger()->debug('Initalization complete: Object is ready');
    return $self;
}

#
# Extraction runs during init phase itself
#
sub init {
    my $self = shift;
    try {
        #
        # Step - 1: Creates Mailbox object and read all the folders
        #
        my $mgr = Mail::Box::Manager->new();
        logger()->debug('Manager object is created');
        #
        # Step - 2: Check if source folder is reachable
        #
        unless ( $self->check_source_folder() ) {
            logger()->fatal( $self->{'source'} . ' folder cannot be reached' );
            return;
        }
        #
        # Step - 3: Create the storage path
        #
        $self->create_absolute_storage_path();
        #
        # Step - 4: Read the folders in maildir and get all messages
        #
        my $folder = $mgr->open( folder => $self->{'source'} );
        logger()->error( 'Cannot open source folder ' . $self->{'source'} . $! . "\n" ) if !$folder;
        my @messages = $folder->messages;
        logger()
          ->info(
            'Mail folder ' . $self->{'source'} . ' contains ' . scalar @messages . ' messages' );
        #
        # Step - 5: Loop through the message and copy them to the storage area
        #
        foreach my $msg (@messages) {
            $self->handle_message( $msg, $folder, $self->{'source'} );
        }
        logger()->info('All messages have been handled');
        #
        # Step - 6: Close the Mailbox connection
        #
        $mgr->closeAllFolders();
        #
        # Step - 7: Create a manifest file to store the mappings of all messages copied
        #
        $self->save_manifest() if $messages[0];
    }
    catch {
        logger()->error( "Error occured in init of maildir : " . $! );
        return;
    };
    return;
}

#
# Check if the source folder is reachable, if not then make it reachable
#
sub check_source_folder {
    my $self = shift;
    return 1 if ( -d $self->{'source'} );
    my $dir = $Bin;
    my $lib = join( '/../../', $dir, $self->{'source'} );
    $self->{'source'} = $lib;
    return 1 if ( -d $lib );
    return;
}

#
# Create the absoulute path for the storage folder
#
sub create_absolute_storage_path {
    my $self = shift;
    return 1 if ( -d $self->{'storage'} );
    $self->{'storage'} = $Bin . '/' . $self->{'storage'};
    return 1;
}

#
# [Message logic part] Handle individual messages carefully
#
sub handle_message {
    my ( $self, $msg, $folder, $source_path ) = @_;
    #
    # Step 1: Get the message object
    #
    try {
        #
        # Step 2: Get the message body
        #
        my Mail::Message::Body $body = $msg->decoded;
        logger()->info('message body decoded');
        #
        # Step 3: Extract Content-Type and MessageId
        #
        my $contentType = $msg->head->get('Content-Type')->body;
        my $messageId   = $msg->messageId;
        #
        # Step 4: Create the message folder in storage area (i.e. Target/destination)
        #
        my $storage = MailStore::Storage->new( storage => $self->{storage} );
        my $store_status = $storage->create_storage($messageId);
        unless ($store_status) {
            logger()->error("Could not create storage for id : $messageId");
            return;
        }
        #
        # Step 5: Serialize the message object in the message folder for Reporting
        #
        my $serialize_status = $storage->serialize_message($msg);
        unless ($serialize_status) {
            logger()->error("Could not serialize object : $messageId");
            return;
        }
        logger()->debug('Object Serialize completed');
        #
        # Step 6: If Multi-part then handle differently
        #         You may have to split the message and
        #         then save in the tagret message folder
        #
        if ( $msg->isMultipart ) {
            #
            # [As per Requirement Spec]
            # If more than one part then saving only part-1 as .text or .html
            #
            print "Number of attachments found: ", scalar $body->parts('ACTIVE') . "\n";
            my $save_count       = 0;
            my $attachment_count = 0;

            foreach my $part ( $body->parts ) {
                $contentType = $part->get('Content-Type');
                #
                # Sometimes attachment might be of Content-Type = text/html or text/plain
                # we can check if it is attachment or not based on 'content-disposition'
                #
                if ( $part->head->get('content-disposition') =~ /attachment/ ) {
                    $attachment_count++;
                    $storage->save_attachment( $part, $attachment_count );
                    next;
                }
                #
                # We are saving text/html and text/plain content types only once
                # as either body.txt or body.html
                #
                if ( $contentType =~ /html|plain/i && $save_count == 0 ) {
                    $storage->write_to_file( $part->get('Content-Type'), $part->body );
                    $save_count++;
                }
                #
                # Other attachments that are not text/html or text/plain
                # we are saving them irrespective of count
                #
                elsif ( $contentType !~ /html|plain/i ) {
                    $attachment_count++;
                    $storage->save_attachment( $part, $attachment_count );
                }
            }
        }
        #
        # Step 7: Handle for non-multipart message
        #
        else {
            #
            # Non-multipart save
            #
            $storage->write_to_file( $contentType, $body );
        }
        #
        # Step 8: Update the manifest file (mappings.yaml) file with
        #         1) MessageId
        #         2) Stored path
        #
        $self->update_manifest($storage);
        logger()->debug('Finished updating Manifest : mappings.yaml');
        return 1;
    }
    catch {
        logger()->error("Error in handling message : $!");
    };
    return 1;
}

#
# Update the manifest file (update the mappings array)
#
sub update_manifest {
    my ( $self, $storage ) = @_;
    my $manifest;
    $manifest->{'messageId'} = $storage->{'messageId'};
    $manifest->{'stored_as'} = $storage->{'folderName'};
    push( @{ $self->{'manifest'} }, $manifest );
    return 1;
}

#
# Finally save the manifest to file for reporting
#
sub save_manifest {
    my $self   = shift;
    my $dumper = YAML::Dumper->new;
    $dumper->indent_width(4);
    my $yamlText = $dumper->dump( $self->{'manifest'} );
    write_file( $self->{'storage'} . '/Mappings.yaml', $yamlText );
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
