#!/usr/bin/perl
package MailStore::Storage;

#------------------------------------------------------------
#  Module: MailStore::Storage
#  Description: Handles the responsibilty of storing the
#               Messages in the target directory
#
#  Author: Babu Prasad H P (babuprasad.perl@gmail.com)
#------------------------------------------------------------

use Moose;
#use Data::Dumper;
use Storable;
use File::Slurp;
use FindBin qw($Bin);
use File::Path qw(make_path);
use Try::Tiny;
use Mail::Address;
use Carp;

# MailStore modules
use MailStore;
use MailStore::Common::Config;
use MailStore::Common::Logger qw(logger);

our $VERSION = '1.0';

# Moose Attributes
has 'storage' => ( is => 'rw', isa => 'Str', required => 1 );
has 'messageId'       => ( is => 'rw', isa => 'Str' );
has 'folderName'      => ( is => 'rw', isa => 'Str' );
has 'storeFormat'     => ( is => 'rw', isa => 'Str', default => ':utf8' );
has 'storePermission' => ( is => 'rw', isa => 'Str', default => '0666' );
has 'save_html'       => ( is => 'rw', isa => 'Str', default => 'body.html' );
has 'save_text'       => ( is => 'rw', isa => 'Str', default => 'body.txt' );

#
# During Storage object initialization
#
sub BUILD {
    my $self   = shift;
    my $config = MailStore::Common::Config->instance();
    $self->{'storeFormat'}     = $config->getValue('store_format')     || ':utf8';
    $self->{'storePermission'} = $config->getValue('store_permission') || '0666';
    $self->{'save_html'}       = $config->getValue('save_html')        || 'body.html';
    $self->{'save_text'}       = $config->getValue('save_text')        || 'body.txt';

    return $self;
}

#
# Create folder structure for the message
#
sub create_storage {
    my ( $self, $messageId ) = @_;

    logger()->info('creating folder for message');
    $self->{'folderName'} = $self->get_folder_name($messageId);

    logger()->info( 'folder name :' . $self->{'folderName'} );
    my $store_status = $self->create_folder();
    logger()->info( 'created folder :' . $self->{'folderName'} );
    return $store_status;
}

#
# Return the new folder name at the storage area
# Every folder is named after the messageId of the message
# messageId is a unique id, so no question of clashes
#
sub get_folder_name {
    my ( $self, $messageId ) = @_;
    $self->{messageId} = $messageId;
    return $self->{storage} . '/' . $messageId;
}

#
# Creates folder
#
sub create_folder {
    my ($self) = @_;

    try {
        logger()->debug( 'Creating folder:' . $self->{'messageId'} );
        make_path(
            $self->{'folderName'},
            {
                verbose => 1,
                mode    => '0700',
            }
        );
    }
    catch {
        logger()->error( 'Folder could not be created :' . $! );
    };
    logger()->error( 'Folder could not be created :' . $! ) if ( !-d $self->{'folderName'} );

    #
    # Read, Write, Execute for current user
    # This is backup plan incase the make_path() doesnt give the permissions properly
    #
    chmod 0700, $self->{'folderName'};

    return 1;
}

#
# Now serialize the message object to the disk
#
sub serialize_message {
    my ( $self, $msg ) = @_;
    my $status;
    try {
        logger()->debug('filtering the object for serialization');
        my $filtered_obj = $self->filter_message($msg);
        logger()->debug('Serializing now');
        $status = $self->serialize($filtered_obj);
        logger()->debug('Serializing completed');
    }
    catch {
        logger()->error( 'Problem in Serializing ' . $! );
    };
    return $status;
}

#
# Filtering only needed ones
#
sub filter_message {
    my ( $self, $msg ) = @_;
    my $obj;

    try {
        $obj->{from} = [ map { $_->format } $msg->from ];
        $obj->{to}   = [ map { $_->format } $msg->to ];
        $obj->{subject} = $msg->subject || 'unknown';
        $obj->{cc}  = [ map { $_->format } $msg->cc ]  || ['None'];
        $obj->{bcc} = [ map { $_->format } $msg->bcc ] || ['None'];
        $obj->{date} = $msg->head->get('Date') || 'Unknown';
        $obj->{sender} = [ map { $_->format } $msg->sender ];
        $obj->{contentType} = $msg->contentType || 'text/plain';
        $obj->{isNested} = $msg->isNested ? 'True' : 'False';
        $obj->{nrLines} = $msg->nrLines || 0;
        $obj->{'Main_Message'}  = $msg->{'main-message'};
        $obj->{'Main_filename'} = $msg->{'main-file'};
        $obj->{'attachments'} = $msg->{'attachments'} if $msg->{'attachments'};
    }
    catch {
        logger()->error( 'Problem in message object filtering ' . $! );
    };

    return $obj;
}

#
# Serialize and store the object hash to a file on the disk
# with the same name as the foldername
#
sub serialize {
    my ( $self, $objHash ) = @_;
    try {
        my $file = $self->{'folderName'} . '/' . $self->{'messageId'} . '.srz';
        store $objHash, $file or croak( 'Could not serialize :' . $! );
    }
    catch {
        logger()->error( 'Problem in serializing to file - Storable error :' . $! );
    };
    return 1;
}

#
# Write the message to file as either body.html or body.txt
#
sub write_to_file {
    my ( $self, $contentType, $body ) = @_;
    my $file;

    if ( $contentType =~ /html/i ) {
        $file = $self->{'folderName'} . '/' . $self->{'save_html'};
        write_file( $file,
            { binmode => $self->{'storeFormat'}, perms => $self->{'storePermission'} }, $body );
        logger()->debug( 'Writing message body to file :' . $self->{'save_html'} );
    }
    else {
        $file = $self->{'folderName'} . '/' . $self->{'save_text'};
        write_file( $file,
            { binmode => $self->{'storeFormat'}, perms => $self->{'storePermission'} }, $body );
        logger()->debug( 'Writing message body to file :' . $self->{'save_text'} );
    }
    return $file;
}

#
# Write only attachments
#
sub save_attachment {
    my ( $self, $part, $count ) = @_;
    my $messageId    = $self->{'messageId'} || $part->messageId;
    my $partNumber   = $part->partNumber;
    my $attachmentId = $messageId . '-' . $partNumber . '-' . $count;
    logger()->debug( 'Attachment Id is :' . $attachmentId );
    my $file = $self->{'folderName'} . '/' . $attachmentId;
    logger()->debug('Writing attachment to file ');
    write_file( $file, $part->body );
    return $attachmentId;
}

1;
