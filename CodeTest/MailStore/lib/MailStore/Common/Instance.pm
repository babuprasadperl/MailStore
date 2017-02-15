#!/usr/bin/perl
package MailStore::Common::Instance;

#-------------------------------------------------------
#  Module: MailStore::Common::Instance.pm
#  Description: Implements Singleton
#
#  Author: Babu Prasad H P (babuprasad.perl@gmail.com)
#--------------------------------------------------------

# Implements Singleton
# This module is derived by Config.pm and Logger.pm
#
use Moose::Role;

#
# Get the instance of the object
#
sub instance {
    my ( $class, @args ) = @_;

    my $existing = $class->existing_singleton;
    return $existing if $existing;

    no strict 'refs';

    return ${"$class\::singleton"} = $class->new(@args);
}

#
# Check if the object already exists in the memory
#
sub existing_singleton {
    my ( $class, @args ) = @_;

    no strict 'refs';

    # create exactly one instance
    if ( defined ${"$class\::singleton"} ) {
        my $obj = ${"$class\::singleton"};

        # re-read the config if needed
        $obj->init(@args);
        return $obj;
    }
    return;
}

1;
