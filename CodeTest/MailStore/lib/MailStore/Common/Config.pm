#!/usr/bin/perl
package MailStore::Common::Config;

#-------------------------------------------------------
#  Module: Config.pm
#  Description: Module to load MailStore config file
#
#  Author: Babu Prasad H P (babuprasad.perl@gmail.com)
#--------------------------------------------------------

use Moose;
use FindBin qw($Bin);
use Config::Simple;
use Carp;

our $VERSION = '1.0';

# Implements Instance module
# The methods of Instance module is imported to this namespace
#
with 'MailStore::Common::Instance';

# Moose attributes
has 'config' => ( is => 'rw' );
has 'config_file' => ( isa => 'Str', is => 'rw', default => sub { "mailstore.conf" } );

# initialize the object
sub BUILD {
    my $self = shift;

    if ( !-e $self->config_file ) {
        $self->{config_file} = ( $self->find( $self->config_file ) );
    }
    if ( !-e $self->config_file ) {
        croak("A valid mystore configuration file is required!\n");
    }
    $self->init(@_);
    return $self;
}

#
# Attempt to locate config file from paths
#
sub find {
    my ( $self, $config ) = @_;

    my @path = ( "$Bin/../etc", "$Bin/../../etc" );
    my $file;
    foreach my $dir (@path) {
        if ( -e "$dir/$config" ) {
            $file = "$dir/$config";
            last;
        }
    }
    return $file;
}

#
# Now load the config file
#
sub init {
    my $self = shift;

    $self->{config} = Config::Simple->new;
    $self->{config}->read( $self->config_file )
      or die( "Failed to read loki config file, "
          . $self->config_file . ": "
          . $self->{config}->error
          . "\n" );
    return;
}

#
# Get any value from the config file
#
sub getValue {
    my ( $self, $param ) = @_;
    return $self->{config}->param($param);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

