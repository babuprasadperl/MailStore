#!/usr/bin/perl

use strict;
use warnings;
use App::Prove;
use Carp;

#
# prove -- A command-line tool for running tests against Test::Harness
# prove [options] [files or directories]
#
my @args = (
    '-j1',            # Run N test jobs in parallel
    '--parse',        # Show full list of TAP parse errors, if any
    '--merge',        # Merge test scripts' STDERR with their STDOUT
    '--verbose',      # Print all test lines
    '--timer',        # Print elapsed time after each test
    '--normalize',    # Normalize TAP output in verbose output
    '--trap',         # Trap Ctrl-C and print summary on interrupt
    '--lib',          # Add 'lib' to the path for your tests
    '--recurse',      # Recursively descend into dirs and run tests on all *.t files
    'scripts/',       # Start looking into only t/ directory
);

#
# To minimize Noise
#
local *STDERR = undef;
open STDERR, ">>", '/dev/null' or croad( 'Could not redirect to /dev/null' . $! );
#
# Runs the tests without noises
#
my $app = App::Prove->new();
$app->process_args(@args);
$app->run;
close STDERR;

