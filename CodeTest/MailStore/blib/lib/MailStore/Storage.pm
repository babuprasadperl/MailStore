package MailStore::Storage;

#!/usr/bin/perl
#------------------------------------------------------------
#  Module: MailStore::Storage
#  Description: Handles the responsibilty of storing the 
#               Messages in the target directory
#
#  Author: Babu Prasad H P (babuprasad.perl@gmail.com)
#------------------------------------------------------------

use Moose;
use Data::Dumper;
use Storable;
use File::Slurp;
use FindBin qw($Bin);
use File::Path qw(make_path);
use Try::Tiny;
use Mail::Address;

# MailStore modules
use MailStore;
use MailStore::Common::Config;
use MailStore::Common::Logger qw(logger);

our $VERSION = $MailStore::VERSION;

# Moose Attributes
has 'storage'     => (is => 'rw', isa => 'Str', required => 1);
has 'messageId'   => (is => 'rw', isa => 'Str');
has 'folderName'  => (is => 'rw', isa => 'Str');
has 'storeFormat'      => (is => 'rw', isa => 'Str', default => ':utf8');
has 'storePermission'  => (is => 'rw', isa => 'Num', default => 0666);
has 'save_html'        => (is => 'rw', isa => 'Str', default => 'body.html');
has 'save_text'        => (is => 'rw', isa => 'Str', default => 'body.txt');

#
# During Storage object initialization
#
sub BUILD {
    my $self = shift;
    print "hello \n";
       print Data::Dumper::Dumper $self;
    my $config = MailStore::Common::Config->instance();
    $self->{'storeFormat'}     = $config->getValue('store_format') || ':utf8';
    $self->{'storePermission'} = $config->getValue('store_permission') || 0666;
    $self->{'save_html'}       = $config->getValue('save_html') || 'body.html';
    $self->{'save_text'}       = $config->getValue('save_text') || 'body.txt';
    
   print "FORMAT = ".$self->{'storeFormat'}."\n";
   print "PERMISSIONS = ".$self->{'storePermission'}."\n";
   print Data::Dumper::Dumper $self;
   
    return $self;
}

#
# Create folder structure for the message
#
sub create_storage {
    my ($self, $messageId) = @_;
    
    logger()->info('creating folder for message');
    $self->{'folderName'}  = $self->get_folder_name($messageId);

    logger()->info('folder name :'.$self->{'folderName'});
    my $store_status = $self->create_folder();
    logger()->info('created folder :'.$self->{'folderName'});
    return $store_status;
}

#
# Return the new folder name at the storage area
# Every folder is named after the messageId of the message
# messageId is a unique id, so no question of clashes
#
sub get_folder_name {
    my ($self, $messageId) = @_;
    $self->{messageId} = $messageId;
    return $self->{storage}.'/'.$messageId;
}

#
# Creates folder
#
sub create_folder {
    my ($self) = @_;
    print "FOLDER = ".$self->{'folderName'};
    print Data::Dumper::Dumper $self;
    try {
    print "FOLER = ".$self->{'folderName'}."\n";
    make_path($self->{'folderName'}, {
            verbose => 1,
            mode => 0000,
    });
    }
    catch {
    print "ERRRO = $!\n";
    logger()->error('Folder could not be created :'.$!);
    };
    print"HELLO HERE\n";
    logger()->error('Folder could not be created :'.$!) if (! -d $self->{'folderName'});
    # 
    # Read, Write, Execute for current user
    chmod 700, $self->{'folderName'};

    return 1;
}

#
# Now serialize the message object to the disk
#
sub serialize_message {
    my ($self, $msg) = @_;
    my $status;
    try {
    print "filtering\n";
    my $filtered_obj = $self->filter_message($msg);
    print "Serilazlie\n";
    $status = $self->serialize($filtered_obj);
    print "Serilalize done = $status\n";
    
    }
    catch{
     print "ERROR = $!\n";
    };
    return $status;
}

#
# Filtering only needed ones
#
sub filter_message {
    my ($self, $msg) = @_;
    my $obj;
print "filter started\n";
try {
#print Data::Dumper::Dumper $msg;
    $obj->{from} = [map {$_->format} $msg->from];
    $obj->{to} = [map {$_->format} $msg->to];
    $obj->{subject} = $msg->subject   || 'unknown';
    $obj->{cc} = [map {$_->format} $msg->cc]   || ['None'];
    $obj->{bcc} = [map {$_->format} $msg->bcc] || ['None'];
    $obj->{date} =  $msg->head->get('Date')    || 'Unknown';
    $obj->{sender} =  [map {$_->format} $msg->sender];
    $obj->{contentType} = $msg->contentType   || 'text/plain';
    $obj->{content} =$msg->lines   || 'unknown';
    $obj->{isNested} = $msg->isNested ? 'True' : 'False';
    $obj->{nrLines} = $msg->nrLines  || 0;
    }
    catch {
        print "ERROR = $!\n";
    };

    return $obj;
}

#
# Serialize and store the object hash to a file on the disk
# with the same name as the foldername
#
sub serialize {
    my ($self, $objHash) = @_;
    my $file = $self->{'folderName'}.'/'.$self->{'messageId'}.'.srz';
    store $objHash, $file or die('Could not serialize :'.$!);
    return 1;
}

# 
# Write the message to file as either body.html or body.txt
#
sub write_to_file{
   my ($self, $contentType, $body) = @_;
   print "Starting to write\n";
   print "FORMAT = ".$self->{'storeFormat'}."\n";
   print "PERMISSIONS = ".$self->{'storePermission'}."\n";
   
   if ($contentType =~ /html/i) {
        my $file = $self->{'folderName'}.'/'.$self->{'save_html'};
        write_file( $file, {binmode => $self->{'storeFormat'}, perms => $self->{'storePermission'}}, $body ) ;
   }
   else {
        my $file = $self->{'folderName'}.'/'.$self->{'save_text'};
        write_file( $file, {binmode => $self->{'storeFormat'}, perms => $self->{'storePermission'}}, $body ) ;
   }
   print "Completed write\n";
   return 1;
}

#
# Write only attachments
#
sub save_attachment {
    my ($self, $part, $count) = @_;
    my $messageId = $self->{'messageId'} || $part->messageId;
    my $partNumber = $part->partNumber;
    print "PARTNMUMBER is =". $partNumber."\n";
    my $attachmentId = $messageId.'-'.$partNumber.'-'.$count;
     print "Attachment is =". $attachmentId."\n";
    my $file = $self->{'folderName'}.'/'.$attachmentId;
    write_file( $file, $part->body ) ;
}

1;