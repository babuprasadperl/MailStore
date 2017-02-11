#!/usr/bin/perl
package MailStore::Common::Logger;

#-------------------------------------------------------
#  Module: MailStore::Common::Logger.pm
#  Description: Handles MailStore Logging using Log4Perl
#
#  Author: Babu Prasad H P (babuprasad.perl@gmail.com)
#--------------------------------------------------------

use Moose;
use FindBin qw($Bin);
use Log::Log4perl;
use Exporter;

#
# Exporting the logger function,
# so that it can be used by every other modules
#
use vars qw(@ISA @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT_OK = qw(logger);

# Importing Config module
use MailStore::Common::Config;

# Implements Instance module
# The methods of Instance module is imported to this namespace
#
with 'MailStore::Common::Instance';

# Moose attributes
has 'log_conf' => ( isa => 'Str', is => 'rw', default => 'logger.conf' );
has 'log' => ( is => 'rw' );

# initialize the object
sub BUILD {
    my ( $self, $params ) = @_;

    # this is so we get caller depth right
    Log::Log4perl->wrapper_register(__PACKAGE__);

    # get configuration parameters
    my $c = MailStore::Common::Config->instance;

    my @path = ( "$Bin/../etc", "$Bin/../../etc" );

    if ( !-e $self->log_conf ) {
        foreach my $dir (@path) {
            if ( -e $dir . '/' . $self->{'log_conf'} ) {
                $self->log_conf( $dir . '/' . $self->{'log_conf'} );
                last;
            }
        }
    }
    $self->init;
    return $self;
}

#
# Creates the logging instance
#
sub logger {
    my $self = shift;
    return MailStore::Common::Logger->instance(@_);
}

#
# Initializes the log_conf path
#
sub init {
    my $self = shift;

    if ( !Log::Log4perl->initialized() ) {
        Log::Log4perl->init( $self->{log_conf} );
        $self->{log} = Log::Log4perl->get_logger(__PACKAGE__);
        $self->{log}->info('Initializing logger');
        print 'For Detailed Log: Please check : MailStore/log/app.log' . "\n";
    }
    return $self;
}

#
# log method-modifier
#
before 'log' => sub {
    my ( $self, $log ) = @_;
    return if ($log);
    $self->init if ( !defined $self->{log} );
};

#
# Print INFO to log
#
sub info {
    my $self = shift;
    return if ( !@_ );
    $self->{log}->info(@_);
    return;
}
#
# Print ERROR to log
#
sub error {
    my $self = shift;
    return if ( !@_ );
    $self->{log}->error(@_);
    return;
}
#
# Print WARN to log
#
sub warn {
    my $self = shift;
    return if ( !@_ );
    $self->{log}->warn(@_);
    return;
}
#
# Print FATAL to log
#
sub fatal {
    my $self = shift;
    return if ( !@_ );
    $self->{log}->fatal(@_);
    return;
}
#
# Print DEBUG to log
#
sub debug {
    my ( $self, $msg ) = @_;
    return if ( !@_ );
    $self->{log}->debug($msg);
    return;
}

#
# The make_immutable call allows Moose to speed up a lot of things, most notably object construction.
# The trade-off is that you can no longer change the class definition.
#
no Moose;
__PACKAGE__->meta->make_immutable;

1;
